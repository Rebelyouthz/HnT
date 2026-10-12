class_name CampSheets
extends Object

## Camp building id -> the sheet (menu) it opens. Shared by the hub's clinic
## page and the walkable camp hideout.
const PATHS := {
	"pawn_shop": "res://src/ui/dopamine_shop.gd",
	"patrol_desk": "res://src/ui/patrol_sheet.gd",
	"research_lab": "res://src/ui/research_sheet.gd",
	"dojo": "res://src/ui/dojo_sheet.gd",
	"workshop": "res://src/ui/workshop_sheet.gd",
	"bounty_board": "res://src/ui/bounty_sheet.gd",
	"radio_tower": "res://src/ui/radio_sheet.gd",
	"album_wall": "res://src/ui/album_sheet.gd",
	"blood_fridge": "res://src/ui/fridge_sheet.gd",
	"streak_locker": "res://src/ui/streak_sheet.gd",
	"invoice_wheel": "res://src/ui/lottery_sheet.gd",
	"punching_bag": "res://src/ui/bag_sheet.gd",
	"warrant_fax": "res://src/ui/fax_sheet.gd",
	"tip_jar": "res://src/ui/tip_sheet.gd",
	"lost_found": "res://src/ui/lost_sheet.gd",
	"payphone": "res://src/ui/phone_sheet.gd",
	"water_cooler": "res://src/ui/cooler_sheet.gd",
	"coat_check": "res://src/ui/coat_sheet.gd",
	"time_clock": "res://src/ui/clock_sheet.gd",
	"bleach_closet": "res://src/ui/bleach_sheet.gd",
}

## The five core rooms open a hub tab.
const TAB_OF := {
	"front_desk": "clinic",
	"street_map": "run",
	"therapy_couch": "build",
	"wardrobe_cage": "locker",
	"trophy_cabinet": "awards",
}


static func path(id: String) -> String:
	return str(PATHS.get(id, ""))
