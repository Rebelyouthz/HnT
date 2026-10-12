## Son move jobs for genq-style generation: (name, seconds, seed, prompt, startkey)
F = "The teenage boy in the black zip jacket with long sleeves"
STANCE = " He starts and ends standing relaxed in the same pose."
MOVES = [
 ("son_run", 3.0, 5, F + " runs to the right on a treadmill at a fast sprint, long strides, knees driving up, arms pumping hard, leaning forward, continuous run cycle.", "sleeve"),
 ("son_jab", 1.6, 9, F + " raises his fists and throws one fast straight jab with his front fist at head height, snapping the arm fully out and back." + STANCE, "son"),
 ("son_cross", 1.8, 11, F + " raises his fists and throws a hard straight right cross at head height, rotating his hips and shoulders, arm fully extended, then pulls it back." + STANCE, "son"),
 ("son_heavy", 2.2, 13, F + " winds up and throws a huge looping haymaker punch with his whole body weight, follows through, then recovers." + STANCE, "son"),
 ("son_front_kick", 2.0, 15, F + " snaps a fast front kick straight forward at stomach height with his front leg, leg fully extended, then puts the foot back down." + STANCE, "son"),
 ("son_roundhouse", 2.4, 17, F + " spins his hips and throws a high roundhouse kick at head height, the leg sweeping in a wide arc, then lands back in place." + STANCE, "son"),
 ("son_hurt", 1.6, 19, F + " flinches hard as if punched in the face, his head snaps back and he staggers half a step backward, then recovers his balance." + STANCE, "son"),
 ("son_jump", 2.0, 21, F + " bends his knees and jumps straight up high in place, tucks his knees at the top, then lands softly bending his knees." + STANCE, "son"),
 ("son_duck", 1.8, 23, F + " quickly crouches down low to dodge, ducking his head with fists up, holds it a moment, then stands back up." + STANCE, "son"),
 ("son_roll", 2.2, 25, F + " drops into a fast forward shoulder roll along the ground and comes back up to his feet in one smooth motion." + STANCE, "son"),
 ("son_knockdown", 3.5, 27, F + " is hit hard, flies backward off his feet and falls flat on his back on the ground, lies there, then slowly gets up." + STANCE, "son"),
]
MOVES.append(("son_sprint", 3.0, 7, F + " sprints to the right on a treadmill at full speed like an athlete, legs driving hard, knees high, back foot kicking up behind, arms pumping, body leaning forward, continuous fast running cycle.", "sprint"))
ENEMY_WHO = {
 "bag_snatch": "The street thug in the red hoodie, white bandana mask and messenger bag",
 "punk": "The thug in the yellow beanie, black leather jacket and ripped jeans holding a clipboard",
 "mohawk": "The skinny punk with the spiked mohawk, black leather jacket and ripped jeans",
 "shift_lead": "The burly worker in the orange high visibility vest and work boots",
 "cop": "The police officer in the blue uniform and peaked cap",
 "roof_runner": "The athletic rooftop thug in the black tank top and yellow headband",
}
ENEMY_MOVES = [
 ("idle", 2.5, "stands in a loose fighting stance, breathing heavily and bouncing slightly, shifting his weight, ready to brawl. He stays in place.", "idle"),
 ("walk", 3.0, "walks forward to the right on a treadmill with a menacing swagger, long clear strides, fists ready, continuous walk cycle.", "stride"),
 ("punch_high", 2.0, "throws a hard right hook at head height with a big shoulder turn, then returns to his fighting stance.", "idle"),
 ("hurt", 1.8, "flinches hard as if punched, his head jerks back and he staggers one step backward, then recovers his balance.", "idle"),
 ("death", 3.5, "is hit hard, goes limp, collapses and falls backward flat onto the ground and lies still, then slowly gets up.", "idle"),
]
for _w, _d in ENEMY_WHO.items():
    for _m, _s, _p, _k in ENEMY_MOVES:
        MOVES.append((f"{_w}_{_m}", _s, 31, _d + " " + _p, f"{_w}_{_k}"))
MOVES.append(("son_hurt2", 1.6, 61, F + " gets hit hard in the face by an invisible punch: his head and shoulders whip backward, his whole upper body bends back, arms fly up, he stumbles one big step backward, then straightens up again." + STANCE, "son"))
MOVES.append(("son_roll2", 2.0, 83, F + " dives forward and tucks into a full somersault forward roll on the ground, his back rolling over the floor with knees tucked to his chest, then pops back up onto his feet facing right." + STANCE, "son"))
