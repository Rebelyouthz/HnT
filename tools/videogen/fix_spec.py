# Second pass for both heroes: blocks (start image only) and knockdowns
# (first = last = guard, so he ends back on his feet).
# job: (who, clip, start key, end key or None, prompt, seconds)
STYLE=" Full body always visible, strict side view facing right, locked static camera, plain white background, 2D beat em up game animation, crisp pixel art character, no effects."
DAD="The bearded man in a grey hoodie"
SON="The young man with curly brown hair in a black bomber jacket"
G={"father":"keys/father_jab_a.png","son":"keys/son_gut_a.png"}
JOBS=[]
for who,name in (("father",DAD),("son",SON)):
    JOBS += [
     (who,"block_high",G[who],None,name+" snaps both forearms up high in front of his face and head to block a punch, elbows up, chin tucked behind his arms, and holds that block. Feet stay planted.",1.6),
     (who,"block_mid",G[who],None,name+" pulls both forearms tight against his ribs and stomach to block a body blow, knees slightly bent, and holds that block. Feet stay planted.",1.6),
     (who,"block_low",G[who],None,name+" sinks into a low crouch and drops both forearms crossed in front of his knees to block a low kick, and holds that low block. Feet stay planted.",1.6),
     (who,"knockdown",G[who],G[who],name+" is hit hard and knocked off his feet: he falls backward flat onto his back on the floor, lies there for a moment, then rolls to his side, pushes himself up and gets back on his feet into his fighting guard.",3.3),
    ]
WALK={
 "walk_up":"walks away from the camera into the scene, seen from behind, a steady natural walking cycle in place with alternating legs and arm swing. He stays on the same spot the whole time.",
 "walk_down":"walks toward the camera, seen from the front, a steady natural walking cycle in place with alternating legs and arm swing. He stays on the same spot the whole time.",
 "walk_ur":"walks diagonally away to the upper right, seen from behind at a three-quarter angle, a steady natural walking cycle in place with alternating legs and arm swing. He stays on the same spot the whole time.",
 "walk_dr":"walks diagonally toward the lower right, three-quarter front view, a steady natural walking cycle in place with alternating legs and arm swing. He stays on the same spot the whole time.",
}
for who,name in (("father",DAD),("son",SON)):
    for c,p in WALK.items():
        k="keys/%s_%s_a.png"%(who,c)
        JOBS.append((who,c,k,k,name+" "+p,2.1))
