# shockwave_cel.gd
# Shockwave en estilo cel. Corpulento, sin cara: un solo ojo y el brazo convertido en cañón.
# Se transforma en un cañón láser que flota y GIRA para apuntar (el juego rota el sprite
# entero), así que el cañón va centrado en el eje y=112, sin sombra ni ruedas.
#   G1: morado y gris, cuadrado, antenas → pistola espacial gigante.
#   Prime: alto y anguloso, cuernos → artillería flotante de raíles gemelos.
#   Bay: oscuro y blindado, cabeza hundida → cañón pesado de anillos con cables.
# Solo define piezas: el esqueleto y las animaciones son comunes (cel_character, cel_anim).
# SRP: formas de Shockwave. OCP: no toca el esqueleto común.

extends RefCounted

const R := preload("res://tools/art2/vector_rig.gd")
const C := preload("res://tools/art2/cel_character.gd")

const SKINS := {
	"g1": {"armor": Color("8d60ba"), "armor_s": Color("5f3e88"), "second": Color("c9cdd5"), "second_s": Color("8e94a0"),
		"dark": Color("3c2f56"), "dark_s": Color("272039"), "joint": Color("6a6f79"), "accent": Color("f2c230"),
		"eye": Color("ffd23a"), "energy": Color("c58bff")},
	"prime": {"armor": Color("5c4b88"), "armor_s": Color("3b305d"), "second": Color("9ba1ad"), "second_s": Color("646a76"),
		"dark": Color("26242f"), "dark_s": Color("17161d"), "joint": Color("4f535e"), "accent": Color("d66bff"),
		"eye": Color("ff4a3a"), "energy": Color("d66bff")},
	"bay": {"armor": Color("423f4b"), "armor_s": Color("2a2830"), "second": Color("6c409c"), "second_s": Color("472a6a"),
		"dark": Color("1f1e24"), "dark_s": Color("131217"), "joint": Color("7a7f8a"), "accent": Color("a06bff"),
		"eye": Color("ff3a3a"), "energy": Color("a06bff")},
}

const THIGH := 46.0
const SHIN := 50.0
const HIP_Y := 118.0
const HIP_HALF := 14.0
const SHOULDER_X := 52.0
const SHOULDER_Y := -62.0
const NECK := Vector2(1, -74)
const NEAR_FOOT := Vector2(122, 212)
const FAR_FOOT := Vector2(180, 212)
const SHADOW_W := 78.0
const HALF_STRIDE := 31.0
const LIFT := 12.0
const WALK_CENTER := 152.0
const VEHICLE_RECOIL := 6.0
const VEHICLE_HOVER := 0.0

# ── Espalda ───────────────────────────────────────────────────────────────────

static func back(skin: String, p: Dictionary) -> String:
	var b := ""
	for s in [1, -1]:
		var m: bool = s > 0
		match skin:
			"g1":
				pass
			"prime":
				# Aletas altas y estrechas.
				b += R.cel(R.v([-22,-66, -44,-110, -56,-100, -38,-54], m), p.armor, p.armor_s)
				b += R.accent(R.v([-32,-68, -46,-96], m), p.accent, 2.2)
			_:
				# Tubos gruesos saliendo de la espalda.
				b += R.cel(R.v([-26,-68, -14,-74, -28,-112, -42,-106], m), p.joint, p.dark, 2.6)
				b += R.cel(R.v([-42,-106, -28,-112, -30,-120, -46,-114], m), p.second, p.second_s, 2.0)
	return b

# ── Cabeza ────────────────────────────────────────────────────────────────────

static func _eye(c: Vector2, r: float, p: Dictionary) -> String:
	return R.circle(c.x, c.y, r + 2.5, R.hex(p.dark_s), 2.0) + R.circle(c.x, c.y, r, R.hex(p.eye)) + R.circle(c.x - r * 0.3, c.y - r * 0.3, r * 0.3, "#ffffff")


static func head(skin: String, p: Dictionary) -> String:
	var h := ""
	match skin:
		"g1":
			# Casco cuadrado, antenas a los lados y un ojo redondo en vez de cara.
			for s in [1, -1]:
				h += R.cel(R.v([s * 15,-22, s * 20,-22, s * 20,-44, s * 16,-44]), p.second, p.second_s, 2.2)
				h += R.cel(R.v([s * 13,-20, s * 22,-20, s * 22,-8, s * 13,-8]), p.armor, p.armor_s, 2.2)
			h += R.cel(R.v([-15,4, -15,-24, -8,-30, 8,-30, 15,-24, 15,4]), p.armor, p.armor_s)
			h += R.cel(R.v([-11,-22, 11,-22, 11,2, -11,2]), p.dark, p.dark_s, 2.0)
			h += _eye(Vector2(0, -10), 6.0, p)
		"prime":
			# Cráneo alargado con cuernos hacia arriba.
			for s in [1, -1]:
				h += R.cel(R.v([s * 11,-18, s * 24,-46, s * 16,-44, s * 7,-26]), p.second, p.second_s, 2.2)
			h += R.cel(R.v([-14,0, -16,-18, -8,-32, 0,-36, 8,-32, 16,-18, 14,0, 6,8, -6,8]), p.armor, p.armor_s)
			h += R.cel(R.v([-10,-20, 10,-20, 8,-1, 0,5, -8,-1]), p.dark, p.dark_s, 1.8)
			h += _eye(Vector2(0, -10), 6.5, p)
		_:
			# Cabeza hundida entre placas: casi solo se ve el ojo.
			h += R.cel(R.v([-20,8, -22,-12, -12,-24, 12,-24, 22,-12, 20,8]), p.armor, p.armor_s)
			h += R.cel(R.v([-12,-16, 12,-16, 11,4, -11,4]), p.dark, p.dark_s, 1.8)
			h += _eye(Vector2(0, -6), 5.5, p)
			for s in [1, -1]:
				h += R.accent(R.v([s * 16,-6, s * 16,4]), p.second, 2.4)
	return h

# ── Torso ─────────────────────────────────────────────────────────────────────

static func torso(skin: String, p: Dictionary) -> String:
	var t := ""
	match skin:
		"g1":
			t += R.cel(R.v([-48,-74, 48,-74, 50,-40, 30,-24, 26,2, -26,2, -30,-24, -50,-40]), p.second, p.second_s)
			t += R.cel(R.v([-38,-68, 38,-68, 34,-42, 0,-30, -34,-42]), p.armor, p.armor_s, 2.4)
			t += R.cel(R.v([-14,-62, 14,-62, 12,-44, 0,-38, -12,-44]), p.dark, p.dark_s, 2.0)
			t += R.flat(R.path(R.v([-4,-56, 4,-56, 3,-46, -3,-46])), R.hex(p.accent))
			t += R.cel(R.v([-24,-24, 24,-24, 22,2, -22,2]), p.dark, p.dark_s, 2.2)
			for k in 3:
				t += R.accent(R.v([-15,-18 + k * 6, 15,-18 + k * 6]), p.joint, 1.8)
		"prime":
			t += R.cel(R.v([-50,-74, -30,-82, 30,-82, 50,-74, 42,-44, 22,-26, 18,2, -18,2, -22,-26, -42,-44]), p.armor, p.armor_s)
			t += R.cel(R.v([-22,-76, 22,-76, 28,-50, 0,-32, -28,-50]), p.second, p.second_s, 2.4)
			t += R.cel(R.v([-12,-68, 12,-68, 15,-52, 0,-42, -15,-52]), p.dark, p.dark_s, 1.8)
			t += R.flat(R.path(R.v([0,-64, 7,-54, 0,-47, -7,-54])), R.hex(p.accent))
			for k in 3:
				t += R.cel(R.v([-16 + k,-26 + k * 9, 16 - k,-26 + k * 9, 14 - k,-19 + k * 9, -14 + k,-19 + k * 9]), p.dark, p.dark_s, 1.6)
		_:
			# Bloque blindado con cables morados que le cruzan el pecho.
			t += R.cel(R.v([-52,-72, -36,-84, 36,-84, 52,-72, 46,-40, 28,-22, 22,2, -22,2, -28,-22, -46,-40]), p.armor, p.armor_s)
			t += R.cel(R.v([-30,-76, 30,-76, 34,-48, 12,-38, -12,-38, -34,-48]), p.dark, p.dark_s, 2.2)
			t += R.accent(R.v([-26,-68, -8,-56, -12,-40]), p.second, 3.6)
			t += R.accent(R.v([26,-68, 8,-56, 12,-40]), p.second, 3.6)
			t += R.circle(0, -56, 8.0, R.hex(p.dark_s), 2.0) + R.circle(0, -56, 4.5, R.hex(p.energy))
			for k in 3:
				t += R.accent(R.v([-18 + k * 2,-30 + k * 9, 18 - k * 2,-30 + k * 9]), p.joint, 2.2)
	return t


static func pelvis(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-26,-6, 26,-6, 24,8, 8,16, -8,16, -24,8]), p.armor, p.armor_s) + R.cel(R.v([-7,-3, 7,-3, 6,11, -6,11]), p.second, p.second_s, 1.8)
		"prime":
			return R.cel(R.v([-22,-6, 22,-6, 26,5, 8,17, -8,17, -26,5]), p.dark, p.dark_s) + R.accent(R.v([-14,3, 0,12, 14,3]), p.accent, 2.2)
		_:
			return R.cel(R.v([-24,-6, 24,-6, 30,5, 14,10, 8,17, -8,17, -14,10, -30,5]), p.armor, p.armor_s) + R.accent(R.v([-14,2, 14,2]), p.second, 2.6)

# ── Piernas ───────────────────────────────────────────────────────────────────

static func thigh(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-15,-4, 15,-4, 16,36, 11,46, -11,46, -16,36]), p.second, p.second_s)
		"prime":
			return R.cel(R.v([-14,-4, 14,-4, 15,36, 10,46, -10,46, -15,36]), p.second, p.second_s) + R.cel(R.v([-8,6, 8,6, 7,30, -7,30]), p.dark, p.dark_s, 1.8)
		_:
			return R.cel(R.v([-15,-4, 14,-4, 17,14, 13,26, 16,36, 10,46, -11,46, -16,34, -13,22, -17,10]), p.joint, p.dark)


static func shin(skin: String, p: Dictionary) -> String:
	var s := ""
	match skin:
		"g1":
			s += R.cel(R.v([-18,0, 18,0, 22,34, 18,50, -18,50, -22,34]), p.armor, p.armor_s)
			s += R.cel(R.v([-14,-8, 14,-8, 14,8, 0,14, -14,8]), p.second, p.second_s, 2.2)
			s += R.cel(R.v([-10,24, 10,24, 10,40, -10,40]), p.dark, p.dark_s, 1.8)
		"prime":
			s += R.cel(R.v([-15,0, 15,0, 22,26, 15,50, -15,50, -20,26]), p.armor, p.armor_s)
			s += R.cel(R.v([-13,-12, 13,-6, 14,8, 0,15, -14,8]), p.second, p.second_s, 2.2)
			s += R.accent(R.v([-5,24, -3,44]), p.accent, 2.4)
			s += R.accent(R.v([5,24, 3,44]), p.accent, 2.4)
		_:
			s += R.cel(R.v([-17,0, 17,0, 23,14, 17,26, 22,38, 16,50, -16,50, -23,36, -17,24, -23,12]), p.armor, p.armor_s)
			s += R.cel(R.v([-13,-8, 4,-11, 14,-3, 10,9, -3,14, -14,6]), p.joint, p.dark, 2.2)
			s += R.accent(R.v([-8,28, 8,28]), p.second, 3.0)
	return s


static func foot(skin: String, p: Dictionary) -> String:
	match skin:
		"g1":
			return R.cel(R.v([-18,-6, 17,-6, 34,6, 34,14, -20,14, -20,4]), p.dark, p.dark_s) + R.accent(R.v([16,9, 30,9]), p.second, 2.0)
		"prime":
			return R.cel(R.v([-16,-6, 15,-6, 36,9, 34,14, -18,14, -18,4]), p.dark, p.dark_s) + R.accent(R.v([-9,9, 22,9]), p.second, 2.2)
		_:
			return R.cel(R.v([-17,-6, 16,-6, 24,3, 38,9, 34,14, 14,11, 7,14, -20,14, -19,4]), p.dark, p.dark_s) + R.accent(R.v([18,7, 32,10]), p.joint, 2.0)

# ── Brazos ────────────────────────────────────────────────────────────────────

static func shoulder(skin: String, p: Dictionary, s: float) -> String:
	var m: bool = s < 0.0
	match skin:
		"g1":
			var o := R.cel(R.v([-18,-15, 19,-15, 21,14, -18,16], m), p.armor, p.armor_s)
			return o + R.accent(R.v([-12,-7, 14,-7], m), p.second, 2.8)
		"prime":
			var o := R.cel(R.v([-14,16, -22,-4, -14,-24, 16,-20, 24,-4, 16,16], m), p.armor, p.armor_s)
			return o + R.accent(R.v([-9,-12, 14,-10], m), p.accent, 2.4)
		_:
			var o := R.cel(R.v([-16,16, -24,-4, -18,-12, -14,-24, 16,-24, 20,-12, 26,-4, 18,16], m), p.armor, p.armor_s)
			o += R.accent(R.v([-14,-15, 15,-15], m), p.second, 3.0)
			return o + R.accent(R.v([-13,4, 15,4], m), p.joint, 2.0)


static func upper_arm(p: Dictionary) -> String:
	return R.cel(R.v([-10,-2, 10,-2, 10,30, -10,30]), p.joint, p.dark_s, 2.8)


## Brazo libre: la mano varía mucho entre versiones.
static func fist_arm(skin: String, p: Dictionary) -> String:
	var f := ""
	var hand := ""
	match skin:
		"g1":
			f += R.cel(R.v([-13,0, 13,0, 16,24, 13,38, -13,38, -16,24]), p.second, p.second_s)
			hand += R.cel(R.v([-12,0, 12,0, 14,10, 10,19, -10,19, -14,10]), p.armor, p.armor_s, 2.4)
		"prime":
			f += R.cel(R.v([-12,0, 12,0, 17,20, 12,38, -12,38, -17,20]), p.armor, p.armor_s)
			hand += R.cel(R.v([-11,0, 11,0, 13,9, 9,15, -9,15, -13,9]), p.dark, p.dark_s, 2.2)
			for x in [-9, -3, 3, 9]:
				hand += R.shape(R.path(R.v([x - 2.5,14, x + 2.5,14, x,28])), R.hex(p.second), 1.4)
		_:
			f += R.cel(R.v([-13,0, 13,0, 18,12, 13,22, 17,32, 13,38, -13,38, -17,28, -13,18, -18,8]), p.armor, p.armor_s)
			f += R.accent(R.v([-6,8, -4,32]), p.second, 2.6)
			hand += R.cel(R.v([-12,0, 12,0, 14,9, 10,15, -10,15, -14,9]), p.joint, p.dark, 2.2)
			for x in [-10, 0, 10]:
				hand += R.shape(R.path(R.v([x - 3,14, x + 3,14, x,30])), R.hex(p.dark), 1.6)
	return f + R.joint(Vector2(0, 38), 0.0, hand)


## El brazo-cañón: sin mano, con la boca en y≈80.
static func gun(skin: String, p: Dictionary, charge: float) -> String:
	var c := ""
	match skin:
		"g1":
			# Cañón grueso y cuadrado con aros morados.
			c += R.cel(R.v([-15,0, 15,0, 17,36, -17,36]), p.second, p.second_s)
			c += R.cel(R.v([-11,34, 11,34, 11,72, -11,72]), p.dark, p.dark_s, 2.4)
			for y in [42, 56]:
				c += R.cel(R.v([-14,y, 14,y, 14,y + 6, -14,y + 6]), p.armor, p.armor_s, 1.8)
			c += R.cel(R.v([-15,70, 15,70, 18,80, -18,80]), p.second, p.second_s, 2.2)
		"prime":
			# Dos raíles paralelos con la energía entre ellos.
			c += R.cel(R.v([-14,0, 14,0, 18,18, 14,38, -14,38, -18,18]), p.armor, p.armor_s)
			c += R.cel(R.v([-13,34, -5,34, -5,80, -13,74]), p.dark, p.dark_s, 2.2)
			c += R.cel(R.v([13,34, 5,34, 5,80, 13,74]), p.dark, p.dark_s, 2.2)
			c += R.accent(R.v([0,40, 0,76]), p.energy, 3.2)
			c += R.cel(R.v([-14,48, 14,48, 14,54, -14,54]), p.second, p.second_s, 1.6)
		_:
			# Cañón de anillos, muy ancho, con cables.
			c += R.cel(R.v([-16,0, 16,0, 20,14, 16,26, 20,38, -20,38, -16,26, -20,14]), p.armor, p.armor_s)
			c += R.accent(R.v([-8,6, -10,34]), p.second, 3.0)
			for k in 3:
				var y: int = 36 + k * 14
				c += R.cel(R.v([-17 + k,y, 17 - k,y, 15 - k,y + 12, -15 + k,y + 12]), p.dark if k % 2 == 0 else p.armor, p.dark_s, 2.2)
			c += R.cel(R.v([-14,74, 14,74, 16,80, -16,80]), p.joint, p.dark, 2.0)
	if charge > 0.01:
		c += R.circle(0, 80, 16.0 + 12.0 * charge, "url(#e_glow)", 0.0, charge)
	return c

# ── Cañón láser ───────────────────────────────────────────────────────────────
# El eje del cañón es y=112 y la boca está en x≈290 (a 50 px del origen en el juego).

static func cannon_parts(skin: String) -> Dictionary:
	var p: Dictionary = SKINS[skin]
	var q := {"under": "", "body": "", "barrel": "", "top": ""}
	match skin:
		"g1":
			# Pistola espacial: empuñadura, guardamonte, cuerpo y cañón largo con mira.
			q.under += R.cel(R.v([60,126, 104,126, 88,200, 44,194]), p.armor, p.armor_s)
			q.under += R.accent(R.v([62,150, 92,154]), p.dark, 2.6)
			q.under += R.accent(R.v([62,168, 88,172]), p.dark, 2.6)
			q.under += R.accent(R.v([110,132, 112,158, 140,158, 146,134]), p.second_s, 4.0)
			q.body += R.cel(R.v([26,84, 176,82, 186,94, 186,134, 26,136]), p.second, p.second_s)
			q.body += R.cel(R.v([40,94, 166,92, 166,126, 40,128]), p.armor, p.armor_s, 2.2)
			q.body += R.circle(70, 110, 12.0, R.hex(p.dark), 2.2) + R.circle(70, 110, 6.0, R.hex(p.energy))
			q.body += R.accent(R.v([96,104, 156,102]), p.second, 3.0)
			q.body += R.accent(R.v([96,116, 156,114]), p.second, 3.0)
			q.barrel += R.cel(R.v([184,98, 282,100, 282,124, 184,126]), p.dark, p.dark_s)
			for x in [200, 226, 252]:
				q.barrel += R.cel(R.v([x,94, x + 12,94, x + 12,130, x,130]), p.armor, p.armor_s, 2.0)
			q.barrel += R.cel(R.v([276,92, 296,88, 296,136, 276,132]), p.second, p.second_s, 2.4)
			q.top += R.cel(R.v([104,82, 118,66, 170,66, 176,82]), p.second, p.second_s, 2.4)
			q.top += R.cel(R.v([164,70, 178,70, 178,78, 164,78]), p.eye, p.eye.darkened(0.3), 1.6)
		"prime":
			# Artillería flotante: dos raíles largos, aletas y motores detrás.
			q.under += R.cel(R.v([60,132, 150,130, 110,182, 40,176]), p.armor, p.armor_s)
			q.under += R.accent(R.v([74,146, 56,168]), p.accent, 2.6)
			q.under += R.cel(R.v([18,126, 36,126, 36,146, 18,146]), p.dark_s, p.dark_s, 2.2)
			q.body += R.cel(R.v([22,92, 70,74, 170,76, 196,96, 196,128, 170,148, 70,150, 22,132]), p.armor, p.armor_s)
			q.body += R.cel(R.v([70,92, 160,92, 176,106, 160,132, 70,132]), p.second, p.second_s, 2.4)
			q.body += R.cel(R.v([96,100, 150,100, 160,112, 150,124, 96,124]), p.dark, p.dark_s, 1.8)
			q.body += R.accent(R.v([104,112, 148,112]), p.energy, 3.6)
			q.barrel += R.cel(R.v([190,84, 292,94, 292,104, 190,104]), p.dark, p.dark_s, 2.6)
			q.barrel += R.cel(R.v([190,120, 292,120, 292,130, 190,140]), p.dark, p.dark_s, 2.6)
			q.barrel += R.accent(R.v([196,112, 288,112]), p.energy, 3.4)
			for x in [214, 256]:
				q.barrel += R.cel(R.v([x,90, x + 10,90, x + 10,134, x,134]), p.second, p.second_s, 1.8)
			q.top += R.cel(R.v([60,80, 110,76, 76,38, 44,44]), p.armor, p.armor_s)
			q.top += R.accent(R.v([66,72, 58,50]), p.accent, 2.4)
			q.top += R.flat(R.path(R.v([176,92, 192,104, 176,108])), R.hex(p.eye))
		_:
			# Cañón pesado: bloque blindado, anillos, cables y cuchillas de sujeción.
			q.under += R.cel(R.v([30,132, 66,134, 50,190, 22,176]), p.armor, p.armor_s)
			q.under += R.cel(R.v([86,136, 124,136, 118,196, 90,186]), p.armor, p.armor_s)
			q.under += R.accent(R.v([60,136, 96,168, 150,136]), p.second, 4.0)
			q.body += R.cel(R.v([14,92, 38,72, 150,72, 176,88, 176,136, 150,152, 38,152, 14,132]), p.armor, p.armor_s)
			q.body += R.cel(R.v([44,88, 142,88, 142,136, 44,136]), p.dark, p.dark_s, 2.2)
			q.body += R.circle(92, 112, 18.0, R.hex(p.second), 2.4) + R.circle(92, 112, 10.0, R.hex(p.energy)) + R.circle(89, 109, 3.0, "#ffffff")
			q.body += R.accent(R.v([46,80, 140,80]), p.second, 3.0)
			q.body += R.accent(R.v([46,144, 140,144]), p.second, 3.0)
			for k in 4:
				var x: int = 176 + k * 28
				var h: int = 30 - k * 3
				q.barrel += R.cel(R.v([x,112 - h, x + 26,112 - h + 2, x + 26,112 + h - 2, x,112 + h]), p.dark if k % 2 == 0 else p.armor, p.dark_s, 2.4)
			q.barrel += R.cel(R.v([286,92, 298,90, 298,134, 286,132]), p.joint, p.dark, 2.2)
			q.barrel += R.accent(R.v([180,84, 280,94]), p.second, 2.6)
			q.top += R.cel(R.v([70,72, 84,44, 132,44, 140,72]), p.armor, p.armor_s)
			q.top += R.flat(R.path(R.v([120,52, 130,52, 134,66, 122,66])), R.hex(p.eye))
	return q


## Resplandor en la boca (x=296, y=112): crece con la carga.
static func _muzzle_glow(charge: float) -> String:
	return R.circle(296, 112, 16.0 + 18.0 * charge, "url(#e_glow)", 0.0, 0.4 + 0.5 * charge)


static func vehicle(D, skin: String, pose: Dictionary = {}, k: float = 1.0) -> Image:
	var r = C.canvas(D, skin)
	var q: Dictionary = cannon_parts(skin)
	r.add(q.under + q.top + q.barrel + q.body)
	r.add(_muzzle_glow(pose.get("charge", 0.3)))
	return r.render_scaled(k)


## Fotograma de robot → cañón (t de 0 a 1): el robot se encoge hacia el centro mientras el
## cuerpo del cañón crece a su alrededor y el cañón sale hacia delante.
static func morph(D, skin: String, t: float, k: float = 1.0) -> Image:
	var p: Dictionary = SKINS[skin]
	var r = C.canvas(D, skin)
	var q: Dictionary = cannon_parts(skin)
	var shrink: float = C.smooth(t / 0.6)
	var body: float = C.smooth((t - 0.2) / 0.45)
	var barrel: float = C.smooth((t - 0.5) / 0.45)
	var robot_op: float = 1.0 - C.smooth((t - 0.45) / 0.3)
	var center := Vector2(150, 112)
	if barrel > 0.0:
		r.add(R.scaled(Vector2(176, 112), barrel, lerpf(0.6, 1.0, barrel), q.barrel))
		r.add(R.scaled(Vector2(100, 130), 1.0, barrel, q.under))
		r.add(R.scaled(Vector2(100, 80), 1.0, barrel, q.top))
	if robot_op > 0.0:
		var figure: String = C.robot_svg(D, skin, {
			"no_shadow": true,
			"crouch": shrink * 20.0,
			"near_foot": NEAR_FOOT.lerp(Vector2(140, 212), shrink),
			"far_foot": FAR_FOOT.lerp(Vector2(162, 212), shrink),
			"gun_sh": lerpf(-16.0, -82.0, shrink),
			"gun_el": lerpf(-12.0, -8.0, shrink),
			"fist_sh": lerpf(8.0, 3.0, shrink),
			"fist_el": lerpf(8.0, 2.0, shrink),
			"charge": 0.3,
		})
		var s: float = lerpf(1.0, 0.55, shrink)
		r.add(R.faded(robot_op, R.scaled(center, s, s, figure)))
	if body > 0.0:
		r.add(R.faded(C.smooth(body * 2.0), R.scaled(center, lerpf(0.4, 1.0, body), lerpf(0.4, 1.0, body), q.body)))
	C.energy_arcs(r, p, center, t)
	return r.render_scaled(k)
