# clip: (start (board, idx), end (board, idx) or None, prompt, mode)
# mode: loop | strike | move ; anchor center for airborne clips
G=("father-jab.png",0)  # boxing guard
STYLE=" Full body always visible, strict side view facing right, locked static camera, plain white background, 2D beat em up game animation, crisp pixel art character."
SPEC={
 "idle":       (G, None, "The bearded man in a grey hoodie holds a relaxed boxing guard and bounces lightly on the balls of his feet, breathing, small natural weight shifts, fists up. He stays in place.", "loop"),
 "parkour_run":(("father-parkour-run.png",5), None, "The bearded man in a grey hoodie sprints in place facing right, an athletic fast running cycle with high knees, long strides and strong opposite arm pumps, leaning forward. He keeps running the whole time.", "loop"),
 "jump":       (("father-jump.png",0), ("father-jump.png",11), "The man crouches, explodes upward into a high athletic jump, tucks his knees at the top, then falls and lands softly back into a crouch.", "air"),
 "duck":       (("father-duck.png",0), ("father-duck.png",7), "The man quickly drops into a low defensive crouch, knees bent, guard up, head tucked.", "strike"),
 "hurt":       (("father-hurt.png",4), ("father-hurt.png",0), "The man is hit hard in the face: his head snaps back, his body recoils backward with the impact, arms flailing.", "strike"),
 "jab":        (G, ("father-jab.png",7), "From his boxing guard, the man throws a fast snappy straight jab with his lead fist toward the right, shoulder and hip rotate, the arm fully extends. Feet stay planted.", "strike"),
 "cross":      (("father-cross.png",0), ("father-cross.png",8), "From his guard, the man throws a powerful rear straight cross toward the right, pivoting his back foot and rotating his hips and shoulders through the punch until the arm is fully extended.", "strike"),
 "gut":        (("father-gut-casual.png",0), ("father-gut-casual.png",7), "The man dips low and drives a hard hook punch into the stomach of an imaginary opponent on the right, bending his knees and twisting his torso.", "strike"),
 "heavy":      (("father-heavy-casual.png",0), ("father-heavy-casual.png",11), "The man winds up and throws a massive haymaker punch toward the right with his whole body weight behind it, stepping in, the arm fully extended at the end.", "strike"),
 "front_kick": (G, ("father-front-kick-casual.png",3), "From his guard the man chambers his knee and snaps a fast front push kick straight forward to the right, leg fully extended at chest height, arms up for balance.", "strike"),
 "side_kick":  (G, ("father-side-kick-casual.png",7), "From his guard the man turns his hip and fires a powerful side kick to the right, the leg fully extended horizontally, torso leaning back for balance.", "strike"),
 "roundhouse": (G, ("father-roundhouse-casual.png",6), "From his guard the man pivots on his standing foot and swings a fast high roundhouse kick to the right, the leg whipping around to head height, arms counterbalancing.", "strike"),
 "uppercut":   (("father-uppercut-casual.png",3), ("father-uppercut-casual.png",7), "From a low crouch the man explodes upward with a rising uppercut, driving his fist high into the air above his head, legs extending.", "strike"),
 "air_mix":    (("father-air-mix-casual.png",3), ("father-air-mix-casual.png",9), "In mid air the man leaps forward and throws a flying jump kick to the right, one leg fully extended, the other tucked.", "air"),
 "slide":      (("father-slide-casual.png",0), ("father-slide-casual.png",9), "Running fast, the man drops into a low baseball slide along the ground to the right, one leg extended forward, leaning back.", "move"),
 "dive":       (("father-parkour-run.png",5), ("father-dive-casual.png",3), "The man launches into a forward superman dive to the right, body horizontal, arms stretched forward, flying through the air.", "air"),
 "snap":       (("father-snap-casual.png",0), ("father-snap-casual.png",6), "The man grabs a stunned thug standing in front of him by the collar and violently throws him over his hip down to the ground in a brutal finishing move.", "strike"),
}
