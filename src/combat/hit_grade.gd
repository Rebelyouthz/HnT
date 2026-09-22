class_name HitGrade
extends Object

## Jab vs cross vs BAM. SoR4 string reading, HnT billing.


static func of_lights(n: int) -> String:
	if n <= 1:
		return "jab"
	if n == 2:
		return "cross"
	return "bam"


static func shout(grade: String) -> String:
	match grade:
		"jab":
			return "JAB"
		"cross":
			return "CROSS"
		"bam":
			return "BAM"
		_:
			return grade.to_upper()


static func dmg(grade: String) -> int:
	match grade:
		"jab":
			return 6
		"cross":
			return 9
		"bam":
			return 16
		_:
			return 8
