# bumblebee_cel.gd
# Bumblebee en estilo cel. Es el más bajo del grupo: piernas cortas y cabeza grande.
# Pelea a puñetazos con los stingers de energon. Cada skin tiene su silueta y su coche:
#   G1: redondo y de dibujo clásico, capó en el pecho → escarabajo.
#   Prime: esbelto, negro y amarillo, puertas-ala → deportivo anguloso.
#   Bay: blindado, parrilla en el pecho, puertas y ruedas a la vista → Camaro con franjas.
# Solo define piezas: el esqueleto y las animaciones son comunes (cel_character, cel_anim).
# SRP: formas de Bumblebee. OCP: no toca el esqueleto común.

extends RefCounted

const R := preload("res://tools/art2/vector_rig.gd")
const C := preload("res://tools/art2/cel_character.gd")

const SKINS := {
	"g1": {"armor": Color("f6c81e"), "armor_s": Color("c4950e"), "second": Color("d5dae1"), "second_s": Color("9aa2ad"),
		"dark": Color("2c2e36"), "dark_s": Color("1b1c22"), "joint": Color("6b707a"), "accent": Color("d9322d"),
		"eye": Color("7fe6ff"), "energy": Color("ffe066"), "glass": Color("8fd8f0")},
	"prime": {"armor": Color("f0b81c"), "armor_s": Color("b4860f"), "second": Color("33363f"), "second_s": Color("20222a"),
		"dark": Color("24262d"), "dark_s": Color("15161b"), "joint": Color("565b66"), "accent": Color("ffe27a"),
		"eye": Color("5fc8ff"), "energy": Color("6fd6ff"), "glass": Color("3f5566")},
	"bay": {"armor": Color("f2c21a"), "armor_s": Color("b78b10"), "second": Color("2a2c33"), "second_s": Color("191a1f"),
		"dark": Color("2f323a"), "dark_s": Color("1c1e24"), "joint": Color("8a909a"), "accent": Color("ff8a25"),
		"eye": Color("6fc4ff"), "energy": Color("8fdcff"), "glass": Color("47606f")},
}

const THIGH := 38.0
const SHIN := 44.0
const HIP_Y := 134.0
const HIP_HALF := 11.0
const SHOULDER_X := 38.0
const SHOULDER_Y := -52.0
const NECK := Vector2(1, -62)
const NEAR_FOOT := Vector2(128, 212)
const FAR_FOOT := Vector2(172, 212)
const SHADOW_W := 56.0
const HALF_STRIDE := 28.0
const LIFT := 13.0
const WALK_CENTER := 151.0
const VEHICLE_RECOIL := 14.0
const VEHICLE_HOVER := 0.0

## Los puños quedan más cerca que la boca de un cañón: el fogonazo sale de ahí.
const FLASH_Y := 54.0

# ── Espalda ───────────────────────────────────────────────────────────────────

static func back(skin: String, p: Dictionary) -> String:
	var b := ""
	for s in [1, -1]:
		var m: bool = s > 0
		match skin:
			"g1":
				# Asoma el techo del escarabajo detrás de los hombros.
				b += R.cel(R.v([-16,-58, -30,-74, -44,-62, -32,-44], m), p.armor, p.armor_s, 2.6)
			"prime":
				# Puertas estrechas barridas hacia arriba.
				b += R.cel(R.v([-16,-54, -50,-92, -60,-80, -36,-40], m), p.armor, p.armor_s)
				b += R.cel(R.v([-22,-54, -46,-82, -50,-76, -34,-46], m), p.glass, p.glass.darkened(0.3), 1.8)
			_:
				# Puertas enteras del Camaro, abiertas como alas.
				b += R.cel(R.v([-14,-56, -62,-84, -70,-54, -34,-30], m), p.armor, p.armor_s)
				b += R.cel(R.v([-26,-58, -58,-76, -62,-60, -34,-46], m), p.glass, p.glass.darkened(0.3), 1.8)
				b += R.accent(R.v([-36,-36, -66,-54], m), p.second, 3.0)
	return b

# ── Cabeza ────────────────────────────────────────────────────────────────────

static func head(skin: String, p: Dictionary) -> String:
	var h := ""
	match skin:
		"g1":
			# Casco redondeado con cuernos cortos y cara clara.
			for s in [1, -1]:
				h += R.cel(R.v([s * 12,-22, s * 20,-40, s * 23,-38, s * 18,-18]), p.dark, p.dark_s, 2.2)
			h += R.cel(R.v([-16,2, -18,-14, -13,-27, -5,-32, 5,-32, 13,-27, 18,-14, 16,2, 9,6, 9,-13, -9,-13, -9,6]), p.armor, p.armor_s)
			h += R.cel(R.v([-10,-15, 10,-15, 10,0, 5,7, -5,7, -10,0]), p.second, p.second_s, 2.2)
			h += R.flat(R.path(R.v([-9,-12, 9,-12, 9,-7, -9,-7])), R.hex(p.eye))
			h += R.accent(R.v([-4,1, 4,1]), p.second_s, 1.8)
		"prime":
			# Máscara negra, dos ópticas azules y aletas hacia atrás.
			for s in [1, -1]:
				h += R.cel(R.v([s * 10,-16, s * 25,-36, s * 16,-12]), p.dark, p.dark_s, 2.2)
			h += R.cel(R.v([-14,0, -16,-16, -8,-27, 0,-34, 8,-27, 16,-16, 14,0, 8,6, 8,-12, -8,-12, -8,6]), p.armor, p.armor_s)
			h += R.cel(R.v([-10,-15, 10,-15, 9,0, 0,9, -9,0]), p.dark, p.dark_s, 2.2)
			h += R.circle(-5, -9, 3.6, R.hex(p.eye))
			h += R.circle(5, -9, 3.6, R.hex(p.eye))
			h += R.accent(R.v([-3,1, 0,4, 3,1]), p.joint, 1.6)
		_:
			# Casco de placas, antenas finas y boca metálica.
			for s in [1, -1]:
				h += R.cel(R.v([s * 13,-10, s * 24,-24, s * 18,-32, s * 11,-22]), p.armor, p.armor_s, 2.2)
				h += R.accent(R.v([s * 10,-26, s * 15,-42]), p.dark, 2.0)
			h += R.cel(R.v([-14,2, -16,-14, -9,-26, -3,-30, 3,-30, 9,-26, 16,-14, 14,2, 8,6, 8,-12, -8,-12, -8,6]), p.armor, p.armor_s)
			h += R.cel(R.v([-10,-14, 10,-14, 9,-5, -9,-5]), p.dark, p.dark_s, 1.8)
			h += R.flat(R.path(R.v([-8,-12, -2,-9, -2,-7, -8,-8])), R.hex(p.eye))
			h += R.flat(R.path(R.v([8,-12, 2,-9, 2,-7, 8,-8])), R.hex(p.eye))
			h += R.cel(R.v([-8,-5, 8,-5, 6,4, 2,8, -2,8, -6,4]), p.joint, p.dark, 1.8)
			for x in [-3, 3]:
				h += R.accent(R.v([x,-2, x,5]), p.dark, 1.3)
	return h

# ── Torso ─────────────────────────────────────────────────────────────────────

static func _headlight(c: Vector2, p: Dictionary) -> String:
	return R.circle(c.x, c.y, 7.0, R.hex(p.second), 2.2) + R.circle(c.x, c.y, 4.0, R.hex(p.glass)) + R.circle(c.x - 1.5, c.y - 1.5, 1.4, "#ffffff")


static func torso(skin: String, p: Dictionary) -> String:
	var t := ""
	match skin:
		"g1":
			# Pecho redondo: el capó del escarabajo con sus dos faros.
			t += R.cel(R.v([-36,-58, -20,-64, 20,-64, 36,-58, 40,-38, 30,-24, 20,-18, 18,2, -18,2, -20,-18, -30,-24, -40,-38]), p.armor, p.armor_s)
			t += _headlight(Vector2(-22, -44), p) + _headlight(Vector2(22, -44), p)
			t += R.cel(R.v([-10,-60, 10,-60, 12,-30, 0,-24, -12,-30]), p.armor.lightened(0.15), p.armor_s, 2.0)
			t += C.autobot_insignia(Vector2(0, -44), 0.7, p.accent)
			t += R.cel(R.v([-18,-20, 18,-20, 16,2, -16,2]), p.dark, p.dark_s, 2.2)
			t += R.accent(R.v([-10,-10, 10,-10]), p.joint, 2.0)
		"prime":
			# En V marcada, con dos franjas negras y cintura muy fina.
			t += R.cel(R.v([-40,-58, -22,-66, 22,-66, 40,-58, 30,-34, 13,-18, 11,2, -11,2, -13,-18, -30,-34]), p.armor, p.armor_s)
			t += R.cel(R.v([-14,-65, -5,-65, -4,-30, -10,-26]), p.dark, p.dark_s, 1.6)
			t += R.cel(R.v([14,-65, 5,-65, 4,-30, 10,-26]), p.dark, p.dark_s, 1.6)
			t += R.cel(R.v([-34,-56, -18,-56, -16,-40, -24,-36]), p.glass, p.glass.darkened(0.3), 1.8)
			t += R.cel(R.v([34,-56, 18,-56, 16,-40, 24,-36]), p.glass, p.glass.darkened(0.3), 1.8)
			for k in 2:
				t += R.cel(R.v([-12 + k,-17 + k * 9, 12 - k,-17 + k * 9, 11 - k,-11 + k * 9, -11 + k,-11 + k * 9]), p.dark, p.dark_s, 1.6)
		_:
			# Frontal del Camaro: parabrisas arriba, faros rasgados y parrilla negra.
			t += R.cel(R.v([-36,-60, -22,-68, 22,-68, 36,-60, 42,-36, 28,-22, 18,-16, 15,2, -15,2, -18,-16, -28,-22, -42,-36]), p.armor, p.armor_s)
			t += R.cel(R.v([-20,-65, 20,-65, 25,-52, -25,-52]), p.glass, p.glass.darkened(0.3), 1.8)
			t += R.cel(R.v([-34,-46, -6,-46, -6,-30, -28,-30]), p.second, p.second_s, 2.0)
			t += R.cel(R.v([34,-46, 6,-46, 6,-30, 28,-30]), p.second, p.second_s, 2.0)
			t += R.flat(R.path(R.v([-32,-44, -20,-44, -22,-39, -30,-39])), R.hex(p.eye))
			t += R.flat(R.path(R.v([32,-44, 20,-44, 22,-39, 30,-39])), R.hex(p.eye))
			t += R.cel(R.v([-5,-52, 5,-52, 5,-24, -5,-24]), p.second, p.second_s, 1.6)
			t += R.cel(R.v([-14,-16, 14,-16, 12,2, -12,2]), p.dark, p.dark_s, 2.0)
			t += R.accent(R.v([-8,-8, 8,-8]), p.joint, 1.8)
	return t


static func pelvis(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-20,-6, 20,-6, 18,7, 6,13, -6,13, -18,7]), p.dark, p.dark_s) + R.cel(R.v([-5,-3, 5,-3, 4,9, -4,9]), p.armor, p.armor_s, 1.8)
		"prime":
			return R.cel(R.v([-16,-6, 16,-6, 19,4, 5,14, -5,14, -19,4]), p.dark, p.dark_s) + R.cel(R.v([-5,-3, 5,-3, 0,10]), p.armor, p.armor_s, 1.6)
		_:
			return R.cel(R.v([-17,-6, 17,-6, 22,4, 11,8, 5,14, -5,14, -11,8, -22,4]), p.dark, p.dark_s) + R.accent(R.v([-9,1, 9,1]), p.armor, 2.2)

# ── Piernas ───────────────────────────────────────────────────────────────────

static func thigh(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-12,-4, 12,-4, 13,28, 8,38, -8,38, -13,28]), p.dark, p.dark_s)
		"prime":
			return R.cel(R.v([-10,-4, 10,-4, 11,28, 6,38, -6,38, -11,28]), p.dark, p.dark_s) + R.cel(R.v([-9,2, -2,0, -3,24, -9,22]), p.armor, p.armor_s, 1.6)
		_:
			return R.cel(R.v([-11,-4, 10,-4, 13,12, 9,20, 12,28, 6,38, -7,38, -12,26, -9,16, -13,8]), p.joint, p.dark)


static func shin(skin: String, p: Dictionary) -> String:
	var s := ""
	match skin:
		"g1":
			# Espinillas gruesas y redondas.
			s += R.cel(R.v([-14,0, 14,0, 19,14, 18,34, 13,44, -13,44, -18,34, -19,14]), p.armor, p.armor_s)
			s += R.cel(R.v([-11,-7, 11,-7, 11,6, 0,11, -11,6]), p.dark, p.dark_s, 2.0)
			s += R.accent(R.v([-8,24, 8,24]), p.dark, 2.4)
		"prime":
			s += R.cel(R.v([-10,0, 11,0, 17,20, 11,44, -10,44, -15,20]), p.armor, p.armor_s)
			s += R.cel(R.v([-9,-10, 10,-4, 11,7, 0,12, -10,6]), p.dark, p.dark_s, 2.0)
			s += R.cel(R.v([-3,14, 5,14, 4,38, -2,38]), p.dark, p.dark_s, 1.4)
		_:
			s += R.cel(R.v([-12,0, 12,0, 18,12, 13,22, 17,32, 12,44, -12,44, -18,30, -13,20, -18,10]), p.armor, p.armor_s)
			s += R.cel(R.v([-10,-7, 3,-10, 11,-3, 8,7, -3,12, -11,5]), p.joint, p.dark, 2.0)
			s += R.circle(-11, 30, 8.0, "#20232a", 2.0) + R.circle(-11, 30, 3.5, R.hex(p.joint))
			s += R.accent(R.v([2,18, 10,18]), p.second, 2.6)
	return s


static func foot(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-14,-6, 13,-6, 28,6, 28,14, -16,14, -16,4]), p.armor, p.armor_s) + R.accent(R.v([-8,10, 22,10]), p.dark, 2.0)
		"prime":
			return R.cel(R.v([-10,-6, 11,-6, 30,10, 26,14, -14,14, -13,3]), p.dark, p.dark_s)
		_:
			return R.cel(R.v([-12,-6, 12,-6, 18,3, 30,9, 26,14, 8,11, 3,14, -16,14, -14,4]), p.dark, p.dark_s) + R.accent(R.v([12,6, 24,9]), p.armor, 2.0)

# ── Brazos ────────────────────────────────────────────────────────────────────

static func shoulder(skin: String, p: Dictionary, s: float) -> String:
	var m: bool = s < 0.0
	match skin:
		"g1":
			return R.cel(R.v([-12,-11, 13,-11, 15,10, 9,14, -9,14, -13,8], m), p.armor, p.armor_s) + R.accent(R.v([-7,3, 8,3], m), p.dark, 2.2)
		"prime":
			return R.cel(R.v([-10,12, -15,-3, -9,-16, 14,-13, 16,3, 10,12], m), p.armor, p.armor_s) + R.accent(R.v([-7,-9, 11,-7], m), p.dark, 2.6)
		_:
			# Hombro con rueda a la vista.
			var o := R.cel(R.v([-11,12, -16,-5, -8,-15, 12,-15, 16,-3, 12,12], m), p.armor, p.armor_s)
			return o + R.circle(2.0 * (-1.0 if m else 1.0), 0, 9.0, "#20232a", 2.0) + R.circle(2.0 * (-1.0 if m else 1.0), 0, 4.0, R.hex(p.joint))


static func upper_arm(p: Dictionary) -> String:
	return R.cel(R.v([-7,-2, 7,-2, 7,30, -7,30]), p.dark, p.dark_s, 2.6)


## Antebrazo con su stinger; glow es la energía de los nudillos (0 a 1).
static func _stinger_arm(skin: String, p: Dictionary, glow: float) -> String:
	var f := ""
	var hand: Color = p.dark
	match skin:
		"g1":
			f += R.cel(R.v([-10,0, 10,0, 13,18, 11,32, -11,32, -13,18]), p.armor, p.armor_s)
			f += R.accent(R.v([-6,10, 6,10]), p.dark, 2.2)
		"prime":
			f += R.cel(R.v([-8,0, 8,0, 13,16, 9,32, -9,32, -13,16]), p.armor, p.armor_s)
			# Cuchilla retráctil a lo largo del antebrazo.
			f += R.cel(R.v([8,4, 19,14, 17,46, 11,32]), p.energy, p.energy.darkened(0.3), 1.8)
		_:
			f += R.cel(R.v([-9,0, 9,0, 14,10, 10,18, 13,26, 9,32, -9,32, -13,24, -10,16, -14,8]), p.armor, p.armor_s)
			# Cañón corto sobre el brazo.
			f += R.cel(R.v([9,4, 18,4, 18,38, 9,38]), p.dark, p.dark_s, 1.8)
			f += R.accent(R.v([13,12, 13,32]), p.energy, 2.0)
	var fist := R.cel(R.v([-10,0, 10,0, 12,9, 9,17, -9,17, -12,9]), hand, p.dark_s, 2.4)
	var knuckles := R.cel(R.v([-8,12, 8,12, 7,18, -7,18]), p.energy, p.energy.darkened(0.3), 1.4)
	var out := ""
	if glow > 0.01:
		out += R.joint(Vector2(0, 32), 0.0, R.circle(0, 16, 16.0 + 12.0 * glow, "url(#e_glow)", 0.0, 0.35 + 0.5 * glow))
	return out + f + R.joint(Vector2(0, 32), 0.0, fist + knuckles)


static func fist_arm(skin: String, p: Dictionary) -> String:
	return _stinger_arm(skin, p, 0.0)


static func gun(skin: String, p: Dictionary, charge: float) -> String:
	return _stinger_arm(skin, p, charge)

# ── Coche ─────────────────────────────────────────────────────────────────────

## Paso de rueda redondeado (el hueco oscuro de la carrocería).
static func _arch(cx: float, cy: float, r: float, col: String) -> String:
	var pts := PackedVector2Array()
	for i in 9:
		var ang: float = PI + float(i) / 8.0 * PI
		pts.append(Vector2(cx + cos(ang) * r, cy + sin(ang) * r))
	return R.flat(R.path(pts), col)


## Piezas por separado: la transformación las monta una a una.
static func car_parts(skin: String, pose: Dictionary) -> Dictionary:
	var p: Dictionary = SKINS[skin]
	var tread: float = pose.get("tread", 0.0)
	var chrome := Color("c6ccd4")
	var chrome_s := Color("858d99")
	var arch := "#191a1f"
	var q := {"low": "", "top": "", "wheels": ""}
	match skin:
		"g1":
			# Escarabajo: una sola curva de atrás adelante, aletas sueltas y estribo.
			q.low += R.cel(R.v([40,190, 40,166, 58,146, 118,132, 232,132, 286,142, 308,160, 310,190]), p.armor, p.armor_s)
			q.low += R.cel(R.v([34,190, 42,162, 74,152, 116,168, 126,190]), p.armor, p.armor_s, 2.4)
			q.low += R.cel(R.v([192,190, 202,166, 240,150, 282,156, 306,172, 312,190]), p.armor, p.armor_s, 2.4)
			q.low += R.cel(R.v([116,184, 196,184, 196,194, 116,194]), chrome, chrome_s, 2.0)
			q.low += R.cel(R.v([30,184, 50,184, 50,194, 30,194]), chrome, chrome_s, 2.0)
			q.low += R.cel(R.v([300,182, 322,182, 322,194, 300,194]), chrome, chrome_s, 2.0)
			q.low += C.autobot_insignia(Vector2(158, 158), 1.0, p.accent)
			q.low += R.accent(R.v([124,136, 124,184]), p.armor_s, 2.0)
			q.low += R.accent(R.v([194,136, 194,184]), p.armor_s, 2.0)
			q.low += R.circle(292, 154, 9.0, R.hex(chrome), 2.2) + R.circle(292, 154, 5.0, R.hex(p.glass))
			q.top += R.cel(R.v([60,146, 84,110, 116,84, 152,74, 188,78, 216,100, 240,134, 60,146]), p.armor, p.armor_s)
			q.top += C.window(R.v([96,132, 112,100, 150,88, 152,132]), p)
			q.top += C.window(R.v([160,88, 188,92, 212,132, 160,132]), p)
			q.wheels += C.wheel(82, 204, tread, chrome, 20.0) + C.wheel(250, 204, tread, chrome, 20.0)
		"prime":
			# Deportivo anguloso: morro en cuña, cintura alta, franjas negras por capó y techo.
			q.low += R.cel(R.v([24,176, 24,150, 34,130, 96,122, 150,124, 246,126, 312,136, 340,158, 342,174, 328,186, 40,186]), p.armor, p.armor_s)
			q.low += _arch(92, 204, 27.0, arch) + _arch(272, 204, 27.0, arch)
			q.low += R.cel(R.v([122,178, 240,178, 234,186, 128,186]), p.dark, p.dark_s, 1.8)
			q.low += R.accent(R.v([38,152, 110,146, 180,150, 250,150, 322,156]), p.armor_s, 2.4)
			q.low += R.cel(R.v([246,126, 312,136, 316,142, 250,133]), p.dark, p.dark_s, 1.4)
			q.low += R.cel(R.v([318,144, 340,158, 342,172, 326,170]), p.dark, p.dark_s, 2.0)
			q.low += R.flat(R.path(R.v([300,140, 322,150, 304,150])), R.hex(p.eye))
			q.low += R.cel(R.v([250,120, 280,124, 282,130, 252,128]), p.dark, p.dark_s, 1.8)
			q.low += R.cel(R.v([24,124, 56,122, 54,130, 34,132, 24,136]), p.dark, p.dark_s, 2.0)
			q.top += R.cel(R.v([86,128, 136,96, 204,94, 256,130]), p.armor, p.armor_s)
			q.top += C.window(R.v([118,124, 142,104, 170,102, 170,124]), p)
			q.top += C.window(R.v([178,102, 202,102, 230,124, 178,124]), p)
			q.top += R.cel(R.v([136,96, 204,94, 203,100, 138,102]), p.dark, p.dark_s, 1.4)
			q.wheels += C.wheel(92, 204, tread, p.joint, 21.0) + C.wheel(272, 204, tread, p.joint, 21.0)
		_:
			# Camaro: largo de capó, cristales muy estrechos, caderas marcadas y dos franjas negras.
			q.low += R.cel(R.v([20,178, 20,146, 30,128, 88,120, 110,126, 240,128, 306,132, 340,150, 346,170, 334,188, 36,188]), p.armor, p.armor_s)
			q.low += _arch(84, 202, 30.0, arch) + _arch(278, 202, 30.0, arch)
			q.low += R.cel(R.v([118,178, 246,178, 240,188, 124,188]), p.dark, p.dark_s, 1.8)
			# Pliegue de la carrocería y toma de aire lateral.
			q.low += R.accent(R.v([30,150, 88,140, 140,146, 240,146, 310,150]), p.armor_s, 2.6)
			q.low += R.cel(R.v([128,154, 176,150, 170,166, 134,168]), p.second, p.second_s, 1.6)
			# Franjas negras gemelas sobre el capó y la zaga.
			q.low += R.cel(R.v([240,128, 306,132, 322,139, 244,135]), p.second, p.second_s, 1.4)
			q.low += R.cel(R.v([30,128, 88,120, 92,127, 34,134]), p.second, p.second_s, 1.4)
			# Morro: faro rasgado, parrilla y labio inferior.
			q.low += R.cel(R.v([322,142, 340,150, 346,170, 326,168]), p.second, p.second_s, 2.0)
			q.low += R.flat(R.path(R.v([300,138, 326,146, 306,148])), R.hex(p.eye))
			q.low += R.cel(R.v([318,180, 346,178, 344,190, 322,190]), p.second, p.second_s, 1.8)
			q.low += R.cel(R.v([18,122, 56,118, 54,126, 30,130, 18,134]), p.second, p.second_s, 2.0)
			q.top += R.cel(R.v([92,130, 136,102, 200,100, 250,132]), p.armor, p.armor_s)
			q.top += C.window(R.v([122,126, 142,110, 170,108, 170,126]), p)
			q.top += C.window(R.v([178,108, 198,108, 224,126, 178,126]), p)
			q.top += R.cel(R.v([136,102, 200,100, 199,106, 138,108]), p.second, p.second_s, 1.4)
			q.wheels += C.wheel(84, 202, tread, chrome, 24.0) + C.wheel(278, 202, tread, chrome, 24.0)
	return q


static func vehicle(D, skin: String, pose: Dictionary = {}, k: float = 1.0) -> Image:
	return C.ground_vehicle(D, skin, pose, k, car_parts(skin, pose), {"center_x": 180.0, "shadow_w": 150.0, "front": Vector2(330, 160)})


static func morph(D, skin: String, t: float, k: float = 1.0) -> Image:
	return C.fold_into_vehicle(D, skin, t, k, car_parts(skin, {}), {"center_x": 180.0, "shadow_w": 150.0, "crouch": 26.0, "pivot_y": 170.0, "base_y": 204.0, "top_y": 132.0})
