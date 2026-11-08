# arcee_pistols_cel.gd
# Arcee con las pistolas fotónicas: el mismo diseño que arcee_cel.gd, otras armas.
# OCP: reutiliza todas las piezas por herencia y solo sustituye las de los brazos.

extends "res://tools/art2/arcee_cel.gd"

## Las pistolas son cortas: el fogonazo sale más cerca que el de un cañón.
const FLASH_Y := 62.0


## Pistola: empuñadura en la mano y cañón hacia y≈68.
static func _pistol(skin: String, p: Dictionary, charge: float) -> String:
	var e: Color = p.energy
	var g := ""
	match skin:
		"g1":
			g += R.cel(R.v([-7,42, 7,42, 7,64, 4,68, -4,68, -7,64]), p.second, p.second_s, 2.0)
			g += R.accent(R.v([0,48, 0,62]), p.armor, 2.4)
		"prime":
			g += R.cel(R.v([-6,40, 6,40, 8,60, 0,70, -8,60]), p.dark, p.dark_s, 2.0)
			g += R.accent(R.v([0,46, 0,62]), p.second, 2.4)
		_:
			g += R.cel(R.v([-7,42, 7,42, 9,54, 5,58, 6,68, -6,68, -5,58, -9,54]), p.second, p.second_s, 2.0)
			g += R.accent(R.v([-3,46, -3,64]), e, 1.8)
			g += R.accent(R.v([3,46, 3,64]), e, 1.8)
	if charge > 0.01:
		g += R.circle(0, 68, 8.0 + 8.0 * charge, "url(#e_glow)", 0.0, 0.3 + 0.5 * charge)
	return g


static func _armed(skin: String, p: Dictionary, charge: float) -> String:
	return _pistol(skin, p, charge) + _forearm(skin, p) + R.joint(Vector2(0, 32), 0.0, _hand(p))


static func fist_arm(skin: String, p: Dictionary) -> String:
	return _armed(skin, p, 0.15)


static func gun(skin: String, p: Dictionary, charge: float) -> String:
	return _armed(skin, p, charge)
