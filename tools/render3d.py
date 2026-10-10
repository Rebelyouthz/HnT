"""Render a rigged, animated 3D character to pixel-perfect sprite frames.

The Dead Cells pipeline: a 3D model + skeleton animation is rendered small,
orthographic, without anti-aliasing, as flat albedo plus a normal map. The
game lights the sprite (CanvasTexture normal map + 2D lights), so volume,
rim light and shadow react to lamps, muzzle flashes and neon in real time.

Run inside Blender (no GPU needed, Cycles on CPU at 1 sample):

  blender -b -P tools/render3d.py -- MODEL.glb|fbx OUTDIR \
      --height 198 --dirs 8 [--action NAME] [--every 1] [--aa 0]

OUTDIR/<action>/<dir>/<frame>.png   albedo, RGBA
OUTDIR/<action>/<dir>/<frame>_n.png normal map (tangent space, Godot's +Y up)
OUTDIR/meta.json                    cell size, directions, fps per action

Directions: 0 = facing screen-right (east), then every 360/dirs degrees
counter-clockwise seen from above (east, north-east, north, ...).
"""
import argparse
import json
import math
import os
import sys

import bpy
from mathutils import Vector


def args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("model")
    ap.add_argument("out")
    ap.add_argument("--height", type=int, default=198, help="standing body height in px")
    ap.add_argument("--dirs", type=int, default=8)
    ap.add_argument("--action", default="", help="only this action (default: all)")
    ap.add_argument("--every", type=int, default=1, help="render every Nth frame")
    ap.add_argument("--aa", type=float, default=0.0, help="pixel filter width; 0 = hard pixels")
    ap.add_argument("--elev", type=float, default=0.0, help="camera elevation in degrees")
    return ap.parse_args(argv)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def load(path):
    ext = os.path.splitext(path)[1].lower()
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=path)
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=path, automatic_bone_orientation=True)
    else:
        raise SystemExit("unsupported model %s" % path)
    arm = next((o for o in bpy.data.objects if o.type == "ARMATURE"), None)
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("no mesh in %s" % path)
    return arm, meshes


def root(arm, meshes):
    """An empty that everything hangs from, so one rotation turns the actor."""
    pivot = bpy.data.objects.new("Pivot", None)
    bpy.context.scene.collection.objects.link(pivot)
    for o in bpy.data.objects:
        if o is pivot or o.parent is not None:
            continue
        o.parent = pivot
    return pivot


def world_bbox(meshes):
    dg = bpy.context.evaluated_depsgraph_get()
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for m in meshes:
        ev = m.evaluated_get(dg)
        for c in ev.bound_box:
            w = ev.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    return lo, hi


def flat_albedo_and_normal(meshes):
    """Cycles passes: DiffCol = albedo, Normal = world normal."""
    scn = bpy.context.scene
    vl = scn.view_layers[0]
    vl.use_pass_diffuse_color = True
    vl.use_pass_normal = True


def setup_render(px_w, px_h, aa):
    scn = bpy.context.scene
    scn.render.engine = "CYCLES"
    scn.cycles.device = "CPU"
    scn.cycles.samples = 1 if aa <= 0 else 8
    scn.cycles.use_denoising = False
    scn.cycles.pixel_filter_type = "BOX"
    scn.cycles.filter_width = max(aa, 0.01)
    scn.render.film_transparent = True
    scn.render.resolution_x = px_w
    scn.render.resolution_y = px_h
    scn.render.resolution_percentage = 100
    scn.render.image_settings.file_format = "PNG"
    scn.render.image_settings.color_mode = "RGBA"
    scn.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("W")
    world.color = (0, 0, 0)
    scn.world = world


def compositor(outdir_node_base):
    """Write albedo (with alpha) and the normal pass as separate PNGs."""
    scn = bpy.context.scene
    scn.use_nodes = True
    nt = scn.node_tree
    nt.nodes.clear()
    rl = nt.nodes.new("CompositorNodeRLayers")
    # Albedo keeps the render alpha.
    set_alpha = nt.nodes.new("CompositorNodeSetAlpha")
    nt.links.new(rl.outputs["DiffCol"], set_alpha.inputs["Image"])
    nt.links.new(rl.outputs["Alpha"], set_alpha.inputs["Alpha"])
    # Normal: world normal -> 0..1 colour.
    sep = nt.nodes.new("CompositorNodeSeparateColor")
    nt.links.new(rl.outputs["Normal"], sep.inputs["Image"])
    comb = nt.nodes.new("CompositorNodeCombineColor")
    # The camera looks along +Y: screen right = world X, screen up = world Z,
    # toward the viewer = -Y. Remap into Godot's (right, up, out) normal map.
    for out_ch, (src_ch, sign) in enumerate(((0, 0.5), (2, 0.5), (1, -0.5))):
        mul = nt.nodes.new("CompositorNodeMath")
        mul.operation = "MULTIPLY_ADD"
        mul.inputs[1].default_value = sign
        mul.inputs[2].default_value = 0.5
        nt.links.new(sep.outputs[src_ch], mul.inputs[0])
        nt.links.new(mul.outputs[0], comb.inputs[out_ch])
    nset = nt.nodes.new("CompositorNodeSetAlpha")
    nt.links.new(comb.outputs["Image"], nset.inputs["Image"])
    nt.links.new(rl.outputs["Alpha"], nset.inputs["Alpha"])
    out = nt.nodes.new("CompositorNodeOutputFile")
    out.base_path = outdir_node_base
    out.format.file_format = "PNG"
    out.format.color_mode = "RGBA"
    out.file_slots.clear()
    out.file_slots.new("albedo")
    out.file_slots.new("normal")
    nt.links.new(set_alpha.outputs["Image"], out.inputs["albedo"])
    nt.links.new(nset.outputs["Image"], out.inputs["normal"])
    return out


def camera(ortho_h, center, elev_deg):
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = ortho_h
    cam = bpy.data.objects.new("Cam", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    el = math.radians(elev_deg)
    # Camera looks along +Y (from -Y), i.e. the actor's side faces the lens
    # when the actor faces +X.
    dist = 50.0
    cam.location = center + Vector((0.0, -dist * math.cos(el), dist * math.sin(el)))
    cam.rotation_euler = (math.radians(90) - el, 0.0, 0.0)
    bpy.context.scene.camera = cam
    return cam


def actions_of(arm):
    if arm is None:
        return []
    return [a for a in bpy.data.actions if any(fc.data_path.startswith("pose.bones") for fc in a.fcurves)] or list(bpy.data.actions)


def main():
    a = args()
    reset()
    arm, meshes = load(os.path.abspath(a.model))
    pivot = root(arm, meshes)
    acts = actions_of(arm)
    if a.action:
        acts = [x for x in acts if x.name == a.action]
    if arm and acts:
        arm.animation_data_create()
    # Face +X at direction 0: probe the model's forward with the rest pose.
    lo, hi = world_bbox(meshes)
    stand_h = hi.z - lo.z
    ortho_h = stand_h * 1.45
    px_per_unit = a.height / stand_h
    px = int(math.ceil(ortho_h * px_per_unit / 2.0)) * 2
    center = Vector(((lo.x + hi.x) * 0.5, (lo.y + hi.y) * 0.5, lo.z + ortho_h * 0.5 - stand_h * 0.04))
    setup_render(px, px, a.aa)
    flat_albedo_and_normal(meshes)
    camera(ortho_h, center, a.elev)
    meta = {"cell": [px, px], "dirs": a.dirs, "height": a.height, "actions": {}}
    scn = bpy.context.scene
    for act in acts or [None]:
        name = act.name if act else "pose"
        if act:
            arm.animation_data.action = act
            f0, f1 = (int(act.frame_range[0]), int(act.frame_range[1]))
        else:
            f0 = f1 = scn.frame_current
        frames = list(range(f0, f1 + 1, max(1, a.every)))
        meta["actions"][name] = {"frames": len(frames), "fps": scn.render.fps / max(1, a.every)}
        for d in range(a.dirs):
            pivot.rotation_euler = (0.0, 0.0, math.radians(360.0 * d / a.dirs))
            base = os.path.join(os.path.abspath(a.out), name, "%d" % d)
            os.makedirs(base, exist_ok=True)
            node = compositor(base)
            for i, f in enumerate(frames):
                scn.frame_set(f)
                node.file_slots[0].path = "%03d_a" % i
                node.file_slots[1].path = "%03d_n" % i
                scn.render.filepath = os.path.join(base, "_discard")
                bpy.ops.render.render(write_still=False)
            print("rendered %s dir %d: %d frames" % (name, d, len(frames)))
    os.makedirs(a.out, exist_ok=True)
    with open(os.path.join(a.out, "meta.json"), "w") as fh:
        json.dump(meta, fh, indent=1)


main()
