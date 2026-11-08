# arcee_cel.gd
# Arcee en estilo cel, con las cuchillas en las manos. La versión con pistolas es
# arcee_pistols_cel.gd, que solo cambia las armas.
# Es la más esbelta: cintura fina, caderas marcadas y piernas largas.
# Cada skin tiene su silueta y su moto:
#   G1: rosa y blanca, de formas redondeadas → moto futurista carenada.
#   Prime: azul con detalles rosas, aletas en la cabeza → deportiva angulosa.
#   Bay: magenta y metal, muy delgada, ruedas a la espalda → superbike con chasis a la vista.
# Solo define piezas: el esqueleto y las animaciones son comunes (cel_character, cel_anim).
# SRP: formas de Arcee. OCP: no toca el esqueleto común.

extends RefCounted

const R := preload("res://tools/art2/vector_rig.gd")
const C := preload("res://tools/art2/cel_character.gd")

const SKINS := {
	"g1": {"armor": Color("f06aa8"), "armor_s": Color("b63f7b"), "second": Color("f1f2f6"), "second_s": Color("bfc2cc"),
		"dark": Color("3b4060"), "dark_s": Color("262a42"), "joint": Color("7d8290"), "accent": Color("5fd0ff"),
		"eye": Color("5fd0ff"), "energy": Color("ff9ad1"), "glass": Color("8fd8f0")},
	"prime": {"armor": Color("3274c6"), "armor_s": Color("1f4c8c"), "second": Color("e84a8a"), "second_s": Color("a82d62"),
		"dark": Color("262931"), "dark_s": Color("16181d"), "joint": Color("5b616d"), "accent": Color("ff9ac4"),
		"eye": Color("7fdcff"), "energy": Color("ff6fb0"), "glass": Color("5a7ea0")},
	"bay": {"armor": Color("cc3280"), "armor_s": Color("8e1f57"), "second": Color("3b3e46"), "second_s": Color("24262c"),
		"dark": Color("2b2d34"), "dark_s": Color("1a1b20"), "joint": Color("8f95a0"), "accent": Color("ff7ab8"),
		"eye": Color("6fd2ff"), "energy": Color("ff4fa0"), "glass": Color("54626e")},
}

const THIGH := 44.0
const SHIN := 50.0
const HIP_Y := 122.0
const HIP_HALF := 9.0
const SHOULDER_X := 32.0
const SHOULDER_Y := -58.0
const NECK := Vector2(1, -68)
const NEAR_FOOT := Vector2(134, 212)
const FAR_FOOT := Vector2(168, 212)
const SHADOW_W := 50.0
const HALF_STRIDE := 30.0
const LIFT := 15.0
const WALK_CENTER := 151.0
const VEHICLE_RECOIL := 14.0
const VEHICLE_HOVER := 0.0

# ── Espalda ───────────────────────────────────────────────────────────────────

static func back(skin: String, p: Dictionary) -> String:
	var b := ""
	match skin:
		"g1":
			# Dos aletas blancas redondeadas.
			for s in [1, -1]:
				b += R.cel(R.v([-14,-58, -38,-80, -48,-70, -40,-50, -20,-38], s > 0), p.second, p.second_s, 2.6)
		"prime":
			# Aletas finas barridas hacia arriba.
			for s in [1, -1]:
				b += R.cel(R.v([-14,-56, -36,-96, -44,-88, -32,-50, -20,-38], s > 0), p.armor, p.armor_s, 2.6)
				b += R.accent(R.v([-22,-54, -36,-84], s > 0), p.second, 2.2)
		_:
			# Las ruedas de la moto a la espalda, una a cada lado.
			for s in [1, -1]:
				var x: float = 34.0 * s
				b += R.circle(x, -62, 21.0, "#20232a", 2.6)
				b += R.circle(x, -62, 11.0, R.hex(p.joint), 2.0)
				b += R.circle(x, -62, 4.0, R.hex(p.energy))
	return b

# ── Cabeza ────────────────────────────────────────────────────────────────────

static func head(skin: String, p: Dictionary) -> String:
	var h := ""
	match skin:
		"g1":
			# Casco blanco redondeado, cresta rosa, cara clara con visera azul.
			h += R.cel(R.v([-15,2, -17,-14, -12,-28, -4,-33, 4,-33, 12,-28, 17,-14, 15,2, 9,8, 9,-12, -9,-12, -9,8]), p.second, p.second_s)
			h += R.cel(R.v([-4,-37, 4,-37, 6,-18, -6,-18]), p.armor, p.armor_s, 2.0)
			h += R.cel(R.v([-9,-14, 9,-14, 8,0, 3,7, -3,7, -8,0]), Color("f4d9cf"), Color("cfa79a"), 2.0)
			h += R.flat(R.path(R.v([-8,-11, 8,-11, 8,-6, -8,-6])), R.hex(p.eye))
			h += R.accent(R.v([-3,2, 3,2]), p.armor_s, 1.8)
		"prime":
			# Casco ceñido con dos aletas largas hacia arriba y atrás.
			for s in [1, -1]:
				h += R.cel(R.v([s * 10,-14, s * 26,-44, s * 20,-44, s * 8,-24]), p.armor, p.armor_s, 2.2)
				h += R.accent(R.v([s * 13,-20, s * 22,-38]), p.second, 1.8)
			h += R.cel(R.v([-13,2, -15,-14, -8,-26, 0,-31, 8,-26, 15,-14, 13,2, 7,9, 7,-11, -7,-11, -7,9]), p.armor, p.armor_s)
			h += R.cel(R.v([-8,-13, 8,-13, 7,0, 0,9, -7,0]), p.second, p.second_s, 2.0)
			h += R.flat(R.path(R.v([-7,-10, -1,-7, -1,-5, -7,-7])), R.hex(p.eye))
			h += R.flat(R.path(R.v([7,-10, 1,-7, 1,-5, 7,-7])), R.hex(p.eye))
		_:
			# Cabeza pequeña y afilada, de placas en punta.
			for s in [1, -1]:
				h += R.cel(R.v([s * 8,-8, s * 22,-14, s * 17,-24, s * 8,-20]), p.armor, p.armor_s, 2.0)
			h += R.cel(R.v([-11,0, -13,-14, -6,-24, -2,-35, 2,-35, 6,-24, 13,-14, 11,0, 0,12]), p.armor, p.armor_s)
			h += R.cel(R.v([-8,-13, 8,-13, 6,-1, 0,7, -6,-1]), p.dark, p.dark_s, 1.8)
			h += R.flat(R.path(R.v([-7,-11, -2,-8, -2,-6, -7,-8])), R.hex(p.eye))
			h += R.flat(R.path(R.v([7,-11, 2,-8, 2,-6, 7,-8])), R.hex(p.eye))
	return h

# ── Torso ─────────────────────────────────────────────────────────────────────

static func torso(skin: String, p: Dictionary) -> String:
	var t := ""
	match skin:
		"g1":
			t += R.cel(R.v([-30,-66, 30,-66, 32,-46, 16,-28, 10,2, -10,2, -16,-28, -32,-46]), p.armor, p.armor_s)
			t += R.cel(R.v([-24,-62, -3,-62, -3,-44, -18,-42]), p.second, p.second_s, 2.2)
			t += R.cel(R.v([24,-62, 3,-62, 3,-44, 18,-42]), p.second, p.second_s, 2.2)
			t += C.autobot_insignia(Vector2(0, -36), 0.6, p.accent)
			t += R.cel(R.v([-12,-26, 12,-26, 9,2, -9,2]), p.second, p.second_s, 2.0)
			t += R.accent(R.v([-6,-14, 6,-14]), p.second_s, 1.8)
		"prime":
			t += R.cel(R.v([-32,-64, -18,-70, 18,-70, 32,-64, 26,-42, 11,-24, 9,2, -9,2, -11,-24, -26,-42]), p.armor, p.armor_s)
			t += R.cel(R.v([-14,-66, 14,-66, 13,-46, 0,-34, -13,-46]), p.second, p.second_s, 2.0)
			t += R.cel(R.v([-8,-61, 8,-61, 7,-48, 0,-41, -7,-48]), p.glass, p.glass.darkened(0.3), 1.6)
			for k in 3:
				t += R.cel(R.v([-10 + k,-22 + k * 8, 10 - k,-22 + k * 8, 9 - k,-17 + k * 8, -9 + k,-17 + k * 8]), p.dark, p.dark_s, 1.4)
		_:
			# Casi esquelética: costillas de metal bajo unas placas magenta.
			t += R.cel(R.v([-14,-30, 14,-30, 9,2, -9,2]), p.second, p.second_s, 2.2)
			for k in 3:
				t += R.accent(R.v([-9 + k,-22 + k * 7, 9 - k,-22 + k * 7]), p.joint, 1.8)
			t += R.cel(R.v([-30,-64, -16,-72, 0,-66, 16,-72, 30,-64, 26,-46, 12,-30, 0,-36, -12,-30, -26,-46]), p.armor, p.armor_s)
			t += R.cel(R.v([-10,-62, 10,-62, 8,-46, 0,-40, -8,-46]), p.dark, p.dark_s, 1.8)
			t += R.flat(R.path(R.v([-3,-58, 3,-58, 2,-48, -2,-48])), R.hex(p.energy))
	return t


static func pelvis(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-18,-6, 18,-6, 21,6, 5,15, -5,15, -21,6]), p.armor, p.armor_s) + R.cel(R.v([-4,-2, 4,-2, 0,11]), p.second, p.second_s, 1.6)
		"prime":
			return R.cel(R.v([-16,-6, 16,-6, 20,5, 4,15, -4,15, -20,5]), p.dark, p.dark_s) + R.accent(R.v([-10,2, 0,9, 10,2]), p.second, 2.2)
		_:
			return R.cel(R.v([-15,-6, 15,-6, 20,4, 9,8, 4,15, -4,15, -9,8, -20,4]), p.second, p.second_s) + R.accent(R.v([-7,1, 7,1]), p.armor, 2.0)

# ── Piernas ───────────────────────────────────────────────────────────────────

static func thigh(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-11,-4, 11,-4, 11,34, 7,44, -7,44, -11,34]), p.second, p.second_s)
		"prime":
			return R.cel(R.v([-10,-4, 10,-4, 10,34, 6,44, -6,44, -10,34]), p.dark, p.dark_s) + R.cel(R.v([-9,2, 0,0, -1,28, -8,26]), p.armor, p.armor_s, 1.6)
		_:
			return R.cel(R.v([-8,-4, 8,-4, 9,16, 6,28, 8,36, 5,44, -5,44, -8,36, -6,26, -9,14]), p.joint, p.dark, 2.8)


static func shin(skin: String, p: Dictionary) -> String:
	var s := ""
	match skin:
		"g1":
			s += R.cel(R.v([-11,0, 11,0, 15,20, 11,50, -11,50, -15,20]), p.armor, p.armor_s)
			s += R.cel(R.v([-9,-7, 9,-7, 9,6, 0,11, -9,6]), p.second, p.second_s, 2.0)
			s += R.accent(R.v([-6,28, 6,28]), p.second, 2.2)
		"prime":
			s += R.cel(R.v([-9,0, 10,0, 15,24, 9,50, -9,50, -13,24]), p.armor, p.armor_s)
			s += R.cel(R.v([-9,-14, 10,-4, 10,8, 0,12, -10,6]), p.second, p.second_s, 2.0)
			s += R.accent(R.v([-4,24, -2,44]), p.second, 2.4)
		_:
			s += R.cel(R.v([-9,0, 9,0, 14,16, 9,26, 13,38, 8,50, -8,50, -13,36, -9,24, -14,14]), p.armor, p.armor_s)
			s += R.cel(R.v([-8,-7, 3,-11, 9,-3, 7,7, -3,11, -9,5]), p.joint, p.dark, 2.0)
			s += R.accent(R.v([-3,22, 4,22]), p.second, 2.2)
	return s


static func foot(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-10,-6, 10,-6, 28,8, 28,14, -13,14, -13,4]), p.second, p.second_s)
		"prime":
			# Pie en punta, con tacón.
			return R.cel(R.v([-9,-6, 9,-6, 32,11, 28,14, 4,10, -6,14, -13,14, -12,3]), p.dark, p.dark_s)
		_:
			return R.cel(R.v([-8,-6, 8,-6, 30,10, 26,14, 2,10, -4,14, -11,14, -11,3]), p.second, p.second_s)

# ── Brazos ────────────────────────────────────────────────────────────────────

static func shoulder(skin: String, p: Dictionary, s: float) -> String:
	var m: bool = s < 0.0
	match skin:
		"g1":
			return R.cel(R.v([-10,-10, 11,-10, 13,8, 7,12, -7,12, -11,7], m), p.armor, p.armor_s) + R.accent(R.v([-5,-5, 7,-5], m), p.second, 2.2)
		"prime":
			return R.cel(R.v([-9,10, -13,-3, -6,-14, 12,-18, 14,2, 9,10], m), p.armor, p.armor_s) + R.accent(R.v([-5,-7, 10,-11], m), p.second, 2.2)
		_:
			return R.cel(R.v([-9,10, -14,-4, -6,-8, -6,-18, 8,-11, 14,-3, 10,10], m), p.armor, p.armor_s)


static func upper_arm(p: Dictionary) -> String:
	return R.cel(R.v([-6,-2, 6,-2, 6,30, -6,30]), p.joint, p.dark_s, 2.6)


static func _forearm(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-8,0, 8,0, 11,16, 9,32, -9,32, -11,16]), p.armor, p.armor_s) + R.accent(R.v([-5,10, 5,10]), p.second, 2.2)
		"prime":
			return R.cel(R.v([-7,0, 7,0, 11,14, 7,32, -7,32, -11,14]), p.armor, p.armor_s) + R.accent(R.v([-3,8, 3,24]), p.second, 2.2)
		_:
			return R.cel(R.v([-7,0, 7,0, 11,10, 7,18, 10,26, 7,32, -7,32, -10,24, -7,16, -11,8]), p.armor, p.armor_s)


static func _hand(p: Dictionary) -> String:
	return R.cel(R.v([-8,0, 8,0, 9,8, 6,14, -6,14, -9,8]), p.dark, p.dark_s, 2.2)


## Cuchilla de energon: sale de la mano y llega hasta y≈96.
static func _blade(skin: String, p: Dictionary, charge: float) -> String:
	var e: Color = p.energy
	var b := ""
	match skin:
		"g1":
			# Hoja recta con guarda blanca.
			b += R.cel(R.v([-5,44, 5,44, 5,86, 0,96, -5,86]), e, e.darkened(0.25), 2.0)
			b += R.flat(R.path(R.v([-2,46, 1,46, 1,84, -2,84])), "#ffffff", 0.55)
			b += R.cel(R.v([-11,40, 11,40, 9,46, -9,46]), p.second, p.second_s, 1.6)
		"prime":
			# Hoja curva que sale del antebrazo.
			b += R.cel(R.v([-5,20, 7,34, 13,62, 5,96, -3,66, -7,40]), e, e.darkened(0.3), 2.0)
			b += R.flat(R.path(R.v([0,36, 5,44, 8,62, 4,84, 0,62])), "#ffffff", 0.5)
		_:
			# Hoja de metal dentada, con el filo encendido.
			b += R.cel(R.v([-5,42, 6,42, 9,56, 4,62, 8,76, 0,96, -6,74, -3,60, -7,52]), p.joint, p.dark, 2.0)
			b += R.accent(R.v([6,42, 9,56, 4,62, 8,76, 0,96]), e, 2.6)
	var glow := ""
	if charge > 0.01:
		glow = R.circle(0, 70, 22.0 + 12.0 * charge, "url(#e_glow)", 0.0, 0.25 + 0.5 * charge)
	return glow + b


static func _armed(skin: String, p: Dictionary, charge: float) -> String:
	return _blade(skin, p, charge) + _forearm(skin, p) + R.joint(Vector2(0, 32), 0.0, _hand(p))


static func fist_arm(skin: String, p: Dictionary) -> String:
	return _armed(skin, p, 0.15)


static func gun(skin: String, p: Dictionary, charge: float) -> String:
	return _armed(skin, p, charge)

# ── Moto ──────────────────────────────────────────────────────────────────────

## Piezas comunes de la moto: basculante, motor y tubo de escape.
static func _bike_frame(engine: Color, engine_s: Color, metal: Color) -> String:
	var f := R.accent(R.v([98,194, 164,170]), metal, 7.0)
	f += R.cel(R.v([146,146, 212,144, 218,186, 192,194, 158,190]), engine, engine_s, 2.6)
	for y in [156, 166, 176]:
		f += R.accent(R.v([156,y, 208,y - 2]), engine_s.lightened(0.25), 1.8)
	f += R.circle(182, 180, 10.0, R.hex(metal), 2.2)
	return f


## Piezas por separado: la transformación las monta una a una.
## "over" va por delante de las ruedas (la horquilla sujeta la rueda delantera).
static func bike_parts(skin: String, pose: Dictionary) -> Dictionary:
	var p: Dictionary = SKINS[skin]
	var tread: float = pose.get("tread", 0.0)
	var q := {"low": "", "top": "", "wheels": "", "over": ""}
	match skin:
		"g1":
			# Carenado completo y redondeado, de ciencia ficción clásica: tapa media rueda.
			q.low += _bike_frame(p.dark, p.dark_s, p.joint)
			q.low += R.accent(R.v([150,186, 62,176]), p.second, 6.0)
			q.top += R.cel(R.v([50,132, 62,114, 104,108, 156,122, 170,150, 126,164, 80,160]), p.armor, p.armor_s)
			q.top += R.cel(R.v([96,124, 150,130, 158,146, 110,146]), p.second, p.second_s, 2.2)
			q.top += R.cel(R.v([150,142, 164,116, 216,106, 246,96, 276,116, 300,146, 288,172, 240,184, 196,170, 160,164]), p.armor, p.armor_s)
			q.top += C.window(R.v([224,112, 250,102, 270,120, 240,134]), p)
			q.top += R.cel(R.v([168,146, 240,140, 272,152, 240,172, 190,162]), p.second, p.second_s, 2.0)
			q.top += R.accent(R.v([180,152, 250,150]), p.accent, 2.6)
			q.top += C.autobot_insignia(Vector2(212, 124), 0.7, p.second)
			q.top += R.flat(R.path(R.v([286,136, 300,146, 288,152])), R.hex(p.eye))
			q.over += R.accent(R.v([262,194, 240,168]), p.joint, 7.0)
			q.wheels += C.wheel(98, 194, tread, p.second, 30.0) + C.wheel(262, 194, tread, p.second, 30.0)
		"prime":
			# Deportiva angulosa: colín en punta, depósito marcado y morro afilado.
			q.low += _bike_frame(p.dark, p.dark_s, p.joint)
			q.low += R.accent(R.v([160,184, 110,150]), p.joint, 6.0)
			q.top += R.cel(R.v([34,112, 96,118, 152,128, 158,146, 112,146]), p.armor, p.armor_s)
			q.top += R.accent(R.v([52,116, 110,128, 150,136]), p.second, 3.0)
			q.top += R.cel(R.v([104,126, 156,130, 160,140, 108,136]), p.dark, p.dark_s, 2.0)
			q.top += R.cel(R.v([152,146, 166,118, 210,108, 232,132, 214,152]), p.armor, p.armor_s)
			q.top += R.cel(R.v([208,108, 244,86, 262,102, 310,142, 276,168, 238,162, 228,132]), p.armor, p.armor_s)
			q.top += R.cel(R.v([226,108, 244,92, 258,104, 238,120]), p.glass, p.glass.darkened(0.3), 1.8)
			q.top += R.accent(R.v([170,134, 214,126, 300,144]), p.second, 3.4)
			q.top += R.flat(R.path(R.v([292,136, 310,142, 296,152])), R.hex(p.eye))
			q.over += R.accent(R.v([262,194, 236,150]), p.joint, 7.0)
			q.wheels += C.wheel(98, 194, tread, p.dark, 30.0) + C.wheel(262, 194, tread, p.dark, 30.0)
		_:
			# Superbike: chasis de celosía a la vista, colín fino y escapes bajo el asiento.
			q.low += _bike_frame(p.second, p.second_s, p.joint)
			for x in [156, 174, 192, 210]:
				q.low += R.accent(R.v([x,122, x + 16,146]), p.armor, 2.6)
				q.low += R.accent(R.v([x + 16,122, x,146]), p.armor, 2.6)
			q.low += R.cel(R.v([72,122, 122,126, 120,136, 74,134]), p.joint, p.dark, 2.2)
			q.top += R.cel(R.v([44,104, 100,112, 158,122, 158,132, 100,130]), p.armor, p.armor_s)
			q.top += R.cel(R.v([104,112, 158,118, 158,126, 108,122]), p.dark, p.dark_s, 1.8)
			q.top += R.cel(R.v([152,122, 168,100, 214,96, 232,122]), p.armor, p.armor_s)
			q.top += R.accent(R.v([166,112, 216,108]), p.accent, 2.4)
			q.top += R.cel(R.v([222,104, 250,84, 270,102, 300,136, 266,146, 236,134]), p.armor, p.armor_s)
			q.top += R.cel(R.v([238,106, 250,92, 264,104, 248,116]), p.glass, p.glass.darkened(0.3), 1.8)
			q.top += R.flat(R.path(R.v([282,122, 300,136, 286,140])), R.hex(p.eye))
			q.over += R.accent(R.v([262,194, 240,126]), p.joint, 7.0)
			q.wheels += C.wheel(98, 194, tread, p.joint, 30.0) + C.wheel(262, 194, tread, p.joint, 30.0)
	return q


static func vehicle(D, skin: String, pose: Dictionary = {}, k: float = 1.0) -> Image:
	return C.ground_vehicle(D, skin, pose, k, bike_parts(skin, pose), {"center_x": 176.0, "shadow_w": 116.0, "front": Vector2(306, 150)})


static func morph(D, skin: String, t: float, k: float = 1.0) -> Image:
	return C.fold_into_vehicle(D, skin, t, k, bike_parts(skin, {}), {"center_x": 176.0, "shadow_w": 116.0, "crouch": 34.0, "pivot_y": 164.0, "base_y": 194.0, "top_y": 124.0})
