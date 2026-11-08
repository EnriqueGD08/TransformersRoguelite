# starscream_cel.gd
# Starscream en estilo cel. Más esbelto que Megatron: alas a la espalda, piernas largas.
# Cada skin tiene su silueta y su avión:
#   G1: anguloso, alas en V, tomas de aire en los hombros, cabina ámbar → F-15 de dos derivas.
#   Prime: muy delgado, garras largas, alas altas y finas, plata y carmesí → jet afilado.
#   Bay: plumas-cuchilla, cabeza de ave, gris metálico → F-22 facetado.
# Solo define piezas: el esqueleto y las animaciones son comunes (cel_character, cel_anim).

extends RefCounted

const R := preload("res://tools/art2/vector_rig.gd")
const C := preload("res://tools/art2/cel_character.gd")

const SKINS := {
	"g1": {"armor": Color("dde2e8"), "armor_s": Color("a8b1bc"), "second": Color("cc352f"), "second_s": Color("962420"),
		"dark": Color("2f4f93"), "dark_s": Color("20376b"), "joint": Color("6a6f79"), "accent": Color("f0b429"),
		"eye": Color("ff3b30"), "energy": Color("9be8ff")},
	"prime": {"armor": Color("949ca8"), "armor_s": Color("686f7b"), "second": Color("97202f"), "second_s": Color("6b1520"),
		"dark": Color("2d2f37"), "dark_s": Color("1c1e24"), "joint": Color("484c56"), "accent": Color("e0354e"),
		"eye": Color("ff2a3a"), "energy": Color("ff6074")},
	"bay": {"armor": Color("8f96a0"), "armor_s": Color("626871"), "second": Color("565c66"), "second_s": Color("3c4149"),
		"dark": Color("2c2f35"), "dark_s": Color("1d1f24"), "joint": Color("444851"), "accent": Color("74bcd9"),
		"eye": Color("ff5a2a"), "energy": Color("8fd6ff")},
}

const THIGH := 46.0
const SHIN := 52.0
const HIP_Y := 118.0
const HIP_HALF := 10.0
const SHOULDER_X := 42.0
const SHOULDER_Y := -62.0
const NECK := Vector2(1, -74)
const NEAR_FOOT := Vector2(130, 212)
const FAR_FOOT := Vector2(172, 212)
const SHADOW_W := 62.0
const HALF_STRIDE := 33.0
const LIFT := 16.0
const WALK_CENTER := 151.0
const VEHICLE_RECOIL := 9.0
const VEHICLE_HOVER := 3.0


static func _insignia(c: Vector2, k: float, col: Color) -> String:
	var pts := R.v([-8,-8, -4,-8, -2,-4, 2,-4, 4,-8, 8,-8, 6,2, 3,3, 2,8, 0,10, -2,8, -3,3, -6,2])
	var out := PackedVector2Array()
	for q in pts:
		out.append(c + q * k)
	return R.shape(R.path(out), R.hex(col), 1.4)


static func _mirror(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in pts:
		out.append(Vector2(-q.x, q.y))
	return out

# ── Alas a la espalda ─────────────────────────────────────────────────────────

static func back(skin: String, p: Dictionary) -> String:
	var b := ""
	for s in [1, -1]:
		var m: bool = s > 0
		match skin:
			"g1":
				# Alas anchas en V con punta roja y deriva.
				b += R.cel(R.v([-20,-60, -82,-98, -92,-72, -30,-30], m), p.armor, p.armor_s)
				b += R.cel(R.v([-82,-98, -92,-72, -76,-68, -66,-88], m), p.second, p.second_s, 2.2)
				b += R.accent(R.v([-34,-52, -70,-76], m), p.dark, 2.4)
				b += R.cel(R.v([-20,-68, -30,-112, -14,-104, -10,-70], m), p.armor, p.armor_s, 2.4)
				b += R.cel(R.v([-30,-112, -14,-104, -15,-94, -28,-100], m), p.second, p.second_s, 2.0)
			"prime":
				# Alas altas, muy finas y barridas hacia arriba.
				b += R.cel(R.v([-18,-62, -52,-122, -64,-114, -46,-66, -24,-42], m), p.armor, p.armor_s)
				b += R.accent(R.v([-26,-52, -54,-108], m), p.accent, 2.6)
				b += R.cel(R.v([-46,-66, -70,-58, -58,-46, -26,-40], m), p.second, p.second_s, 2.2)
			_:
				# Plumas-cuchilla, irregulares.
				b += R.cel(R.v([-18,-58, -68,-108, -62,-74, -26,-46], m), p.armor, p.armor_s, 2.4)
				b += R.cel(R.v([-20,-50, -88,-80, -66,-58, -28,-38], m), p.second, p.second_s, 2.4)
				b += R.cel(R.v([-22,-40, -78,-44, -58,-34, -24,-28], m), p.armor, p.armor_s, 2.2)
				b += R.accent(R.v([-30,-56, -58,-84], m), p.accent, 1.8)
	return b

# ── Cabeza ────────────────────────────────────────────────────────────────────

static func head(skin: String, p: Dictionary) -> String:
	var h := ""
	match skin:
		"g1":
			h += R.cel(R.v([-15,3, -17,-20, -12,-33, 12,-33, 17,-20, 15,3, 9,3, 9,-14, -9,-14, -9,3]), p.dark, p.dark_s)
			h += R.cel(R.v([-3,-40, 3,-40, 5,-14, -5,-14]), p.second, p.second_s, 2.2)
			h += R.cel(R.v([-10,-15, 10,-15, 8,2, 3,7, -3,7, -8,2]), p.armor, p.armor_s, 2.4)
			h += R.flat(R.path(R.v([-8,-11, -2,-8, -2,-5, -8,-7])), R.hex(p.eye))
			h += R.flat(R.path(R.v([8,-11, 2,-8, 2,-5, 8,-7])), R.hex(p.eye))
			h += R.accent(R.v([-4,1, 4,1]), p.joint, 1.8)
		"prime":
			# Cara larga, barbilla en punta y corona barrida hacia atrás.
			h += R.cel(R.v([-11,-5, -14,-22, -22,-42, -9,-31, 0,-38, 9,-31, 22,-42, 14,-22, 11,-5, 6,7, 0,15, -6,7]), p.armor, p.armor_s)
			h += R.cel(R.v([-8,-21, 8,-21, 7,-6, 3,5, 0,9, -3,5, -7,-6]), p.dark, p.dark_s, 2.2)
			h += R.flat(R.path(R.v([-7,-17, -1,-13, -2,-10, -7,-13])), R.hex(p.eye))
			h += R.flat(R.path(R.v([7,-17, 1,-13, 2,-10, 7,-13])), R.hex(p.eye))
			h += R.accent(R.v([-4,-2, 0,0, 5,-4]), p.armor, 1.6)
		_:
			# Cabeza de ave: placas en punta y pico metálico.
			h += R.cel(R.v([-12,4, -15,-12, -24,-28, -10,-24, -7,-38, 0,-29, 7,-38, 10,-24, 24,-28, 15,-12, 12,4, 0,16]), p.armor, p.armor_s)
			h += R.cel(R.v([-9,-19, 9,-19, 8,-4, 0,8, -8,-4]), p.dark, p.dark_s, 2.2)
			h += R.flat(R.path(R.v([-8,-15, -2,-11, -3,-8, -8,-11])), R.hex(p.eye))
			h += R.flat(R.path(R.v([8,-15, 2,-11, 3,-8, 8,-11])), R.hex(p.eye))
			h += R.accent(R.v([-4,-3, 0,3, 4,-3]), p.armor_s, 1.6)
	return h

# ── Torso ─────────────────────────────────────────────────────────────────────

static func torso(skin: String, p: Dictionary) -> String:
	var t := ""
	match skin:
		"g1":
			t += R.cel(R.v([-35,-72, 35,-72, 38,-50, 22,-24, 14,2, -14,2, -22,-24, -38,-50]), p.armor, p.armor_s)
			# Morro del avión en el pecho: franja roja y cabina ámbar.
			t += R.cel(R.v([-13,-70, 13,-70, 16,-34, 0,-22, -16,-34]), p.second, p.second_s, 2.4)
			t += R.cel(R.v([-8,-64, 8,-64, 10,-44, -10,-44]), p.accent, p.accent.darkened(0.3), 2.0)
			t += R.flat(R.path(R.v([-5,-61, -1,-61, -5,-47, -8,-47])), "#ffffff", 0.55)
			t += _insignia(Vector2(0, -33), 0.72, p.armor)
			for s in [-1, 1]:
				for k in 3:
					t += R.accent(R.v([s * 19,-64 + k * 6, s * 31,-64 + k * 6]), p.dark, 2.0)
			t += R.cel(R.v([-13,-20, 13,-20, 11,2, -11,2]), p.dark, p.dark_s, 2.2)
			t += R.accent(R.v([-8,-11, 8,-11]), p.armor, 1.8)
		"prime":
			t += R.cel(R.v([-40,-72, -24,-78, 24,-78, 40,-72, 28,-44, 12,-18, 9,2, -9,2, -12,-18, -28,-44]), p.armor, p.armor_s)
			t += R.cel(R.v([-11,-74, 11,-74, 15,-46, 0,-28, -15,-46]), p.dark, p.dark_s, 2.2)
			t += R.cel(R.v([-6,-69, 6,-69, 8,-50, 0,-40, -8,-50]), p.second, p.second_s, 1.8)
			t += R.accent(R.v([-26,-60, -15,-48, -18,-38]), p.accent, 2.6)
			t += R.accent(R.v([26,-60, 15,-48, 18,-38]), p.accent, 2.6)
			for k in 3:
				t += R.cel(R.v([-10 + k,-20 + k * 7, 10 - k,-20 + k * 7, 9 - k,-15 + k * 7, -9 + k,-15 + k * 7]), p.dark, p.dark_s, 1.6)
		_:
			t += R.cel(R.v([-36,-70, -24,-78, -8,-72, 0,-80, 8,-72, 24,-78, 36,-70, 30,-52, 34,-42, 18,-32, 14,-14, 9,2, -9,2, -14,-14, -18,-32, -34,-42, -30,-52]), p.armor, p.armor_s)
			t += R.cel(R.v([-16,-66, -5,-70, 0,-62, 5,-70, 16,-66, 12,-44, 0,-32, -12,-44]), p.dark, p.dark_s, 2.2)
			t += R.flat(R.path(R.v([-4,-58, 4,-58, 2,-44, -2,-44])), R.hex(p.accent))
			for k in 3:
				t += R.accent(R.v([-9 + k,-24 + k * 7, 9 - k,-24 + k * 7]), p.dark_s, 2.2)
	return t


static func pelvis(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-20,-6, 20,-6, 18,7, 6,14, -6,14, -18,7]), p.dark, p.dark_s) + R.cel(R.v([-5,-4, 5,-4, 4,10, -4,10]), p.second, p.second_s, 2.0)
		"prime":
			return R.cel(R.v([-16,-6, 16,-6, 19,4, 5,16, -5,16, -19,4]), p.dark, p.dark_s) + R.accent(R.v([-10,2, 0,10, 10,2]), p.accent, 2.2)
		_:
			return R.cel(R.v([-18,-6, 18,-6, 22,5, 11,9, 5,16, -5,16, -11,9, -22,5]), p.dark, p.dark_s) + R.accent(R.v([-9,1, 9,1]), p.armor_s, 2.0)

# ── Piernas ───────────────────────────────────────────────────────────────────

static func thigh(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-12,-4, 12,-4, 13,34, 8,44, -8,44, -13,34]), p.second, p.second_s)
		"prime":
			return R.cel(R.v([-9,-4, 10,-4, 9,34, 5,44, -5,44, -9,34]), p.joint, p.dark, 2.8) + R.cel(R.v([-10,2, -2,0, -3,30, -9,26]), p.armor, p.armor_s, 2.0)
		_:
			return R.cel(R.v([-11,-4, 10,-4, 13,14, 9,24, 12,34, 6,44, -7,44, -12,32, -9,20, -13,10]), p.joint, p.dark)


static func shin(skin: String, p: Dictionary) -> String:
	var s := ""
	match skin:
		"g1":
			# Pantorrilla con forma de motor de reacción.
			s += R.cel(R.v([-13,0, 13,0, 17,38, 13,52, -13,52, -17,38]), p.dark, p.dark_s)
			s += R.cel(R.v([-10,-7, 10,-7, 11,8, 0,14, -11,8]), p.armor, p.armor_s, 2.2)
			s += R.cel(R.v([-10,24, 10,24, 11,44, -11,44]), p.armor, p.armor_s, 2.0)
			s += R.accent(R.v([-7,30, 7,30]), p.second, 2.2)
			s += R.accent(R.v([-7,36, 7,36]), p.second, 2.2)
		"prime":
			# Espinilla muy fina con espolón hacia delante.
			s += R.cel(R.v([-8,0, 9,0, 17,28, 10,52, -9,52, -14,28]), p.dark, p.dark_s)
			s += R.cel(R.v([-8,-16, 9,-3, 11,10, 0,16, -10,8]), p.armor, p.armor_s, 2.2)
			s += R.accent(R.v([-7,26, -3,46]), p.accent, 2.4)
			s += R.accent(R.v([8,26, 4,46]), p.accent, 2.4)
		_:
			s += R.cel(R.v([-11,0, 11,0, 17,16, 12,26, 17,38, 11,52, -11,52, -17,36, -12,24, -17,12]), p.dark, p.dark_s)
			s += R.cel(R.v([-9,-7, 3,-11, 11,-3, 8,9, -3,14, -11,6]), p.armor, p.armor_s, 2.2)
			s += R.cel(R.v([-6,24, 8,20, 10,42, -5,46]), p.armor, p.armor_s, 1.8)
			s += R.accent(R.v([-2,30, 5,28]), p.accent, 1.8)
	return s


static func foot(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-13,-6, 12,-6, 30,8, 30,14, -16,14, -16,5]), p.dark, p.dark_s)
		"prime":
			# Pie en punta, con tacón.
			return R.cel(R.v([-9,-6, 9,-6, 34,11, 30,14, 4,10, -6,14, -13,14, -12,3]), p.joint, p.dark)
		_:
			return R.cel(R.v([-11,-6, 11,-6, 18,3, 34,10, 30,14, 10,11, 4,14, -18,14, -15,4]), p.joint, p.dark)

# ── Brazos ────────────────────────────────────────────────────────────────────

static func shoulder(skin: String, p: Dictionary, s: float) -> String:
	var m: bool = s < 0.0
	match skin:
		"g1":
			# Toma de aire del F-15 en el hombro.
			var o := R.cel(R.v([-14,-12, 16,-12, 18,12, -14,14], m), p.armor, p.armor_s)
			o += R.cel(R.v([-9,-7, 12,-7, 13,8, -9,9], m), p.dark_s, p.dark_s, 2.0)
			return o + R.accent(R.v([-14,-12, 16,-12], m), p.second, 2.6)
		"prime":
			return R.cel(R.v([-12,12, -18,-4, -14,-22, 0,-10, 14,-16, 18,-2, 12,12], m), p.armor, p.armor_s) + R.accent(R.v([-9,4, 11,3], m), p.accent, 2.2)
		_:
			var o := R.cel(R.v([-14,12, -20,-6, -10,-10, -12,-22, 2,-13, 10,-22, 12,-9, 20,-4, 15,12], m), p.armor, p.armor_s)
			return o + R.cel(R.v([-7,1, 7,-1, 9,8, -5,10], m), p.dark, p.dark_s, 1.8)


static func upper_arm(p: Dictionary) -> String:
	return R.cel(R.v([-7,-2, 7,-2, 7,30, -7,30]), p.joint, p.dark, 2.8)


static func fist_arm(skin: String, p: Dictionary) -> String:
	var f := ""
	var fingers := 0.0
	match skin:
		"g1":
			f += R.cel(R.v([-10,0, 10,0, 13,26, 10,38, -10,38, -13,26]), p.armor, p.armor_s)
			f += R.accent(R.v([-7,14, 7,14]), p.second, 2.4)
		"prime":
			f += R.cel(R.v([-7,0, 9,0, 15,18, 8,38, -8,38, -12,16]), p.armor, p.armor_s)
			f += R.accent(R.v([-4,10, 1,26, 6,12]), p.accent, 2.2)
			fingers = 14.0
		_:
			f += R.cel(R.v([-9,0, 9,0, 14,12, 9,22, 13,32, 8,38, -9,38, -13,28, -9,18, -14,8]), p.armor, p.armor_s)
			f += R.cel(R.v([-13,6, -24,-6, -22,20, -13,26]), p.second, p.second_s, 2.0)
			fingers = 9.0
	var hand := R.cel(R.v([-9,0, 9,0, 11,10, 7,17, -7,17, -11,10]), p.dark, p.dark_s, 2.4)
	if fingers > 0.0:
		for x in [-7, -2, 3, 8]:
			hand += R.shape(R.path(R.v([x - 2,16, x + 2,16, x,16 + fingers])), R.hex(p.armor if skin == "prime" else p.dark), 1.4)
	return f + R.joint(Vector2(0, 38), 0.0, hand)


## Rayo nulificador: montado en el antebrazo, con la boca en y≈80.
static func gun(skin: String, p: Dictionary, charge: float) -> String:
	var c := ""
	match skin:
		"g1":
			c += R.cel(R.v([-11,0, 11,0, 13,30, 9,36, -9,36, -13,30]), p.armor, p.armor_s)
			c += R.cel(R.v([-5,28, 5,28, 5,72, -5,72]), p.dark, p.dark_s, 2.4)
			for y in [40, 54]:
				c += R.cel(R.v([-7,y, 7,y, 7,y + 5, -7,y + 5]), p.second, p.second_s, 1.8)
			c += R.cel(R.v([-8,70, 8,70, 9,80, -9,80]), p.dark_s, p.dark_s, 2.2)
		"prime":
			# Lanzamisiles estrecho sobre un antebrazo fino.
			c += R.cel(R.v([-8,0, 9,0, 13,22, 7,34, -7,34, -11,20]), p.armor, p.armor_s)
			c += R.cel(R.v([-5,24, 5,24, 7,62, 0,80, -7,62]), p.dark, p.dark_s, 2.2)
			c += R.accent(R.v([0,30, 0,66]), p.accent, 2.8)
			c += R.cel(R.v([5,30, 15,44, 6,50]), p.second, p.second_s, 1.8)
			c += R.cel(R.v([-5,30, -15,44, -6,50]), p.second, p.second_s, 1.8)
		_:
			# Cañón rotativo hecho de segmentos.
			c += R.cel(R.v([-10,0, 10,0, 14,14, 10,24, 13,34, 8,40, -8,40, -13,32, -10,22, -14,12]), p.armor, p.armor_s)
			for k in 3:
				var y: int = 38 + k * 13
				c += R.cel(R.v([-7,y, 7,y, 9,y + 10, 0,y + 13, -9,y + 10]), p.dark if k % 2 == 0 else p.second, p.dark_s, 2.0)
			c += R.accent(R.v([-3,44, -3,72]), p.accent, 1.6)
			c += R.cel(R.v([-7,72, 7,72, 9,80, -9,80]), p.joint, p.dark_s, 2.0)
	if charge > 0.01:
		c += R.circle(0, 80, 14.0 + 9.0 * charge, "url(#e_glow)", 0.0, charge)
	return c

# ── Avión ─────────────────────────────────────────────────────────────────────
# Piezas por separado: la transformación las despliega una a una.

static func jet_parts(skin: String, _pose: Dictionary) -> Dictionary:
	var p: Dictionary = SKINS[skin]
	var q := {"far": "", "body": "", "near": "", "tails": "", "nozzle": ""}
	match skin:
		"g1":
			# F-15: fuselaje ancho, tomas de aire rectas y dos derivas verticales.
			q.far += R.cel(R.v([116,102, 182,102, 150,58, 92,64]), p.armor_s, p.armor_s.darkened(0.2))
			q.far += R.cel(R.v([66,106, 104,102, 90,50, 58,56]), p.armor_s, p.armor_s.darkened(0.2))
			q.body += R.cel(R.v([26,120, 58,104, 202,100, 258,108, 326,128, 258,142, 58,148, 26,142]), p.armor, p.armor_s)
			q.body += R.cel(R.v([280,115, 326,128, 280,140, 288,128]), p.second, p.second_s, 2.2)
			q.body += R.cel(R.v([168,130, 226,130, 220,162, 162,162]), p.dark, p.dark_s, 2.6)
			q.body += R.cel(R.v([176,136, 218,136, 214,154, 172,154]), p.dark_s, p.dark_s, 1.8)
			q.body += R.cel(R.v([212,100, 246,103, 266,117, 214,116]), p.accent, p.accent.darkened(0.3), 2.2)
			q.body += R.flat(R.path(R.v([222,103, 232,104, 228,114, 218,114])), "#ffffff", 0.55)
			q.body += R.accent(R.v([40,132, 160,130]), p.second, 3.2)
			q.body += R.accent(R.v([40,138, 160,136]), p.dark, 2.2)
			q.near += R.cel(R.v([104,138, 186,138, 150,200, 58,190]), p.armor, p.armor_s)
			q.near += R.cel(R.v([58,190, 150,200, 156,190, 66,178]), p.second, p.second_s, 2.2)
			q.near += _insignia(Vector2(118, 164), 1.1, p.dark)
			q.tails += R.cel(R.v([30,116, 78,108, 52,46, 22,52]), p.armor, p.armor_s)
			q.tails += R.cel(R.v([22,52, 52,46, 56,60, 26,66]), p.second, p.second_s, 2.0)
			q.tails += R.cel(R.v([24,140, 84,140, 46,174, 8,164]), p.armor, p.armor_s)
			q.nozzle += R.cel(R.v([12,116, 30,116, 30,146, 12,146]), p.dark_s, p.dark_s, 2.6)
		"prime":
			# Jet afilado: cuerpo fino y largo, morro caído, alas muy barridas.
			q.far += R.cel(R.v([128,110, 196,108, 146,62, 96,66]), p.armor_s, p.armor_s.darkened(0.2))
			q.far += R.cel(R.v([60,112, 94,110, 66,62, 42,66]), p.second_s, p.second_s.darkened(0.2))
			q.body += R.cel(R.v([24,124, 66,110, 206,106, 262,114, 332,136, 258,142, 72,146, 26,138]), p.armor, p.armor_s)
			q.body += R.cel(R.v([282,120, 332,136, 282,142, 292,132]), p.dark, p.dark_s, 2.2)
			q.body += R.cel(R.v([214,106, 248,109, 270,122, 216,120]), p.second, p.second_s, 2.2)
			q.body += R.flat(R.path(R.v([224,109, 234,110, 230,119, 220,119])), "#ffffff", 0.35)
			q.body += R.accent(R.v([46,132, 124,128, 206,130, 276,132]), p.accent, 3.0)
			q.body += R.cel(R.v([170,132, 212,132, 204,152, 160,150]), p.dark, p.dark_s, 2.2)
			q.near += R.cel(R.v([96,140, 196,136, 96,206, 34,200]), p.armor, p.armor_s)
			q.near += R.accent(R.v([104,152, 66,194]), p.accent, 2.6)
			q.near += R.cel(R.v([34,200, 96,206, 106,196, 50,186]), p.second, p.second_s, 2.0)
			q.tails += R.cel(R.v([28,120, 70,112, 34,54, 12,60]), p.armor, p.armor_s)
			q.tails += R.accent(R.v([36,110, 22,70]), p.accent, 2.4)
			q.tails += R.cel(R.v([28,136, 78,138, 30,172, 4,160]), p.second, p.second_s)
			q.nozzle += R.cel(R.v([12,122, 28,120, 28,142, 12,140]), p.dark_s, p.dark_s, 2.6)
		_:
			# F-22: facetado, ala de diamante, derivas inclinadas, cabina dorada.
			q.far += R.cel(R.v([120,106, 192,104, 160,70, 122,66]), p.second, p.second_s)
			q.far += R.cel(R.v([62,108, 96,106, 60,62, 40,68]), p.second, p.second_s)
			q.body += R.cel(R.v([24,122, 42,112, 80,106, 206,102, 256,112, 330,132, 262,138, 200,144, 86,148, 28,140]), p.armor, p.armor_s)
			q.body += R.flat(R.path(R.v([206,102, 256,112, 240,124, 192,116])), R.hex(p.armor_s), 0.8)
			q.body += R.cel(R.v([214,103, 250,108, 270,120, 218,119]), Color("c9973a"), Color("8f6a26"), 2.2)
			q.body += R.flat(R.path(R.v([224,106, 234,107, 230,117, 220,117])), "#ffffff", 0.4)
			# Toma de aire en dientes de sierra (rasgo del F-22).
			q.body += R.cel(R.v([168,128, 216,124, 200,152, 158,150]), p.dark, p.dark_s, 2.4)
			q.body += R.accent(R.v([60,118, 92,130, 60,142]), p.second, 2.2)
			q.body += R.accent(R.v([118,116, 146,132, 118,144]), p.second, 2.2)
			q.near += R.cel(R.v([96,140, 204,136, 136,200, 42,190]), p.armor, p.armor_s)
			q.near += R.cel(R.v([104,152, 180,148, 136,188, 74,180]), p.second, p.second_s, 1.8)
			q.tails += R.cel(R.v([28,120, 72,112, 26,54, 6,64]), p.armor, p.armor_s)
			q.tails += R.cel(R.v([22,140, 86,142, 26,176, -2,162]), p.armor, p.armor_s)
			q.nozzle += R.cel(R.v([12,120, 28,118, 28,144, 12,142]), p.dark_s, p.dark_s, 2.6)
	return q


static func vehicle(D, skin: String, pose: Dictionary = {}, k: float = 1.0) -> Image:
	var r = C.canvas(D, skin)
	var p: Dictionary = SKINS[skin]
	var oy: float = float(pose.get("bob", 0.0)) - 6.0
	var rc: float = pose.get("recoil", 0.0)
	var boost: float = pose.get("boost", 0.5)
	# Sombra lejana: va volando.
	r.add(R.ellipse(150, 226, 104, 6, "#000000", 0.26))
	var q: Dictionary = jet_parts(skin, pose)
	var fx := _flame(p, boost)
	r.add(R.joint(Vector2(-rc, oy), 0.0, fx + q.far + q.nozzle + q.tails + q.body + q.near))
	# Líneas de velocidad
	if pose.has("lines"):
		var t: float = pose.lines
		for i in 5:
			var y: float = 84.0 + i * 26.0
			var x: float = -46.0 + fposmod(t * 40.0 + i * 13.0, 40.0)
			r.add(R.faded(0.35, R.accent(R.v([x, y + oy, x + 46.0, y + oy]), Color.WHITE, 2.0)))
	var flash: float = pose.get("flash", 0.0)
	if flash > 0.01:
		var m := Vector2(332.0 - rc, 134.0 + oy)
		r.add(R.circle(m.x, m.y, 26.0 * flash, "url(#e_glow)", 0.0, 1.0))
	return r.render_scaled(k)


static func _flame(p: Dictionary, boost: float) -> String:
	var l: float = 30.0 + 44.0 * boost
	var f := R.circle(12, 131, 18.0 + 8.0 * boost, "url(#e_glow)", 0.0, 0.5)
	f += R.shape(R.path(R.v([14,120, 14 - l,131, 14,142])), R.hex(p.energy), 0.0)
	f += R.shape(R.path(R.v([14,125, 14 - l * 0.62,131, 14,137])), "#ffffff", 0.0)
	return f


# ── Transformación ────────────────────────────────────────────────────────────

## Fotograma de robot → jet (t de 0 a 1): se estira y se tumba hasta quedar en horizontal,
## el fuselaje se forma a su alrededor, y las alas y derivas se despliegan al final.
static func morph(D, skin: String, t: float, k: float = 1.0) -> Image:
	var p: Dictionary = SKINS[skin]
	var r = C.canvas(D, skin)
	var dive: float = C.smooth(t / 0.55)
	var body: float = C.smooth((t - 0.28) / 0.45)
	var wings: float = C.smooth((t - 0.5) / 0.45)
	var oy: float = -6.0
	r.add(R.ellipse(150, 226, lerpf(SHADOW_W, 104.0, wings), lerpf(7.0, 6.0, wings), "#000000", lerpf(0.3, 0.26, wings)))
	var q: Dictionary = jet_parts(skin, {})
	if wings > 0.0:
		r.add(R.joint(Vector2(0, oy), 0.0, R.scaled(Vector2(150, 106), 1.0, wings, q.far)))
		r.add(R.joint(Vector2(0, oy), 0.0, _flame(p, wings * 0.5)))
	var robot_op: float = 1.0 - C.smooth((t - 0.62) / 0.2)
	if robot_op > 0.0:
		var figure: String = C.robot_svg(D, skin, {
			"no_shadow": true,
			"near_foot": NEAR_FOOT.lerp(Vector2(146, 212), dive),
			"far_foot": FAR_FOOT.lerp(Vector2(156, 212), dive),
			"gun_sh": lerpf(-16.0, -4.0, dive),
			"gun_el": lerpf(-12.0, -2.0, dive),
			"fist_sh": lerpf(8.0, 3.0, dive),
			"fist_el": lerpf(8.0, 2.0, dive),
			"head": dive * -60.0,
			"charge": 0.3,
		})
		# Se tumba hacia delante hasta quedar con la cabeza donde irá el morro.
		var rot: String = R.rotated(Vector2(150, 122), dive * 80.0, figure)
		r.add(R.faded(robot_op, R.joint(Vector2(dive * 28.0, dive * 2.0), 0.0, rot)))
	if body > 0.0:
		r.add(R.joint(Vector2(0, oy), 0.0, R.faded(C.smooth(body * 2.0), R.scaled(Vector2(170, 126), lerpf(0.45, 1.0, body), lerpf(0.5, 1.0, body), q.body + q.nozzle))))
	if wings > 0.0:
		r.add(R.joint(Vector2(0, oy), 0.0, R.scaled(Vector2(150, 138), 1.0, wings, q.near)))
		r.add(R.joint(Vector2(0, oy), 0.0, R.scaled(Vector2(44, 128), lerpf(0.5, 1.0, wings), wings, q.tails)))
	C.energy_arcs(r, p, Vector2(170, 126), t)
	return r.render_scaled(k)
