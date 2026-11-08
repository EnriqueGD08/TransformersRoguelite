# vehicon_cel.gd
# Vehicon en estilo cel: el soldado raso decepticon. Delgado, gris y morado, sin cara
# (solo un visor en V) y con una cuchilla de energon en el brazo.
# Es un enemigo: una sola apariencia ("base") y sin transformación.
# Solo define piezas: el esqueleto y las animaciones son comunes (cel_character, cel_anim).
# SRP: formas del Vehicon. OCP: no toca el esqueleto común.

extends RefCounted

const R := preload("res://tools/art2/vector_rig.gd")
const C := preload("res://tools/art2/cel_character.gd")

const SKINS := {
	"base": {"armor": Color("737887"), "armor_s": Color("4c505d"), "second": Color("8d5cc4"), "second_s": Color("603e8a"),
		"dark": Color("2a2b32"), "dark_s": Color("1a1b20"), "joint": Color("6a6f79"), "accent": Color("b07cff"),
		"eye": Color("c8a2ff"), "energy": Color("c58bff")},
}

const THIGH := 44.0
const SHIN := 50.0
const HIP_Y := 122.0
const HIP_HALF := 10.0
const SHOULDER_X := 38.0
const SHOULDER_Y := -60.0
const NECK := Vector2(1, -70)
const NEAR_FOOT := Vector2(130, 212)
const FAR_FOOT := Vector2(172, 212)
const SHADOW_W := 58.0
const HALF_STRIDE := 30.0
const LIFT := 14.0
const WALK_CENTER := 151.0
const VEHICLE_RECOIL := 0.0
const VEHICLE_HOVER := 0.0

## El tajo no sube tanto como el hachazo de Optimus: cabe en el lienzo normal.
const SWING_TOP := -125.0
const TRAIL_RADIUS := 108.0


static func back(_skin: String, _p: Dictionary) -> String:
	return ""


static func head(_skin: String, p: Dictionary) -> String:
	# Casco liso y redondeado; la cara es solo un visor en V.
	var h := R.cel(R.v([-14,2, -16,-16, -10,-28, 0,-32, 10,-28, 16,-16, 14,2, 7,9, -7,9]), p.armor, p.armor_s)
	h += R.cel(R.v([-12,-18, 0,-8, 12,-18, 11,-12, 0,-2, -11,-12]), p.dark, p.dark_s, 2.0)
	h += R.flat(R.path(R.v([-10,-16, 0,-8, 10,-16, 9,-13, 0,-5, -9,-13])), R.hex(p.eye))
	return h + R.accent(R.v([-6,4, 6,4]), p.dark, 1.8)


static func torso(_skin: String, p: Dictionary) -> String:
	var t := R.cel(R.v([-34,-68, -16,-74, 16,-74, 34,-68, 30,-44, 14,-26, 11,2, -11,2, -14,-26, -30,-44]), p.armor, p.armor_s)
	t += R.cel(R.v([-18,-68, 18,-68, 16,-48, 0,-38, -16,-48]), p.dark, p.dark_s, 2.2)
	t += R.flat(R.path(R.v([-12,-62, 0,-52, 12,-62, 10,-58, 0,-48, -10,-58])), R.hex(p.second))
	for k in 3:
		t += R.cel(R.v([-11 + k,-24 + k * 8, 11 - k,-24 + k * 8, 10 - k,-19 + k * 8, -10 + k,-19 + k * 8]), p.dark, p.dark_s, 1.4)
	return t


static func pelvis(_skin: String, p: Dictionary) -> String:
	return R.cel(R.v([-18,-6, 18,-6, 21,5, 5,15, -5,15, -21,5]), p.dark, p.dark_s) + R.accent(R.v([-10,2, 0,9, 10,2]), p.second, 2.2)


static func thigh(_skin: String, p: Dictionary) -> String:
	return R.cel(R.v([-10,-4, 10,-4, 11,34, 7,44, -7,44, -11,34]), p.joint, p.dark, 2.8) + R.cel(R.v([-10,2, -1,0, -2,28, -9,26]), p.armor, p.armor_s, 1.8)


static func shin(_skin: String, p: Dictionary) -> String:
	var s := R.cel(R.v([-11,0, 11,0, 16,22, 11,50, -11,50, -15,22]), p.armor, p.armor_s)
	s += R.cel(R.v([-10,-10, 11,-4, 11,8, 0,13, -11,7]), p.dark, p.dark_s, 2.0)
	return s + R.accent(R.v([-5,26, 5,26]), p.second, 2.4)


static func foot(_skin: String, p: Dictionary) -> String:
	return R.cel(R.v([-12,-6, 11,-6, 28,8, 26,14, -14,14, -14,4]), p.dark, p.dark_s)


static func shoulder(_skin: String, p: Dictionary, s: float) -> String:
	var m: bool = s < 0.0
	return R.cel(R.v([-11,11, -15,-4, -8,-14, 12,-12, 15,2, 10,11], m), p.armor, p.armor_s) + R.accent(R.v([-7,-7, 11,-6], m), p.second, 2.2)


static func upper_arm(p: Dictionary) -> String:
	return R.cel(R.v([-7,-2, 7,-2, 7,30, -7,30]), p.joint, p.dark_s, 2.6)


static func _forearm(p: Dictionary) -> String:
	return R.cel(R.v([-9,0, 9,0, 12,16, 9,34, -9,34, -12,16]), p.armor, p.armor_s) + R.accent(R.v([-5,12, 5,12]), p.second, 2.0)


static func fist_arm(_skin: String, p: Dictionary) -> String:
	var hand := R.cel(R.v([-9,0, 9,0, 11,9, 7,16, -7,16, -11,9]), p.dark, p.dark_s, 2.2)
	return _forearm(p) + R.joint(Vector2(0, 34), 0.0, hand)


## Cuchilla de energon que sale del antebrazo (en lugar de mano), hasta y≈80.
static func gun(_skin: String, p: Dictionary, charge: float) -> String:
	var e: Color = p.energy
	var b := R.cel(R.v([-6,30, 7,30, 10,52, 2,80, -5,56]), e, e.darkened(0.3), 2.0)
	b += R.flat(R.path(R.v([-1,36, 4,36, 5,52, 1,70, -2,54])), "#ffffff", 0.5)
	var glow := ""
	if charge > 0.01:
		glow = R.circle(0, 58, 18.0 + 10.0 * charge, "url(#e_glow)", 0.0, 0.25 + 0.5 * charge)
	return glow + b + _forearm(p)
