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
const CLEAR := "DOCK STREET FILED"
const CLEAR_SUB := "24/7 Blood Mart is still a metaphor. You lived."
const SNAP := "SNAP"
const GROUNDED := "GROUNDED"
const DAILY := "TODAY'S COPING GOALS"
const LIFE := "FAMILY PROGRESS"
const BUILD_HINT := "Upgrade the furniture. Unlock the menus. Pretend that's healing."

const SOLO := "SOLO"
const COUCH := "COUCH 2P"
const GO_SOLO := "GO ALONE"
const GO_COUCH := "GO TOGETHER"
const JOIN_HINT := "Pad Start or keyboard P sits the other role down. Enemies do not multiply."
const SOLO_HINT := "One body. Fewer punks. Same street. Nobody has to wait."
const COUCH_HINT := "Two bodies. Full roster. Shared lives. The leash is the relationship."
const FIRE_CLEAR := "FIRE ESCAPES FILED"
const FIRE_SUB := "Roofs filed. The vendor still wants a tip."
const NEXT_MAP := "THE FIRE ESCAPES"
const GATE_SUB := "Blood Mart is a checkpoint, not a personality. Roofs are next."
const CLINIC_PLAY_SUB := "Starts solo. Couch 2P lives on the Run tab. No one has to plug in."

static func come_on(father: String, son: String, who: String) -> String:
	if who == "father":
		return "COME ON, %s" % father
	return "%s, GET OFF THE ROOF" % son
