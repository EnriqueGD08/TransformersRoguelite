# megatron_cel.gd
# PROTOTIPO: Megatron en estilo cel (colores planos, contorno grueso, formas angulares).
# Cada skin tiene su PROPIA silueta (no solo otros colores): G1 cuadrado y plateado,
# Prime alto y afilado con pinchos, Bay irregular con placas dentadas.
# Solo define piezas: el esqueleto y las animaciones son comunes (cel_character, cel_anim).

extends RefCounted

const R := preload("res://tools/art2/vector_rig.gd")
const C := preload("res://tools/art2/cel_character.gd")

const SKINS := {
	"g1": {"armor": Color("d3d8de"), "armor_s": Color("9ca5b0"), "dark": Color("3b3f48"), "dark_s": Color("272a31"),
		"joint": Color("6a6f79"), "accent": Color("c23a33"), "eye": Color("ff3b30"), "energy": Color("c86bff")},
	"prime": {"armor": Color("77808f"), "armor_s": Color("535b69"), "dark": Color("2c303a"), "dark_s": Color("1d2027"),
		"joint": Color("454a56"), "accent": Color("a845ff"), "eye": Color("ff2a2a"), "energy": Color("b84dff")},
	"bay": {"armor": Color("857e70"), "armor_s": Color("5e584d"), "dark": Color("35322d"), "dark_s": Color("24221f"),
		"joint": Color("4b4740"), "accent": Color("c9501f"), "eye": Color("ff5a1f"), "energy": Color("ff7a2a")},
}

const THIGH := 44.0
const SHIN := 50.0
const HIP_Y := 122.0
const HIP_HALF := 12.0
const SHOULDER_X := 50.0
const SHOULDER_Y := -64.0
const NECK := Vector2(2, -76)
const NEAR_FOOT := Vector2(126, 212)
const FAR_FOOT := Vector2(178, 212)
const SHADOW_W := 72.0
const HALF_STRIDE := 31.0
const LIFT := 15.0
const WALK_CENTER := 152.0
const VEHICLE_RECOIL := 22.0
const VEHICLE_HOVER := 0.0


static func _insignia(c: Vector2, k: float, col: Color) -> String:
	var pts := R.v([-8,-8, -4,-8, -2,-4, 2,-4, 4,-8, 8,-8, 6,2, 3,3, 2,8, 0,10, -2,8, -3,3, -6,2])
	var out := PackedVector2Array()
	for p in pts:
		out.append(c + p * k)
	return R.shape(R.path(out), R.hex(col), 1.6)


## Megatron no lleva nada a la espalda.
static func back(_skin: String, _p: Dictionary) -> String:
	return ""


# ── Cabezas ───────────────────────────────────────────────────────────────────

static func head(skin: String, p: Dictionary) -> String:
	var h := ""
	match skin:
		"g1":
			# Casco tipo cubo, redondeado por chaflanes, con cresta central.
			h += R.cel(R.v([-20,4, -22,-24, -15,-38, 15,-38, 22,-24, 20,4, 11,4, 11,-16, -11,-16, -11,4]), p.armor, p.armor_s)
			h += R.cel(R.v([-4,-44, 4,-44, 6,-16, -6,-16]), p.armor, p.armor_s, 2.4)
			h += R.cel(R.v([-12,-17, 12,-17, 10,2, 4,8, -4,8, -10,2]), p.dark, p.dark_s, 2.4)
			h += R.flat(R.path(R.v([-10,-12, -2,-9, -2,-6, -10,-8])), R.hex(p.eye))
			h += R.flat(R.path(R.v([10,-12, 2,-9, 2,-6, 10,-8])), R.hex(p.eye))
			h += R.accent(R.v([-5,1, 5,1]), p.joint, 2.0)
		"prime":
			# Yelmo alto con cuernos y mandíbula de colmillos.
			h += R.cel(R.v([-13,2, -17,-18, -27,-34, -12,-30, -7,-48, 0,-36, 7,-48, 12,-30, 27,-34, 17,-18, 13,2, 5,9, -5,9]), p.armor, p.armor_s)
			h += R.cel(R.v([-10,-20, 10,-20, 8,-4, 4,5, -4,5, -8,-4]), p.dark, p.dark_s, 2.4)
			h += R.flat(R.path(R.v([-9,-16, -2,-12, -3,-9, -9,-12])), R.hex(p.eye))
			h += R.flat(R.path(R.v([9,-16, 2,-12, 3,-9, 9,-12])), R.hex(p.eye))
			for x in [-5, -2, 1, 4]:
				h += R.flat(R.path(R.v([x,-3, x + 2,-3, x + 1,2])), R.hex(p.armor))
		"bay":
			# Calavera con placas sueltas y dentadas.
			h += R.cel(R.v([-15,3, -20,-10, -16,-22, -23,-37, -10,-31, -4,-41, 3,-37, 9,-42, 12,-30, 23,-35, 16,-21, 20,-9, 14,3, 7,10, 1,7, -6,11]), p.armor, p.armor_s)
			h += R.cel(R.v([-12,-20, 12,-20, 13,-8, 7,4, 2,1, -3,5, -8,3, -13,-8]), p.dark, p.dark_s, 2.2)
			h += R.flat(R.path(R.v([-11,-16, -3,-12, -5,-8, -11,-11])), R.hex(p.eye))
			h += R.flat(R.path(R.v([11,-16, 3,-12, 5,-8, 11,-11])), R.hex(p.eye))
			for x in [-6, -2, 2, 6]:
				h += R.accent(R.v([x,-5, x + 1,2]), p.armor_s, 1.6)
	return h

# ── Torso ─────────────────────────────────────────────────────────────────────

static func torso(skin: String, p: Dictionary) -> String:
	var t := ""
	match skin:
		"g1":
			t += R.cel(R.v([-42,-74, 42,-74, 46,-50, 28,-24, 18,2, -18,2, -28,-24, -46,-50]), p.armor, p.armor_s)
			t += R.cel(R.v([-24,-68, 24,-68, 22,-34, 12,-26, -12,-26, -22,-34]), p.armor, p.armor_s, 2.4)
			t += _insignia(Vector2(0, -50), 1.45, p.accent)
			for s in [-1, 1]:
				for k in 3:
					t += R.accent(R.v([s * 28,-62 + k * 7, s * 38,-62 + k * 7]), p.dark, 2.2)
			t += R.cel(R.v([-16,-22, 16,-22, 14,2, -14,2]), p.dark, p.dark_s, 2.4)
			t += R.accent(R.v([-11,-14, 11,-14]), p.joint, 2.0)
			t += R.accent(R.v([-10,-6, 10,-6]), p.joint, 2.0)
		"prime":
			t += R.cel(R.v([-50,-74, -32,-80, 32,-80, 50,-74, 38,-44, 16,-18, 12,2, -12,2, -16,-18, -38,-44]), p.armor, p.armor_s)
			t += R.cel(R.v([-26,-74, 26,-74, 20,-44, 0,-26, -20,-44]), p.dark, p.dark_s, 2.4)
			t += _insignia(Vector2(0, -56), 1.25, p.armor)
			# Cicatriz de energon oscuro
			t += R.accent(R.v([-18,-68, -8,-58, -14,-48, -3,-38]), p.accent, 3.0)
			t += R.accent(R.v([18,-68, 8,-58, 14,-48, 3,-38]), p.accent, 3.0)
			for k in 3:
				t += R.cel(R.v([-13 + k,-22 + k * 8, 13 - k,-22 + k * 8, 12 - k,-16 + k * 8, -12 + k,-16 + k * 8]), p.dark, p.dark_s, 1.8)
		"bay":
			t += R.cel(R.v([-44,-70, -30,-80, -14,-72, 0,-80, 14,-72, 30,-80, 44,-70, 40,-50, 46,-40, 26,-30, 22,-14, 14,2, -14,2, -22,-14, -26,-30, -46,-40, -40,-50]), p.armor, p.armor_s)
			t += R.cel(R.v([-20,-66, -6,-70, 0,-62, 6,-70, 20,-66, 16,-44, 6,-34, -6,-34, -16,-44]), p.dark, p.dark_s, 2.2)
			t += R.flat(R.path(R.v([-5,-58, 5,-58, 3,-44, -3,-44])), R.hex(p.accent))
			for s in [-1, 1]:
				t += R.cel(R.v([s * 22,-44, s * 38,-48, s * 34,-36, s * 22,-30]), p.armor, p.armor_s, 2.0)
				t += R.accent(R.v([s * 6,-30, s * 18,-22, s * 10,-10]), p.dark_s, 2.2)
			for k in 3:
				t += R.accent(R.v([-10 + k,-24 + k * 8, 10 - k,-24 + k * 8]), p.dark_s, 2.4)
	return t


static func pelvis(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-26,-6, 26,-6, 24,7, 8,15, -8,15, -24,7]), p.dark, p.dark_s) + R.cel(R.v([-7,-4, 7,-4, 5,11, -5,11]), p.accent, p.accent.darkened(0.3), 2.2)
		"prime":
			return R.cel(R.v([-22,-6, 22,-6, 26,5, 6,17, -6,17, -26,5]), p.dark, p.dark_s) + R.accent(R.v([-14,2, 0,11, 14,2]), p.accent, 2.4)
		_:
			return R.cel(R.v([-24,-6, 24,-6, 28,6, 14,10, 6,18, -6,18, -14,10, -28,6]), p.dark, p.dark_s) + R.accent(R.v([-12,2, 12,2]), p.armor_s, 2.2)

# ── Piernas ───────────────────────────────────────────────────────────────────

static func thigh(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-14,-4, 14,-4, 15,32, 10,42, -10,42, -15,32]), p.armor, p.armor_s)
		"prime":
			return R.cel(R.v([-11,-4, 13,-4, 12,30, 7,42, -7,42, -12,30]), p.joint, p.dark, 3.0) + R.cel(R.v([-13,2, -3,0, -5,28, -12,24]), p.armor, p.armor_s, 2.2)
		_:
			return R.cel(R.v([-13,-4, 12,-4, 15,12, 11,22, 14,32, 8,42, -9,42, -14,30, -11,18, -15,8]), p.joint, p.dark)


static func shin(skin: String, p: Dictionary) -> String:
	var s := ""
	match skin:
		"g1":
			s += R.cel(R.v([-15,0, 15,0, 19,36, 16,50, -16,50, -19,36]), p.dark, p.dark_s)
			s += R.cel(R.v([-11,-7, 11,-7, 12,8, 0,14, -12,8]), p.armor, p.armor_s, 2.4)
			s += R.cel(R.v([-11,22, 11,22, 12,42, -12,42]), p.armor, p.armor_s, 2.2)
			s += R.accent(R.v([-8,30, 8,30]), p.dark, 2.0)
		"prime":
			# Espinilla larga y afilada, con espolón en la rodilla.
			s += R.cel(R.v([-11,0, 12,0, 22,30, 14,50, -14,50, -20,28]), p.dark, p.dark_s)
			s += R.cel(R.v([-9,-16, 9,-4, 12,10, 0,16, -12,8]), p.armor, p.armor_s, 2.4)
			s += R.accent(R.v([-10,26, -4,44]), p.accent, 2.6)
			s += R.accent(R.v([11,26, 5,44]), p.accent, 2.6)
		_:
			s += R.cel(R.v([-14,0, 14,0, 20,16, 15,26, 21,38, 14,50, -14,50, -21,36, -15,24, -20,12]), p.dark, p.dark_s)
			s += R.cel(R.v([-11,-7, 3,-11, 13,-3, 10,9, -3,14, -13,6]), p.armor, p.armor_s, 2.4)
			s += R.cel(R.v([-8,24, 9,20, 12,40, -6,44]), p.armor, p.armor_s, 2.0)
			s += R.accent(R.v([-3,30, 6,28]), p.accent, 2.0)
	return s


static func foot(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-15,-6, 14,-6, 32,7, 32,14, -19,14, -19,5]), p.armor, p.armor_s)
		"prime":
			return R.cel(R.v([-14,-6, 14,-6, 34,10, 30,14, -22,14, -18,4]), p.joint, p.dark)
		_:
			return R.cel(R.v([-16,-6, 16,-6, 22,3, 32,9, 30,14, 12,11, 6,14, -24,14, -20,4]), p.joint, p.dark)


# ── Brazos ────────────────────────────────────────────────────────────────────

static func shoulder(skin: String, p: Dictionary, s: float) -> String:
	var m: bool = s < 0.0
	match skin:
		"g1":
			return R.cel(R.v([-20,-14, 18,-14, 22,8, 14,18, -16,18, -22,6], m), p.armor, p.armor_s) + R.accent(R.v([-14,0, 14,0], m), p.dark, 2.2)
		"prime":
			return R.cel(R.v([-16,16, -24,-4, -30,-30, -10,-14, 4,-34, 10,-12, 26,-8, 22,12, 8,20], m), p.armor, p.armor_s) + R.accent(R.v([-12,4, 14,2], m), p.accent, 2.4)
		_:
			var o := R.cel(R.v([-20,14, -28,-8, -14,-12, -18,-26, 0,-16, 10,-28, 14,-12, 28,-6, 22,14, 6,20], m), p.armor, p.armor_s)
			return o + R.cel(R.v([-10,2, 8,-2, 12,10, -6,14], m), p.dark, p.dark_s, 2.0)


static func upper_arm(p: Dictionary) -> String:
	return R.cel(R.v([-10,-2, 10,-2, 9,30, -9,30]), p.joint, p.dark, 3.0)


static func fist_arm(skin: String, p: Dictionary) -> String:
	var f := ""
	match skin:
		"g1":
			f += R.cel(R.v([-13,0, 13,0, 16,26, 12,38, -12,38, -16,26]), p.armor, p.armor_s)
			f += R.accent(R.v([-9,14, 9,14]), p.dark, 2.2)
		"prime":
			f += R.cel(R.v([-10,0, 12,0, 20,18, 10,38, -10,38, -16,16]), p.armor, p.armor_s)
			f += R.accent(R.v([-6,10, 2,26, 8,12]), p.accent, 2.4)
		_:
			f += R.cel(R.v([-12,0, 12,0, 18,12, 12,22, 16,32, 10,38, -11,38, -16,28, -12,18, -17,8]), p.armor, p.armor_s)
			f += R.accent(R.v([-8,12, 8,10]), p.dark_s, 2.2)
	# Mano
	var hand := R.cel(R.v([-11,0, 11,0, 14,12, 8,20, -8,20, -14,12]), p.dark, p.dark_s, 2.6)
	for x in [-5, 0, 5]:
		hand += R.accent(R.v([x,10, x,20]), p.dark_s, 1.6)
	if skin != "g1":
		for x in [-8, -3, 3, 8]:
			hand += R.flat(R.path(R.v([x - 2,19, x + 2,19, x,26])), R.hex(p.dark))
	return f + R.joint(Vector2(0, 38), 0.0, hand)


## Cañón de fusión: sale del antebrazo y apunta a lo largo de +Y.
static func gun(skin: String, p: Dictionary, charge: float) -> String:
	var c := ""
	match skin:
		"g1":
			# Tubo negro grueso y recto.
			c += R.cel(R.v([-15,0, 15,0, 15,62, 11,68, -11,68, -15,62]), p.dark, p.dark_s)
			for y in [12, 26, 40]:
				c += R.cel(R.v([-17,y, 17,y, 17,y + 7, -17,y + 7]), p.armor, p.armor_s, 2.2)
			c += R.cel(R.v([-13,66, 13,66, 15,78, -15,78]), p.dark_s, p.dark_s, 2.6)
		"prime":
			# Cañón estrecho y afilado, con aletas.
			c += R.cel(R.v([-11,0, 11,0, 13,48, 7,70, -7,70, -13,48]), p.dark, p.dark_s)
			c += R.cel(R.v([-11,10, -24,28, -12,40]), p.armor, p.armor_s, 2.2)
			c += R.cel(R.v([11,10, 24,28, 12,40]), p.armor, p.armor_s, 2.2)
			c += R.accent(R.v([0,6, 0,60]), p.accent, 3.0)
			c += R.cel(R.v([-9,66, 9,66, 5,80, -5,80]), p.armor, p.armor_s, 2.2)
		_:
			# Masa de piezas irregulares.
			c += R.cel(R.v([-14,0, 14,0, 19,16, 13,28, 18,44, 12,58, 14,68, -14,68, -11,56, -19,42, -13,26, -19,14]), p.dark, p.dark_s)
			c += R.cel(R.v([-16,18, 6,12, 16,22, -2,32]), p.armor, p.armor_s, 2.0)
			c += R.cel(R.v([-12,44, 12,40, 16,52, -8,56]), p.armor, p.armor_s, 2.0)
			c += R.cel(R.v([-12,66, 12,66, 15,78, 4,74, -5,80, -15,76]), p.joint, p.dark_s, 2.4)
	# Boca del cañón con energía
	if charge > 0.01:
		c += R.circle(0, 80, 16.0 + 10.0 * charge, "url(#e_glow)", 0.0, charge)
	return c


# ── Tanque ────────────────────────────────────────────────────────────────────
# pose: bob, tread (fase 0..1), recoil, flash, charge

static func vehicle(D, skin: String, pose: Dictionary = {}, k: float = 1.0) -> Image:
	var r = C.canvas(D, skin)
	var q: Dictionary = tank_parts(skin, pose)
	var oy: float = pose.get("bob", 0.0)
	var rc: float = pose.get("recoil", 0.0)
	r.add(R.ellipse(150, 224, 128, 7, "#000000", 0.3))
	r.add(q.treads)
	r.add(R.joint(Vector2(0, oy), 0.0, q.hull + R.joint(Vector2(-rc * 0.3, 0), 0.0, q.turret)))
	r.add(R.joint(Vector2(-rc, oy), 0.0, q.barrel) + q.fx)
	return r.render_scaled(k)


## Piezas del tanque por separado: la transformación las mueve una a una.
static func tank_parts(skin: String, pose: Dictionary) -> Dictionary:
	var p: Dictionary = SKINS[skin]
	var oy: float = pose.get("bob", 0.0)
	var rc: float = pose.get("recoil", 0.0)
	var phase: float = pose.get("tread", 0.0)
	# Orugas
	var tr := R.cel(R.v([26,186, 40,172, 250,172, 268,186, 268,206, 250,222, 44,222, 26,206]), p.dark, p.dark_s)
	for i in 15:
		var x: float = 34.0 + fposmod(i * 16.0 + phase * 16.0, 232.0)
		tr += R.accent(R.v([x,174, x - 2,184]), p.joint, 3.0)
		tr += R.accent(R.v([x,210, x - 2,220]), p.joint, 3.0)
	for wx in [52, 92, 132, 172, 212, 248]:
		tr += R.circle(wx, 197, 15.0, R.hex(p.joint), 2.6)
		tr += R.circle(wx, 197, 6.0, R.hex(p.dark_s), 2.0)
	var hull := ""
	var turret := ""
	var barrel := ""
	match skin:
		"g1":
			hull += R.cel(R.v([30,172, 36,146, 236,146, 276,172, 262,184, 40,184]), p.armor, p.armor_s)
			hull += R.cel(R.v([70,162, 210,162, 204,178, 76,178]), p.dark, p.dark_s, 2.4)
			turret += R.cel(R.v([84,146, 94,104, 188,104, 206,146]), p.armor, p.armor_s)
			turret += _insignia(Vector2(136, 126), 1.5, p.accent)
			barrel += R.cel(R.v([184,110, 300,110, 300,134, 184,134]), p.dark, p.dark_s)
			for x in [214, 244, 274]:
				barrel += R.cel(R.v([x,106, x + 10,106, x + 10,138, x,138]), p.armor, p.armor_s, 2.2)
			barrel += R.cel(R.v([298,104, 322,108, 322,136, 298,140]), p.dark_s, p.dark_s, 2.6)
		"prime":
			hull += R.cel(R.v([22,176, 54,142, 220,138, 292,172, 262,186, 38,186]), p.armor, p.armor_s)
			hull += R.accent(R.v([56,166, 120,154, 214,158, 270,172]), p.accent, 3.0)
			turret += R.cel(R.v([72,142, 112,100, 186,96, 222,140]), p.dark, p.dark_s)
			turret += R.cel(R.v([96,132, 122,108, 176,106, 198,132]), p.armor, p.armor_s, 2.4)
			turret += _insignia(Vector2(146, 120), 1.2, p.dark)
			turret += R.cel(R.v([78,120, 58,86, 104,108]), p.armor, p.armor_s, 2.4)
			barrel += R.cel(R.v([190,106, 296,114, 312,122, 296,130, 190,134]), p.dark, p.dark_s)
			barrel += R.accent(R.v([200,120, 296,122]), p.accent, 3.2)
			barrel += R.cel(R.v([232,104, 256,84, 262,112]), p.armor, p.armor_s, 2.2)
		_:
			hull += R.cel(R.v([26,176, 40,150, 62,156, 80,140, 120,150, 150,138, 196,150, 232,142, 284,172, 262,186, 40,186]), p.armor, p.armor_s)
			hull += R.cel(R.v([60,164, 100,158, 110,178, 66,180]), p.dark, p.dark_s, 2.2)
			hull += R.cel(R.v([170,162, 226,158, 240,176, 178,180]), p.dark, p.dark_s, 2.2)
			turret += R.cel(R.v([86,146, 80,116, 106,112, 110,96, 150,104, 180,94, 204,118, 216,146]), p.dark, p.dark_s)
			turret += R.cel(R.v([104,134, 112,114, 150,118, 178,110, 196,134]), p.armor, p.armor_s, 2.2)
			turret += R.flat(R.path(R.v([140,120, 156,120, 152,132, 144,132])), R.hex(p.accent))
			barrel += R.cel(R.v([190,108, 240,104, 252,112, 300,110, 306,120, 300,132, 250,130, 240,138, 190,134]), p.dark, p.dark_s)
			barrel += R.cel(R.v([246,104, 276,106, 272,136, 250,136]), p.armor, p.armor_s, 2.2)
	# Fogonazo y carga en la boca
	var flash: float = pose.get("flash", 0.0)
	var charge: float = pose.get("charge", 0.0)
	var mouth := Vector2(322 - rc, 122 + oy)
	var fx := ""
	if charge > 0.01:
		fx += R.circle(mouth.x, mouth.y, 14.0 + 10.0 * charge, "url(#e_glow)", 0.0, charge)
	if flash > 0.01:
		fx += R.circle(mouth.x, mouth.y, 30.0 * flash, "url(#e_glow)", 0.0, 1.0)
	return {"treads": tr, "hull": hull, "turret": turret, "barrel": barrel, "fx": fx}


# ── Transformación ────────────────────────────────────────────────────────────

## Fotograma de la transformación robot → tanque (t de 0 a 1). Es movimiento real de piezas:
## el robot se agacha, se inclina y recoge los brazos; las orugas y el casco salen de debajo
## y se cierran sobre él; la torreta sube y el cañón se extiende.
static func morph(D, skin: String, t: float, k: float = 1.0) -> Image:
	var p: Dictionary = SKINS[skin]
	var r = C.canvas(D, skin)
	var fold: float = _smooth(t / 0.5)
	var body: float = _smooth((t - 0.22) / 0.45)
	var top: float = _smooth((t - 0.55) / 0.4)
	r.add(R.ellipse(150, 224, lerpf(72.0, 128.0, body), 7, "#000000", 0.3))
	var q: Dictionary = tank_parts(skin, {"charge": 0.35 * top})
	if body > 0.0:
		r.add(R.joint(Vector2(0, (1.0 - body) * 26.0), 0.0, R.scaled(Vector2(148, 197), lerpf(0.3, 1.0, body), 1.0, q.treads)))
	var robot_op: float = 1.0 - _smooth((t - 0.62) / 0.2)
	if robot_op > 0.0:
		var figure: String = C.robot_svg(D, skin, {
			"no_shadow": true,
			"crouch": fold * 56.0,
			"torso": fold * 42.0,
			"head": fold * -46.0,
			"near_foot": Vector2(lerpf(126, 112, fold), 212),
			"far_foot": Vector2(lerpf(178, 190, fold), 212),
			"gun_sh": lerpf(-16.0, -88.0, fold),
			"gun_el": lerpf(-12.0, 2.0, fold),
			"fist_sh": lerpf(8.0, -58.0, fold),
			"fist_el": lerpf(8.0, -70.0, fold),
			"charge": 0.3,
		})
		r.add(R.faded(robot_op, R.scaled(Vector2(150, 224), 1.0 + fold * 0.04, 1.0 - top * 0.3, figure)))
	if body > 0.0:
		r.add(R.joint(Vector2(0, (1.0 - body) * 34.0), 0.0, R.scaled(Vector2(150, 180), lerpf(0.45, 1.0, body), lerpf(0.5, 1.0, body), q.hull)))
	if top > 0.0:
		r.add(R.joint(Vector2(0, (1.0 - top) * 30.0), 0.0, R.scaled(Vector2(146, 146), lerpf(0.4, 1.0, top), top, q.turret)))
		r.add(R.joint(Vector2(-(1.0 - top) * 120.0, 0), 0.0, q.barrel))
		r.add(q.fx)
	# Chispazo de energía en el momento en que todo encaja.
	C.energy_arcs(r, p, Vector2(150, 165), t)
	return r.render_scaled(k)


static func _smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
