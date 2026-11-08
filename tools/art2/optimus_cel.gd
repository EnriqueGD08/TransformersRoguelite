# optimus_cel.gd
# Optimus Prime en estilo cel. Corpulento y con el pecho de cabina de camión; lucha con hacha.
# Cada skin tiene su silueta y su camión:
#   G1: cuadrado, de dibujo clásico, ventanas grandes → camión de cabina plana.
#   Prime: heroico, cresta alta, tubos en la espalda → camión de líneas redondeadas.
#   Bay: muchas piezas y llamas azules y rojas → camión de morro largo con cromados.
# Solo define piezas: el esqueleto y las animaciones son comunes (cel_character, cel_anim).
# SRP: formas de Optimus. OCP: no toca el esqueleto común.

extends RefCounted

const R := preload("res://tools/art2/vector_rig.gd")
const C := preload("res://tools/art2/cel_character.gd")

const SKINS := {
	"g1": {"armor": Color("d9322d"), "armor_s": Color("9c1f20"), "second": Color("d5dae1"), "second_s": Color("9aa2ad"),
		"dark": Color("2b52ad"), "dark_s": Color("1c387c"), "joint": Color("7c828d"), "accent": Color("f2c230"),
		"eye": Color("7fe6ff"), "energy": Color("ffae3d"), "glass": Color("8fd8f0")},
	"prime": {"armor": Color("bf2b31"), "armor_s": Color("831a22"), "second": Color("b6bdc7"), "second_s": Color("7d8591"),
		"dark": Color("24427f"), "dark_s": Color("162b57"), "joint": Color("4f5561"), "accent": Color("e8edf2"),
		"eye": Color("6fd6ff"), "energy": Color("6fd6ff"), "glass": Color("5fb4dc")},
	"bay": {"armor": Color("284a9f"), "armor_s": Color("1a316e"), "second": Color("d02e25"), "second_s": Color("911b18"),
		"dark": Color("2a2d35"), "dark_s": Color("1b1d23"), "joint": Color("9aa2ad"), "accent": Color("ff8a25"),
		"eye": Color("7fd2ff"), "energy": Color("ff9a3c"), "glass": Color("7fb6d6")},
}

const THIGH := 44.0
const SHIN := 50.0
const HIP_Y := 122.0
const HIP_HALF := 13.0
const SHOULDER_X := 52.0
const SHOULDER_Y := -62.0
const NECK := Vector2(1, -76)
const NEAR_FOOT := Vector2(124, 212)
const FAR_FOOT := Vector2(178, 212)
const SHADOW_W := 76.0
const HALF_STRIDE := 31.0
const LIFT := 15.0
const WALK_CENTER := 152.0
const VEHICLE_RECOIL := 16.0
const VEHICLE_HOVER := 0.0

## El hachazo sube por encima de la cabeza: lienzo más alto, sin mover el centro.
const EXTRA_Y := 36


# ── Espalda ───────────────────────────────────────────────────────────────────

static func back(skin: String, p: Dictionary) -> String:
	if skin == "g1":
		return ""
	var b := ""
	# Tubos de escape del camión asomando por detrás de los hombros.
	for s in [1, -1]:
		var m: bool = s > 0
		b += R.cel(R.v([-40,-62, -30,-62, -30,-112, -40,-112], m), Color("c6ccd4"), Color("858d99"), 2.6)
		b += R.cel(R.v([-42,-112, -28,-112, -29,-122, -41,-122], m), p.joint, p.dark_s, 2.2)
	return b

# ── Cabeza ────────────────────────────────────────────────────────────────────

static func head(skin: String, p: Dictionary) -> String:
	var h := ""
	var blue: Color = p.dark if skin != "bay" else p.armor
	var blue_s: Color = p.dark_s if skin != "bay" else p.armor_s
	var face: Color = Color("cfd5dc")
	var face_s: Color = Color("939ba6")
	match skin:
		"g1":
			# Antenas, casco cuadrado con crestas laterales y máscara plateada.
			for s in [1, -1]:
				h += R.cel(R.v([s * 15,-14, s * 21,-14, s * 21,-40, s * 17,-40]), blue, blue_s, 2.2)
			h += R.cel(R.v([-15,4, -16,-22, -9,-31, 9,-31, 16,-22, 15,4, 8,4, 8,-15, -8,-15, -8,4]), blue, blue_s)
			h += R.cel(R.v([-3,-36, 3,-36, 4,-20, -4,-20]), blue, blue_s, 2.0)
			h += R.cel(R.v([-9,-16, 9,-16, 8,-7, -8,-7]), face, face_s, 2.0)
			h += R.flat(R.path(R.v([-8,-14, 8,-14, 8,-10, -8,-10])), R.hex(p.eye))
			h += R.cel(R.v([-8,-7, 8,-7, 6,5, -6,5]), face, face_s, 2.0)
			h += R.accent(R.v([-3,-5, -3,3]), face_s, 1.6)
			h += R.accent(R.v([3,-5, 3,3]), face_s, 1.6)
		"prime":
			# Cresta alta y aletas barridas hacia arriba.
			for s in [1, -1]:
				h += R.cel(R.v([s * 13,-10, s * 25,-44, s * 16,-34, s * 8,-22]), blue, blue_s, 2.2)
			h += R.cel(R.v([-14,4, -16,-20, -7,-30, -3,-44, 3,-44, 7,-30, 16,-20, 14,4, 8,6, 8,-14, -8,-14, -8,6]), blue, blue_s)
			h += R.cel(R.v([-9,-16, 9,-16, 8,-6, -8,-6]), Color("2c323c"), Color("1b1f26"), 1.8)
			h += R.flat(R.path(R.v([-8,-14, -1,-11, -1,-8, -8,-10])), R.hex(p.eye))
			h += R.flat(R.path(R.v([8,-14, 1,-11, 1,-8, 8,-10])), R.hex(p.eye))
			h += R.cel(R.v([-8,-6, 8,-6, 7,3, 0,9, -7,3]), face, face_s, 2.0)
			h += R.accent(R.v([0,-4, 0,6]), face_s, 1.6)
		_:
			# Casco de piezas pequeñas, en punta, con máscara rasgada.
			for s in [1, -1]:
				h += R.cel(R.v([s * 12,-6, s * 22,-16, s * 20,-36, s * 11,-24]), blue, blue_s, 2.2)
				h += R.accent(R.v([s * 15,-14, s * 18,-28]), p.second, 1.8)
			h += R.cel(R.v([-13,4, -15,-18, -6,-27, -3,-38, 3,-38, 6,-27, 15,-18, 13,4, 8,6, 8,-13, -8,-13, -8,6]), blue, blue_s)
			h += R.cel(R.v([-9,-15, 9,-15, 8,-6, -8,-6]), Color("2a2d35"), Color("1b1d23"), 1.8)
			h += R.flat(R.path(R.v([-8,-13, -2,-10, -2,-7, -8,-9])), R.hex(p.eye))
			h += R.flat(R.path(R.v([8,-13, 2,-10, 2,-7, 8,-9])), R.hex(p.eye))
			h += R.cel(R.v([-8,-6, 8,-6, 6,4, 2,8, -2,8, -6,4]), face, face_s, 1.8)
			for x in [-4, 0, 4]:
				h += R.accent(R.v([x,-3, x,5]), face_s, 1.3)
	return h

# ── Torso ─────────────────────────────────────────────────────────────────────

static func torso(skin: String, p: Dictionary) -> String:
	var t := ""
	match skin:
		"g1":
			# Pecho de camión cuadrado, ventanas grandes y parrilla plateada.
			t += R.cel(R.v([-46,-74, 46,-74, 49,-34, 30,-28, 26,2, -26,2, -30,-28, -49,-34]), p.armor, p.armor_s)
			t += C.window(R.v([-39,-68, -5,-68, -5,-40, -39,-40]), p)
			t += C.window(R.v([5,-68, 39,-68, 39,-40, 5,-40]), p)
			t += R.accent(R.v([0,-72, 0,-36]), p.armor_s, 3.0)
			t += R.cel(R.v([-27,-30, 27,-30, 24,-6, -24,-6]), p.second, p.second_s, 2.4)
			for k in 4:
				t += R.accent(R.v([-19,-25 + k * 5, 19,-25 + k * 5]), p.second_s, 1.8)
			t += R.cel(R.v([-24,-6, 24,-6, 25,2, -25,2]), p.dark, p.dark_s, 2.2)
			t += R.flat(R.path(R.v([-46,-35, -38,-37, -38,-31, -46,-29])), R.hex(p.accent))
			t += R.flat(R.path(R.v([46,-35, 38,-37, 38,-31, 46,-29])), R.hex(p.accent))
		"prime":
			# Más estrecho de cintura, ventanas inclinadas y abdomen de placas.
			t += R.cel(R.v([-48,-76, -30,-80, 30,-80, 48,-76, 44,-44, 22,-26, 18,2, -18,2, -22,-26, -44,-44]), p.armor, p.armor_s)
			t += C.window(R.v([-40,-71, -6,-71, -8,-46, -34,-46]), p)
			t += C.window(R.v([6,-71, 40,-71, 34,-46, 8,-46]), p)
			t += R.cel(R.v([-5,-78, 5,-78, 8,-40, 0,-32, -8,-40]), p.second, p.second_s, 2.2)
			for k in 3:
				t += R.cel(R.v([-17 + k,-29 + k * 10, 17 - k,-29 + k * 10, 15 - k,-21 + k * 10, -15 + k,-21 + k * 10]), p.second, p.second_s, 1.8)
			t += C.autobot_insignia(Vector2(0, -38), 0.55, p.dark)
		_:
			# Blindaje azul con llamas rojas, ventanas pequeñas y parrilla cromada.
			t += R.cel(R.v([-44,-72, -30,-80, -8,-76, 8,-76, 30,-80, 44,-72, 48,-46, 30,-34, 26,-16, 18,2, -18,2, -26,-16, -30,-34, -48,-46]), p.armor, p.armor_s)
			t += R.cel(R.v([-48,-46, -30,-34, -24,-42, -20,-30, -10,-44, -8,-28, 0,-40, 8,-28, 10,-44, 20,-30, 24,-42, 30,-34, 48,-46, 40,-62, 30,-50, 22,-60, 10,-50, 0,-60, -10,-50, -22,-60, -30,-50, -40,-62]), p.second, p.second_s, 2.0)
			t += C.window(R.v([-36,-74, -8,-72, -10,-58, -32,-60]), p)
			t += C.window(R.v([8,-72, 36,-74, 32,-60, 10,-58]), p)
			t += R.cel(R.v([-20,-30, 20,-30, 17,-4, -17,-4]), Color("c6ccd4"), Color("858d99"), 2.2)
			for k in 4:
				t += R.accent(R.v([-13 + k,-25 + k * 5, 13 - k,-25 + k * 5]), Color("5a616d"), 1.8)
	return t


static func pelvis(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-26,-6, 26,-6, 24,8, 8,16, -8,16, -24,8]), p.second, p.second_s) + R.cel(R.v([-7,-3, 7,-3, 6,12, -6,12]), p.dark, p.dark_s, 2.0)
		"prime":
			return R.cel(R.v([-22,-6, 22,-6, 26,5, 8,17, -8,17, -26,5]), p.dark, p.dark_s) + R.cel(R.v([-7,-2, 7,-2, 0,13]), p.second, p.second_s, 1.8)
		_:
			return R.cel(R.v([-22,-6, 22,-6, 28,5, 14,10, 7,17, -7,17, -14,10, -28,5]), p.dark, p.dark_s) + R.accent(R.v([-14,3, 0,10, 14,3]), p.second, 2.4)

# ── Piernas ───────────────────────────────────────────────────────────────────

static func thigh(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-14,-4, 14,-4, 15,36, 10,44, -10,44, -15,36]), p.second, p.second_s)
		"prime":
			return R.cel(R.v([-13,-4, 13,-4, 14,34, 9,44, -9,44, -14,34]), p.second, p.second_s) + R.cel(R.v([-8,6, 8,6, 7,28, -7,28]), p.dark, p.dark_s, 1.8)
		_:
			return R.cel(R.v([-13,-4, 12,-4, 15,14, 11,24, 14,34, 8,44, -9,44, -14,32, -11,20, -15,10]), p.joint, p.dark)


static func shin(skin: String, p: Dictionary) -> String:
	var s := ""
	match skin:
		"g1":
			# Pierna azul de camión, con la rueda asomando.
			s += R.cel(R.v([-17,0, 17,0, 20,34, 17,50, -17,50, -20,34]), p.dark, p.dark_s)
			s += R.cel(R.v([-13,-8, 13,-8, 13,8, 0,14, -13,8]), p.second, p.second_s, 2.2)
			s += R.circle(-13, 32, 9.0, "#20232a", 2.2)
			s += R.circle(-13, 32, 3.5, R.hex(p.second))
			s += R.accent(R.v([3,24, 14,24]), p.accent, 2.6)
		"prime":
			s += R.cel(R.v([-15,0, 15,0, 21,26, 15,50, -15,50, -20,26]), p.dark, p.dark_s)
			s += R.cel(R.v([-12,-10, 12,-5, 13,9, 0,16, -13,9]), p.armor, p.armor_s, 2.2)
			s += R.cel(R.v([-9,22, 11,22, 9,44, -8,44]), p.second, p.second_s, 1.8)
			s += R.accent(R.v([-5,30, 6,30]), p.dark_s, 2.0)
		_:
			s += R.cel(R.v([-15,0, 15,0, 21,14, 15,24, 20,36, 15,50, -15,50, -21,34, -15,22, -20,10]), p.armor, p.armor_s)
			s += R.cel(R.v([-20,10, -6,20, -12,28, 2,30, -6,42, -15,50, -21,34, -15,22]), p.second, p.second_s, 1.8)
			s += R.cel(R.v([-11,-8, 4,-11, 13,-3, 9,9, -3,14, -13,6]), p.joint, p.dark, 2.2)
			s += R.circle(11, 34, 7.0, "#20232a", 2.0)
			s += R.circle(11, 34, 3.0, R.hex(p.joint))
	return s


static func foot(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-16,-6, 15,-6, 32,6, 32,14, -18,14, -18,4]), p.dark, p.dark_s) + R.accent(R.v([14,9, 28,9]), p.second, 2.0)
		"prime":
			return R.cel(R.v([-15,-6, 14,-6, 34,8, 32,14, -17,14, -17,4]), p.second, p.second_s) + R.accent(R.v([-8,9, 20,9]), p.dark_s, 2.2)
		_:
			return R.cel(R.v([-15,-6, 15,-6, 22,3, 36,9, 32,14, 12,11, 6,14, -18,14, -17,4]), p.dark, p.dark_s) + R.accent(R.v([16,7, 30,10]), p.joint, 2.0)

# ── Brazos ────────────────────────────────────────────────────────────────────

static func shoulder(skin: String, p: Dictionary, s: float) -> String:
	var m: bool = s < 0.0
	match skin:
		"g1":
			var o := R.cel(R.v([-16,-14, 18,-14, 20,14, -16,16], m), p.armor, p.armor_s)
			return o + C.autobot_insignia(Vector2(2.0 * (-1.0 if m else 1.0), 1), 0.8, p.second)
		"prime":
			var o := R.cel(R.v([-14,16, -20,-4, -12,-20, 14,-20, 22,-6, 16,16], m), p.armor, p.armor_s)
			o += R.cel(R.v([-8,-13, 13,-13, 15,-4, -9,-4], m), p.second, p.second_s, 1.8)
			return o + C.autobot_insignia(Vector2(2.0 * (-1.0 if m else 1.0), 6), 0.6, p.accent)
		_:
			var o := R.cel(R.v([-14,14, -20,-4, -14,-10, -10,-20, 12,-20, 16,-10, 22,-4, 16,14], m), p.armor, p.armor_s)
			o += R.cel(R.v([-14,14, -8,2, -3,8, 2,-2, 8,8, 16,14], m), p.second, p.second_s, 1.8)
			return o + R.accent(R.v([-8,-13, 10,-13], m), p.joint, 2.2)


static func upper_arm(p: Dictionary) -> String:
	return R.cel(R.v([-9,-2, 9,-2, 9,30, -9,30]), p.joint, p.dark_s, 2.8)


static func _forearm(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-13,0, 13,0, 16,24, 13,38, -13,38, -16,24]), p.armor, p.armor_s) + R.accent(R.v([-8,12, 8,12]), p.second, 2.4)
		"prime":
			return R.cel(R.v([-12,0, 12,0, 17,20, 12,38, -12,38, -17,20]), p.armor, p.armor_s) + R.cel(R.v([-6,12, 6,12, 7,28, -7,28]), p.second, p.second_s, 1.6)
		_:
			var f := R.cel(R.v([-12,0, 12,0, 17,12, 12,22, 16,32, 12,38, -12,38, -16,28, -12,18, -17,8]), p.armor, p.armor_s)
			return f + R.cel(R.v([-17,8, -4,14, -8,24, 4,28, -12,38, -16,28, -12,18]), p.second, p.second_s, 1.6)


static func fist_arm(skin: String, p: Dictionary) -> String:
	var hand := R.cel(R.v([-11,0, 11,0, 13,10, 9,18, -9,18, -13,10]), p.dark if skin != "bay" else p.joint, p.dark_s, 2.4)
	return _forearm(skin, p) + R.joint(Vector2(0, 38), 0.0, hand)


## Hacha de energon. Es la "arma" del esqueleto; el mango sigue al antebrazo y el filo es
## doble, así que se lee bien en cualquier ángulo. Llega hasta y≈92.
static func gun(skin: String, p: Dictionary, charge: float) -> String:
	var a := ""
	var e: Color = p.energy
	match skin:
		"g1":
			# Hacha clásica: dos filos de energía muy abiertos.
			a += R.cel(R.v([-3,34, 3,34, 3,92, -3,92]), p.joint, p.dark_s, 2.0)
			a += R.cel(R.v([0,60, -30,48, -36,70, -30,92, 0,80]), e, e.darkened(0.25), 2.4)
			a += R.cel(R.v([0,60, 30,48, 36,70, 30,92, 0,80]), e, e.darkened(0.25), 2.4)
			a += R.flat(R.path(R.v([-4,63, -26,54, -30,70, -26,86, -4,77])), "#ffffff", 0.35)
			a += R.flat(R.path(R.v([4,63, 26,54, 30,70, 26,86, 4,77])), "#ffffff", 0.35)
		"prime":
			# Filo de energía angosto, con guarda metálica y punta.
			a += R.cel(R.v([-4,34, 4,34, 4,86, 0,94, -4,86]), p.second, p.second_s, 2.0)
			a += R.cel(R.v([3,50, 30,44, 36,62, 26,84, 3,74]), e, e.darkened(0.3), 2.2)
			a += R.cel(R.v([-3,50, -30,44, -36,62, -26,84, -3,74]), e, e.darkened(0.3), 2.2)
			a += R.flat(R.path(R.v([6,54, 25,50, 29,62, 22,76, 6,69])), "#ffffff", 0.4)
			a += R.flat(R.path(R.v([-6,54, -25,50, -29,62, -22,76, -6,69])), "#ffffff", 0.4)
			a += R.cel(R.v([-6,48, 6,48, 6,54, -6,54]), p.dark, p.dark_s, 1.6)
		_:
			# Hacha de metal, recortada en puntas, con el filo al rojo.
			a += R.cel(R.v([-4,34, 4,34, 4,90, -4,90]), Color("2a2d35"), Color("1b1d23"), 2.0)
			a += R.cel(R.v([2,52, 18,42, 38,52, 28,62, 40,74, 24,90, 2,78]), p.joint, p.dark, 2.4)
			a += R.cel(R.v([-2,52, -18,42, -38,52, -28,62, -40,74, -24,90, -2,78]), p.joint, p.dark, 2.4)
			a += R.accent(R.v([18,42, 38,52, 28,62, 40,74, 24,90]), e, 3.0)
			a += R.accent(R.v([-18,42, -38,52, -28,62, -40,74, -24,90]), e, 3.0)
	var out := ""
	if charge > 0.01:
		out += R.circle(0, 68, 30.0 + 14.0 * charge, "url(#e_glow)", 0.0, 0.35 + 0.4 * charge)
	var hand := R.joint(Vector2(0, 38), 0.0, R.cel(R.v([-11,0, 11,0, 13,10, 9,18, -9,18, -13,10]), p.dark if skin != "bay" else p.joint, p.dark_s, 2.4))
	return out + a + _forearm(skin, p) + hand

# ── Camión ────────────────────────────────────────────────────────────────────

## Piezas por separado: la transformación las monta una a una.
static func truck_parts(skin: String, pose: Dictionary) -> Dictionary:
	var p: Dictionary = SKINS[skin]
	var tread: float = pose.get("tread", 0.0)
	var chrome := Color("c6ccd4")
	var chrome_s := Color("858d99")
	var q := {"stacks": "", "rear": "", "cab": "", "wheels": ""}
	match skin:
		"g1":
			# Cabina plana: la cabina queda justo encima del eje delantero.
			q.stacks += R.cel(R.v([168,62, 178,62, 178,150, 168,150]), chrome, chrome_s, 2.4)
			q.rear += R.cel(R.v([26,160, 190,160, 190,186, 26,186]), p.dark, p.dark_s)
			q.rear += R.cel(R.v([30,146, 96,146, 96,162, 30,162]), p.dark_s, p.dark_s, 2.2)
			q.rear += R.cel(R.v([116,164, 172,164, 172,184, 116,184]), chrome, chrome_s, 2.2)
			q.rear += R.accent(R.v([124,174, 164,174]), chrome_s, 2.0)
			q.cab += R.cel(R.v([180,60, 300,60, 310,70, 312,172, 180,172]), p.armor, p.armor_s)
			q.cab += C.window(R.v([198,74, 244,74, 244,114, 198,114]), p)
			q.cab += C.window(R.v([250,74, 300,74, 304,114, 250,114]), p)
			q.cab += R.cel(R.v([290,122, 312,122, 312,162, 290,162]), chrome, chrome_s, 2.2)
			for k in 4:
				q.cab += R.accent(R.v([294,130 + k * 8, 309,130 + k * 8]), chrome_s, 1.8)
			q.cab += R.accent(R.v([184,122, 286,122]), p.dark, 4.0)
			q.cab += R.accent(R.v([184,130, 286,130]), Color.WHITE, 2.4)
			q.cab += C.autobot_insignia(Vector2(232, 150), 1.1, p.second)
			q.cab += R.cel(R.v([180,170, 322,170, 322,190, 180,190]), p.second, p.second_s, 2.6)
			q.cab += R.flat(R.path(R.v([304,174, 318,174, 318,180, 304,180])), R.hex(p.accent))
			q.wheels += C.wheel(50, 206, tread, chrome) + C.wheel(100, 206, tread, chrome) + C.wheel(262, 206, tread, chrome)
		"prime":
			# Líneas redondeadas: morro corto y caído, cabina inclinada.
			q.stacks += R.cel(R.v([152,48, 162,48, 162,150, 152,150]), chrome, chrome_s, 2.4)
			q.stacks += R.cel(R.v([136,58, 146,58, 146,150, 136,150]), chrome_s, chrome_s, 2.2)
			q.rear += R.cel(R.v([20,162, 170,162, 170,188, 20,188]), p.dark, p.dark_s)
			q.rear += R.cel(R.v([120,92, 174,84, 174,174, 120,174]), p.armor, p.armor_s)
			q.rear += R.accent(R.v([128,126, 170,126]), p.second, 3.0)
			q.cab += R.cel(R.v([172,84, 188,68, 238,66, 262,104, 306,120, 328,148, 328,182, 172,182]), p.armor, p.armor_s)
			q.cab += C.window(R.v([194,76, 234,74, 252,106, 194,106]), p)
			q.cab += R.cel(R.v([172,146, 328,148, 328,182, 172,182]), p.dark, p.dark_s, 2.4)
			q.cab += R.accent(R.v([180,116, 256,116, 300,132]), p.second, 2.8)
			q.cab += R.cel(R.v([312,136, 328,148, 328,172, 312,172]), chrome, chrome_s, 2.2)
			q.cab += R.cel(R.v([300,178, 334,178, 334,192, 300,192]), chrome, chrome_s, 2.4)
			q.cab += R.flat(R.path(R.v([316,140, 325,148, 318,150])), R.hex(p.eye))
			q.cab += C.autobot_insignia(Vector2(214, 130), 1.0, p.accent)
			q.wheels += C.wheel(44, 206, tread, chrome) + C.wheel(90, 206, tread, chrome) + C.wheel(268, 206, tread, chrome)
		_:
			# Morro largo con llamas, cromados y tubos altos.
			q.stacks += R.cel(R.v([136,30, 148,30, 148,152, 136,152]), chrome, chrome_s, 2.6)
			q.stacks += R.cel(R.v([136,24, 148,30, 136,30]), chrome, chrome_s, 1.8)
			q.rear += R.cel(R.v([14,164, 150,164, 150,188, 14,188]), p.dark, p.dark_s)
			q.rear += R.cel(R.v([70,84, 132,76, 136,172, 70,172]), p.armor, p.armor_s)
			q.rear += R.cel(R.v([70,172, 70,136, 84,150, 92,128, 106,152, 118,134, 136,172]), p.second, p.second_s, 2.0)
			q.cab += R.cel(R.v([134,76, 152,62, 204,62, 216,104, 318,108, 326,120, 326,178, 134,178]), p.armor, p.armor_s)
			q.cab += C.window(R.v([158,72, 200,72, 208,104, 158,104]), p)
			# Llamas pintadas en el morro y la puerta.
			q.cab += R.cel(R.v([134,178, 134,140, 158,152, 170,126, 196,150, 214,118, 244,146, 270,122, 262,142, 306,134, 268,154, 288,160, 240,178]), p.second, p.second_s, 2.0)
			q.cab += R.accent(R.v([170,140, 196,158, 214,134, 244,156, 270,138]), p.accent, 2.4)
			q.cab += R.cel(R.v([308,112, 326,120, 326,172, 308,172]), chrome, chrome_s, 2.2)
			for k in 5:
				q.cab += R.accent(R.v([311,122 + k * 9, 324,122 + k * 9]), chrome_s, 1.8)
			q.cab += R.cel(R.v([216,104, 318,108, 318,113, 216,110]), chrome, chrome_s, 1.6)
			q.cab += R.cel(R.v([168,178, 240,178, 240,192, 168,192]), chrome, chrome_s, 2.2)
			q.cab += R.cel(R.v([300,176, 338,176, 338,192, 300,192]), chrome, chrome_s, 2.4)
			q.wheels += C.wheel(36, 206, tread, chrome) + C.wheel(84, 206, tread, chrome) + C.wheel(278, 206, tread, chrome)
	return q


static func vehicle(D, skin: String, pose: Dictionary = {}, k: float = 1.0) -> Image:
	var r = C.canvas(D, skin)
	var p: Dictionary = SKINS[skin]
	var bob: float = pose.get("bob", 0.0)
	# El golpe del camión es una embestida: va hacia delante, no atrás.
	var lunge: float = pose.get("recoil", 0.0)
	r.add(R.ellipse(170.0 + lunge, 224, 150, 6, "#000000", 0.3))
	if pose.has("lines"):
		var t: float = pose.lines
		for i in 4:
			var y: float = 100.0 + i * 30.0
			var x: float = -46.0 + fposmod(t * 40.0 + i * 13.0, 40.0)
			r.add(R.faded(0.32, R.accent(R.v([x, y, x + 46.0, y]), Color.WHITE, 2.0)))
		# Polvo saliendo de la rueda de atrás.
		for i in 3:
			var u: float = fposmod(t + float(i) / 3.0, 1.0)
			r.add(R.circle(8.0 - u * 44.0, 220.0 - u * 16.0, 5.0 + u * 8.0, "#9aa0a8", 0.0, 0.32 * (1.0 - u)))
	var q: Dictionary = truck_parts(skin, pose)
	var body: String = q.stacks + q.rear + q.cab
	r.add(R.joint(Vector2(lunge, bob), 0.0, body))
	r.add(R.joint(Vector2(lunge, 0), 0.0, q.wheels))
	var flash: float = pose.get("flash", 0.0)
	if flash > 0.01:
		r.add(R.circle(330.0 + lunge, 140, 52.0 * flash, "url(#e_glow)", 0.0, 1.0))
		r.add(R.faded(flash, R.accent(R.v([330.0 + lunge, 96, 346.0 + lunge, 140, 330.0 + lunge, 186]), p.energy.lightened(0.3), 4.0)))
	return r.render_scaled(k)

# ── Transformación ────────────────────────────────────────────────────────────

## Fotograma de robot → camión (t de 0 a 1): el robot se agacha y se tumba hacia delante,
## el chasis y las ruedas aparecen debajo y la cabina se cierra por encima.
static func morph(D, skin: String, t: float, k: float = 1.0) -> Image:
	var p: Dictionary = SKINS[skin]
	var r = C.canvas(D, skin)
	var fold: float = C.smooth(t / 0.55)
	var base: float = C.smooth((t - 0.25) / 0.4)
	var cab: float = C.smooth((t - 0.45) / 0.45)
	r.add(R.ellipse(lerpf(150.0, 170.0, base), 224, lerpf(SHADOW_W, 150.0, base), lerpf(7.0, 6.0, base), "#000000", 0.3))
	var q: Dictionary = truck_parts(skin, {})
	if base > 0.0:
		r.add(R.scaled(Vector2(170, 206), lerpf(0.5, 1.0, base), base, q.wheels))
		r.add(R.scaled(Vector2(170, 186), lerpf(0.6, 1.0, base), base, q.rear))
	var robot_op: float = 1.0 - C.smooth((t - 0.58) / 0.22)
	if robot_op > 0.0:
		var figure: String = C.robot_svg(D, skin, {
			"no_shadow": true,
			"crouch": fold * 40.0,
			"near_foot": NEAR_FOOT.lerp(Vector2(140, 212), fold),
			"far_foot": FAR_FOOT.lerp(Vector2(162, 212), fold),
			"gun_sh": lerpf(-16.0, -6.0, fold),
			"gun_el": lerpf(-12.0, -2.0, fold),
			"fist_sh": lerpf(8.0, 3.0, fold),
			"fist_el": lerpf(8.0, 2.0, fold),
			"head": fold * -30.0,
			"charge": 0.2,
		})
		var rot: String = R.rotated(Vector2(150, 160), fold * 62.0, figure)
		r.add(R.faded(robot_op, R.joint(Vector2(fold * 32.0, 0), 0.0, rot)))
	if cab > 0.0:
		r.add(R.joint(Vector2(0, (1.0 - cab) * -24.0), 0.0, R.faded(C.smooth(cab * 2.0), R.scaled(Vector2(240, 180), lerpf(0.7, 1.0, cab), lerpf(0.5, 1.0, cab), q.stacks + q.cab))))
	C.energy_arcs(r, p, Vector2(170, 136), t)
	return r.render_scaled(k)
