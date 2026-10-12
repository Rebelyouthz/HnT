# Son clips remade like the Father's (guard -> peak key poses, Wan 2.2 first/last frame).
# clip: (start (board, idx), end (board, idx) or None, prompt, mode)
G=("son-jab-punch.png",0)  # his guard
RUN=("son-parkour-run.png",5)
STYLE=" Full body always visible, strict side view facing right, locked static camera, plain white background, 2D beat em up game animation, crisp pixel art character, no effects, no sparks."
WHO="The young man with curly brown hair in a black bomber jacket, dark joggers and white sneakers"
SPEC={
 "idle": (G, None, WHO+" holds a loose fighting guard and stays in place, breathing.", "loop"),
 "gut":        (G, ("son-gut-punch.png",6), "From his guard, "+WHO.lower()[4:]+" dips his knees and drives a fast hook punch into the stomach of an imaginary opponent on the right, twisting his torso, the arm fully extended at the end. Feet stay planted.", "strike"),
 "side_kick":  (G, ("son-side-kick.png",4), "From his guard, "+WHO.lower()[4:]+" turns his hip and fires a fast high side kick to the right, the leg fully extended horizontally, torso leaning back for balance.", "strike"),
 "slide":      (RUN, ("son-slide-crouch.png",5), WHO+" runs fast and drops into a low baseball slide along the ground to the right, one leg extended forward, leaning back.", "move"),
 "snap":       (G, ("son-snap-flash.png",8), "From his guard, "+WHO.lower()[4:]+" lunges forward and shoves both palms out hard to the right in a powerful two handed palm strike, arms fully extended.", "strike"),
 "dive":       (RUN, ("son-dive-drop.png",3), WHO+" launches into a forward superman dive to the right, body horizontal, arms stretched forward, flying through the air.", "air"),
 "air_mix":    (("son-air-mix.png",1), ("son-air-mix.png",4), "In mid air "+WHO.lower()[4:]+" leaps forward and throws a flying jump kick to the right, one leg fully extended, the other tucked.", "air"),
 "hurt":       (("son-hurt-recoil.png",8), ("son-hurt-recoil.png",1), WHO+" is shoved hard: his head and shoulders snap back, his body recoils backward with the impact, arms flailing.", "strike"),
 "duck":       (G, ("son-duck-crouch.png",0), WHO+" quickly drops into a low defensive crouch, knees bent, one hand near the floor, head tucked.", "strike"),
}
