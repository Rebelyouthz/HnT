class_name InvoiceHeat
extends Object

## Wanted's louder cousin. Kills raise heat. Heat raises tension music.


static func bump(rs: Node, n: int) -> void:
	if rs != null and rs.has_method("add_heat"):
		rs.add_heat(n)
