# constructicon_cel.gd
# Constructicon en estilo cel: obrero pesado decepticon, verde y morado como el equipo
# de Devastator. Ancho y bajo, con la cabeza hundida y una pala excavadora por brazo.
# Es un enemigo: una sola apariencia ("base") y sin transformación.
# Solo define piezas: el esqueleto y las animaciones son comunes (cel_character, cel_anim).
# SRP: formas del Constructicon. OCP: no toca el esqueleto común.

extends RefCounted

const R := preload("res://tools/art2/vector_rig.gd")
const C := preload("res://tools/art2/cel_character.gd")

const SKINS := {
	"base": {"armor": Color("5aa83c"), "armor_s": Color("3b7a27"), "second": Color("6c3f8c"), "second_s": Color("4a2a63"),
		"dark": Color("2b2e34"), "dark_s": Color("1b1d21"), "joint": Color("7a7f8a"), "accent": Color("ffd23a"),
		"eye": Color("ff3b30"), "energy": Color("ffcf4a")},
}

const THIGH := 40.0
const SHIN := 46.0
const HIP_Y := 128.0
const HIP_HALF := 18.0
const SHOULDER_X := 58.0
const SHOULDER_Y := -56.0
const NECK := Vector2(0, -62)
const NEAR_FOOT := Vector2(118, 212)
const FAR_FOOT := Vector2(184, 212)
const SHADOW_W := 88.0
const HALF_STRIDE := 26.0
const LIFT := 10.0
const WALK_CENTER := 152.0
const VEHICLE_RECOIL := 0.0
const VEHICLE_HOVER := 0.0

## Golpe contra el suelo: no sube tanto y la estela es corta.
const SWING_TOP := -118.0
const TRAIL_RADIUS := 104.0


static func back(_skin: String, p: Dictionary) -> String:
	# Tubo de escape a un lado, como una máquina de obra.
	var b := R.cel(R.v([30,-56, 42,-56, 42,-104, 30,-104]), p.joint, p.dark_s, 2.4)
	return b + R.cel(R.v([28,-104, 44,-104, 44,-112, 28,-112]), p.dark, p.dark_s, 2.0)


static func head(_skin: String, p: Dictionary) -> String:
	# Cabeza pequeña hundida entre los hombros, con visor rojo y casco de obra.
	var h := R.cel(R.v([-15,6, -16,-14, -10,-22, 10,-22, 16,-14, 15,6]), p.second, p.second_s)
	h += R.cel(R.v([-18,-14, 18,-14, 14,-26, -14,-26]), p.accent, p.accent.darkened(0.3), 2.2)
	h += R.cel(R.v([-11,-11, 11,-11, 10,-2, -10,-2]), p.dark, p.dark_s, 1.8)
	h += R.flat(R.path(R.v([-9,-9, 9,-9, 8,-5, -8,-5])), R.hex(p.eye))
	return h + R.cel(R.v([-8,-1, 8,-1, 6,6, -6,6]), p.joint, p.dark, 1.6)


static func torso(_skin: String, p: Dictionary) -> String:
	var t := R.cel(R.v([-56,-66, -40,-72, 40,-72, 56,-66, 54,-36, 36,-20, 30,2, -30,2, -36,-20, -54,-36]), p.armor, p.armor_s)
	# Cabina de máquina en el pecho y franjas de peligro.
	t += R.cel(R.v([-26,-64, 26,-64, 24,-38, -24,-38]), p.dark, p.dark_s, 2.2)
	t += C.window(R.v([-22,-60, -2,-60, -2,-42, -20,-42]), {"glass": Color("6ab0c8")})
	t += C.window(R.v([2,-60, 22,-60, 20,-42, 2,-42]), {"glass": Color("6ab0c8")})
	for k in 4:
		var x: float = -28.0 + k * 16.0
		t += R.cel(R.v([x,-30, x + 8,-30, x + 2,-22, x - 6,-22]), p.accent, p.accent.darkened(0.3), 1.4)
	t += R.cel(R.v([-26,-20, 26,-20, 24,2, -24,2]), p.second, p.second_s, 2.2)
	return t + R.accent(R.v([-14,-9, 14,-9]), p.second_s, 2.2)


static func pelvis(_skin: String, p: Dictionary) -> String:
	return R.cel(R.v([-28,-6, 28,-6, 32,6, 12,16, -12,16, -32,6]), p.dark, p.dark_s) + R.accent(R.v([-16,3, 16,3]), p.accent, 2.4)


static func thigh(_skin: String, p: Dictionary) -> String:
	return R.cel(R.v([-16,-4, 16,-4, 17,30, 12,40, -12,40, -17,30]), p.second, p.second_s)


static func shin(_skin: String, p: Dictionary) -> String:
	# Pierna de oruga: bloque ancho con la cadena a la vista.
	var s := R.cel(R.v([-20,0, 20,0, 24,30, 20,46, -20,46, -24,30]), p.armor, p.armor_s)
	s += R.cel(R.v([-16,-8, 16,-8, 16,8, 0,14, -16,8]), p.dark, p.dark_s, 2.2)
	s += R.cel(R.v([-14,22, 14,22, 14,40, -14,40]), p.dark, p.dark_s, 2.0)
	for y in [27, 33, 39]:
		s += R.accent(R.v([-11,y, 11,y]), p.joint, 1.6)
	return s


static func foot(_skin: String, p: Dictionary) -> String:
	return R.cel(R.v([-22,-6, 20,-6, 34,6, 34,14, -24,14, -24,4]), p.dark, p.dark_s) + R.accent(R.v([-14,9, 26,9]), p.accent, 2.2)


static func shoulder(_skin: String, p: Dictionary, s: float) -> String:
	var m: bool = s < 0.0
	var o := R.cel(R.v([-18,-16, 22,-16, 24,16, 16,20, -16,20, -20,12], m), p.armor, p.armor_s)
	return o + R.cel(R.v([-12,-10, 16,-10, 16,-4, -12,-4], m), p.accent, p.accent.darkened(0.3), 1.6)


static func upper_arm(p: Dictionary) -> String:
	return R.cel(R.v([-11,-2, 11,-2, 11,30, -11,30]), p.joint, p.dark_s, 2.8)


static func fist_arm(_skin: String, p: Dictionary) -> String:
	var f := R.cel(R.v([-15,0, 15,0, 18,24, 15,38, -15,38, -18,24]), p.armor, p.armor_s)
	var claw := R.cel(R.v([-13,0, 13,0, 15,10, 11,18, -11,18, -15,10]), p.dark, p.dark_s, 2.4)
	for x in [-9, 0, 9]:
		claw += R.shape(R.path(R.v([x - 3,16, x + 3,16, x,28])), R.hex(p.joint), 1.6)
	return f + R.joint(Vector2(0, 38), 0.0, claw)


## Brazo-pala: brazo hidráulico y una pala dentada al final (y≈80).
static func gun(_skin: String, p: Dictionary, charge: float) -> String:
	var g := R.cel(R.v([-15,0, 15,0, 18,24, 15,36, -15,36, -18,24]), p.armor, p.armor_s)
	g += R.cel(R.v([-6,30, 6,30, 6,52, -6,52]), p.joint, p.dark, 2.2)
	# Pala: cuenco con dientes, abierto hacia delante.
	g += R.cel(R.v([-22,48, 22,48, 28,64, 20,80, -20,80, -26,64]), p.second, p.second_s)
	g += R.cel(R.v([-16,54, 16,54, 18,66, -18,66]), p.dark, p.dark_s, 1.8)
	for x in [-16, -6, 4, 14]:
		g += R.shape(R.path(R.v([x,78, x + 6,78, x + 3,88])), R.hex(p.joint), 1.6)
	if charge > 0.6:
		g += R.circle(0, 72, 26.0 * (charge - 0.6) * 2.5, "url(#e_glow)", 0.0, 0.6)
	return g
