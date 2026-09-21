class_name Copy
extends Object

const TAB_CLINIC := "CLINIC"
const TAB_RUN := "RUN"
const TAB_BUILD := "BUILD"
const TAB_LOCKER := "LOCKER"
const TAB_AWARDS := "AWARDS"

const LOGO := "HnT"
const SUB := "REVENGE & THERAPY"
const TAGLINE := "Illegal clinic. Legal violence."

const CLAIM := "CLAIM"
const CLAIMED := "FILED"
const LOCKED := "COME BACK AFTER YOU BUILD THE COUCH"
const EMPTY_LOG := "NOBODY WROTE. SHOCKING."
const GROWTH := "GROWTH UNLOCKED"
const HEALTHY := "THAT'S HEALTHY"
const INTAKE := "NAME THE PATIENTS"
const PLAY := "GO TALK TO THE LANDLORD"
const HOST := "HOST (THE SON)"
const JOIN := "JOIN (THE FATHER)"
const HOST_HINT := "Room codes land after the slice. Tonight is the same couch."
const PAUSE := "SESSION PAUSED"
const FAIL := "THERAPY'S OVER"
const DAILY := "TODAY'S COPING GOALS"
const LIFE := "FAMILY PROGRESS"
const BUILD_HINT := "Upgrade the furniture. Unlock the menus. Pretend that's healing."

static func come_on(father: String, son: String, who: String) -> String:
	if who == "father":
		return "COME ON, %s" % father
	return "%s, GET OFF THE ROOF" % son
