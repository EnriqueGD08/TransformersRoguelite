# boss_cel.gd
# Los cuatro jefes en estilo cel. Comparten esqueleto corpulento; cada uno es una "skin"
# con su silueta y su arma (el tamaño en el juego lo da la escala de su escena):
#   brawl: combaticon tanque, verde oliva y naranja, torreta con cañón a la espalda → puñetazo.
#   devastator: el gigante de los constructicons, verde y morado, pala a la espalda → mazazo.
#   soundwave: azul y blanco, pecho de casete, cañón al hombro → disparo.
#   galvatron: gris y morado, corona y cañón enorme en el brazo → disparo.
# Solo define piezas: el esqueleto y las animaciones son comunes (cel_character, cel_anim).
# SRP: formas de los jefes. OCP: un jefe nuevo es una entrada más en SKINS y sus formas.

extends RefCounted

const R := preload("res://tools/art2/vector_rig.gd")
const C := preload("res://tools/art2/cel_character.gd")

const SKINS := {
	"brawl": {"armor": Color("6f7f3e"), "armor_s": Color("4a5626"), "second": Color("bf8c3c"), "second_s": Color("8a6424"),
		"dark": Color("2b2e33"), "dark_s": Color("1b1d21"), "joint": Color("6e737c"), "accent": Color("e8892a"),
		"eye": Color("ff4a2a"), "energy": Color("ffb04a"), "glass": Color("6ab0c8")},
	"devastator": {"armor": Color("5c9c3a"), "armor_s": Color("3e6f26"), "second": Color("6a3f8c"), "second_s": Color("482a62"),
		"dark": Color("2a2c32"), "dark_s": Color("1a1b20"), "joint": Color("7d828c"), "accent": Color("f2c230"),
		"eye": Color("ff3030"), "energy": Color("ffcf4a"), "glass": Color("6ab0c8")},
	"soundwave": {"armor": Color("3f5fa8"), "armor_s": Color("2a4277"), "second": Color("e2e5ec"), "second_s": Color("aab0be"),
		"dark": Color("26283a"), "dark_s": Color("181a27"), "joint": Color("7b8090"), "accent": Color("f2c230"),
		"eye": Color("ff2a2a"), "energy": Color("ffd060"), "glass": Color("f2c230")},
	"galvatron": {"armor": Color("c3cad6"), "armor_s": Color("8b93a3"), "second": Color("7c36ab"), "second_s": Color("55247a"),
		"dark": Color("2a2c38"), "dark_s": Color("1a1b24"), "joint": Color("6e7382"), "accent": Color("e2603a"),
		"eye": Color("ff3355"), "energy": Color("c86bff"), "glass": Color("6ab0c8")},
}

const THIGH := 44.0
const SHIN := 50.0
const HIP_Y := 122.0
const HIP_HALF := 15.0
const SHOULDER_X := 54.0
const SHOULDER_Y := -62.0
const NECK := Vector2(1, -74)
const NEAR_FOOT := Vector2(122, 212)
const FAR_FOOT := Vector2(180, 212)
const SHADOW_W := 80.0
const HALF_STRIDE := 30.0
const LIFT := 13.0
const WALK_CENTER := 152.0
const VEHICLE_RECOIL := 0.0
const VEHICLE_HOVER := 0.0

## El mazazo de Devastator cabe en el lienzo normal.
const SWING_TOP := -122.0
const TRAIL_RADIUS := 112.0


static func _decepticon(c: Vector2, k: float, col: Color) -> String:
	var pts := R.v([-9,-8, -4,-4, 4,-4, 9,-8, 8,0, 4,2, 2,9, 0,11, -2,9, -4,2, -8,0])
	var out := PackedVector2Array()
	for q in pts:
		out.append(c + q * k)
	return R.shape(R.path(out), R.hex(col), 1.4)

# ── Espalda ───────────────────────────────────────────────────────────────────

static func back(skin: String, p: Dictionary) -> String:
	match skin:
		"brawl":
			# Torreta de tanque con el cañón asomando por encima del hombro.
			var b := R.cel(R.v([12,-66, 50,-66, 56,-84, 18,-90]), p.armor, p.armor_s)
			b += R.cel(R.v([44,-86, 96,-108, 100,-100, 48,-78]), p.dark, p.dark_s, 2.4)
			return b + R.cel(R.v([94,-112, 104,-106, 100,-96, 92,-100]), p.second, p.second_s, 2.0)
		"devastator":
			# La pala de Scavenger por detrás, como una cresta.
			var b := R.cel(R.v([-46,-70, -20,-74, -30,-112, -64,-104]), p.second, p.second_s)
			for x in [-58, -48, -38]:
				b += R.shape(R.path(R.v([x,-106, x + 6,-108, x + 1,-120])), R.hex(p.joint), 1.6)
			return b
		"soundwave":
			# Cañón de hombro sobre el lado izquierdo.
			var b := R.cel(R.v([-46,-72, -24,-72, -24,-86, -46,-86]), p.dark, p.dark_s, 2.4)
			b += R.cel(R.v([-44,-92, 4,-96, 4,-84, -44,-82]), p.armor, p.armor_s, 2.4)
			return b + R.cel(R.v([2,-98, 12,-98, 12,-82, 2,-82]), p.second, p.second_s, 2.0)
		_:
			# Aletas altas en la espalda, como alas de la corona.
			var b := ""
			for s in [1, -1]:
				b += R.cel(R.v([-20,-64, -44,-108, -52,-100, -40,-56], s > 0), p.second, p.second_s)
			return b

# ── Cabeza ────────────────────────────────────────────────────────────────────

static func head(skin: String, p: Dictionary) -> String:
	var h := ""
	var face := Color("aeb4bf")
	match skin:
		"brawl":
			h += R.cel(R.v([-16,4, -17,-20, -10,-30, 10,-30, 17,-20, 16,4, 9,8, -9,8]), p.armor, p.armor_s)
			h += R.cel(R.v([-12,-18, 12,-18, 12,-9, -12,-9]), p.dark, p.dark_s, 1.8)
			h += R.flat(R.path(R.v([-10,-16, 10,-16, 10,-11, -10,-11])), R.hex(p.eye))
			h += R.cel(R.v([-9,-8, 9,-8, 7,5, -7,5]), face, face.darkened(0.3), 1.8)
			h += R.accent(R.v([-17,-24, -22,-32]), p.second, 3.0)
			h += R.accent(R.v([17,-24, 22,-32]), p.second, 3.0)
		"devastator":
			# Casco morado con cresta y visor rojo de lado a lado.
			h += R.cel(R.v([-18,4, -19,-18, -12,-30, 0,-40, 12,-30, 19,-18, 18,4, 9,8, -9,8]), p.second, p.second_s)
			h += R.cel(R.v([-15,-18, 15,-18, 14,-8, -14,-8]), p.dark, p.dark_s, 1.8)
			h += R.flat(R.path(R.v([-13,-16, 13,-16, 12,-11, -12,-11])), R.hex(p.eye))
			h += R.cel(R.v([-10,-7, 10,-7, 8,5, -8,5]), face, face.darkened(0.3), 1.8)
			for x in [-4, 0, 4]:
				h += R.accent(R.v([x,-4, x,3]), face.darkened(0.3), 1.3)
		"soundwave":
			# Casco azul con aletas a los lados, visor rojo y máscara gris.
			for s in [1, -1]:
				h += R.cel(R.v([s * 14,-6, s * 24,-14, s * 24,-34, s * 16,-28]), p.armor, p.armor_s, 2.2)
			h += R.cel(R.v([-15,4, -16,-20, -10,-32, 10,-32, 16,-20, 15,4, 9,8, -9,8]), p.armor, p.armor_s)
			h += R.cel(R.v([-12,-20, 12,-20, 12,-11, -12,-11]), p.dark, p.dark_s, 1.8)
			h += R.flat(R.path(R.v([-10,-18, 10,-18, 10,-13, -10,-13])), R.hex(p.eye))
			h += R.cel(R.v([-9,-10, 9,-10, 7,6, -7,6]), p.second, p.second_s, 1.8)
		_:
			# Corona de puntas, cara gris y ojos rojos.
			h += R.cel(R.v([-17,-14, -24,-44, -12,-30, -6,-48, 0,-34, 6,-48, 12,-30, 24,-44, 17,-14]), p.second, p.second_s)
			h += R.cel(R.v([-15,4, -16,-18, -10,-26, 10,-26, 16,-18, 15,4, 9,8, -9,8]), p.armor, p.armor_s)
			h += R.cel(R.v([-10,-18, 10,-18, 9,2, 0,7, -9,2]), face, face.darkened(0.3), 1.8)
			h += R.flat(R.path(R.v([-8,-15, -2,-12, -2,-9, -8,-11])), R.hex(p.eye))
			h += R.flat(R.path(R.v([8,-15, 2,-12, 2,-9, 8,-11])), R.hex(p.eye))
	return h

# ── Torso ─────────────────────────────────────────────────────────────────────

static func torso(skin: String, p: Dictionary) -> String:
	var t := ""
	match skin:
		"brawl":
			t += R.cel(R.v([-50,-74, 50,-74, 52,-42, 32,-26, 26,2, -26,2, -32,-26, -52,-42]), p.armor, p.armor_s)
			t += R.cel(R.v([-34,-68, 34,-68, 30,-44, 0,-34, -30,-44]), p.second, p.second_s, 2.4)
			t += _decepticon(Vector2(0, -54), 1.1, Color("6c3f8c"))
			t += R.cel(R.v([-24,-26, 24,-26, 22,2, -22,2]), p.dark, p.dark_s, 2.2)
			for k in 3:
				t += R.accent(R.v([-15,-20 + k * 7, 15,-20 + k * 7]), p.joint, 2.0)
		"devastator":
			# Pecho de excavadora: cabina amarilla y bloque verde con morado.
			t += R.cel(R.v([-56,-74, 56,-74, 58,-40, 34,-24, 28,2, -28,2, -34,-24, -58,-40]), p.armor, p.armor_s)
			t += R.cel(R.v([-30,-70, 30,-70, 28,-42, -28,-42]), p.second, p.second_s, 2.4)
			t += C.window(R.v([-24,-66, -3,-66, -3,-48, -22,-48]), {"glass": p.accent})
			t += C.window(R.v([3,-66, 24,-66, 22,-48, 3,-48]), {"glass": p.accent})
			t += R.cel(R.v([-26,-22, 26,-22, 24,2, -24,2]), p.second, p.second_s, 2.2)
			t += R.accent(R.v([-16,-11, 16,-11]), p.accent, 2.6)
		"soundwave":
			# Pletina de casete en el pecho, con su ventana amarilla y los botones.
			t += R.cel(R.v([-48,-74, 48,-74, 50,-40, 30,-24, 24,2, -24,2, -30,-24, -50,-40]), p.armor, p.armor_s)
			t += R.cel(R.v([-34,-68, 34,-68, 34,-38, -34,-38]), p.second, p.second_s, 2.4)
			t += R.cel(R.v([-28,-64, 28,-64, 28,-46, -28,-46]), p.accent, p.accent.darkened(0.3), 2.0)
			t += R.circle(-12, -55, 5.0, R.hex(p.dark), 1.6) + R.circle(12, -55, 5.0, R.hex(p.dark), 1.6)
			t += R.accent(R.v([-12,-55, 12,-55]), p.dark, 2.0)
			for x in [-24, -14, -4, 6, 16]:
				t += R.cel(R.v([x,-44, x + 8,-44, x + 8,-40, x,-40]), p.dark, p.dark_s, 1.2)
			t += R.cel(R.v([-22,-24, 22,-24, 20,2, -20,2]), p.dark, p.dark_s, 2.2)
		_:
			t += R.cel(R.v([-50,-76, -30,-82, 30,-82, 50,-76, 46,-44, 26,-26, 22,2, -22,2, -26,-26, -46,-44]), p.armor, p.armor_s)
			t += R.cel(R.v([-40,-70, -6,-70, -10,-40, -30,-46]), p.second, p.second_s, 2.2)
			t += R.cel(R.v([40,-70, 6,-70, 10,-40, 30,-46]), p.second, p.second_s, 2.2)
			t += _decepticon(Vector2(0, -50), 1.0, p.second)
			for k in 3:
				t += R.cel(R.v([-17 + k,-24 + k * 9, 17 - k,-24 + k * 9, 15 - k,-18 + k * 9, -15 + k,-18 + k * 9]), p.dark, p.dark_s, 1.6)
	return t


static func pelvis(skin: String, p: Dictionary) -> String:
	var main: Color = p.dark if skin != "galvatron" else p.second
	var main_s: Color = p.dark_s if skin != "galvatron" else p.second_s
	return R.cel(R.v([-26,-6, 26,-6, 30,5, 10,17, -10,17, -30,5]), main, main_s) + R.accent(R.v([-14,2, 0,11, 14,2]), p.accent, 2.4)

# ── Piernas ───────────────────────────────────────────────────────────────────

static func thigh(skin: String, p: Dictionary) -> String:
	var col: Color = p.second if skin in ["brawl", "soundwave", "galvatron"] else p.second
	var col_s: Color = p.second_s
	if skin == "brawl":
		col = p.armor
		col_s = p.armor_s
	return R.cel(R.v([-15,-4, 15,-4, 16,36, 11,44, -11,44, -16,36]), col, col_s)


static func shin(skin: String, p: Dictionary) -> String:
	var s := ""
	match skin:
		"brawl":
			# Orugas de tanque a lo largo de la pierna.
			s += R.cel(R.v([-19,0, 19,0, 23,34, 19,50, -19,50, -23,34]), p.armor, p.armor_s)
			s += R.cel(R.v([-15,10, 15,10, 15,44, -15,44]), p.dark, p.dark_s, 2.0)
			for y in [16, 23, 30, 37]:
				s += R.accent(R.v([-12,y, 12,y]), p.joint, 1.6)
			s += R.cel(R.v([-15,-8, 15,-8, 15,8, 0,13, -15,8]), p.second, p.second_s, 2.2)
		"devastator":
			s += R.cel(R.v([-20,0, 20,0, 24,30, 20,50, -20,50, -24,30]), p.armor, p.armor_s)
			s += R.cel(R.v([-16,-8, 16,-8, 16,8, 0,14, -16,8]), p.second, p.second_s, 2.2)
			s += R.circle(-12, 34, 9.0, "#20232a", 2.2) + R.circle(-12, 34, 4.0, R.hex(p.joint))
			s += R.accent(R.v([2,30, 16,30]), p.accent, 2.6)
		"soundwave":
			s += R.cel(R.v([-17,0, 17,0, 21,30, 17,50, -17,50, -21,30]), p.armor, p.armor_s)
			s += R.cel(R.v([-14,-8, 14,-8, 14,8, 0,13, -14,8]), p.second, p.second_s, 2.2)
			s += R.cel(R.v([-11,22, 11,22, 11,40, -11,40]), p.second, p.second_s, 1.8)
		_:
			s += R.cel(R.v([-16,0, 16,0, 22,26, 16,50, -16,50, -21,26]), p.armor, p.armor_s)
			s += R.cel(R.v([-14,-12, 14,-6, 15,8, 0,15, -15,8]), p.second, p.second_s, 2.2)
			s += R.accent(R.v([-6,24, -4,44]), p.second, 2.6)
			s += R.accent(R.v([6,24, 4,44]), p.second, 2.6)
	return s


static func foot(skin: String, p: Dictionary) -> String:
	return R.cel(R.v([-18,-6, 17,-6, 34,6, 34,14, -20,14, -20,4]), p.dark, p.dark_s) + R.accent(R.v([14,9, 30,9]), p.accent if skin != "galvatron" else p.second, 2.2)

# ── Brazos ────────────────────────────────────────────────────────────────────

static func shoulder(skin: String, p: Dictionary, s: float) -> String:
	var m: bool = s < 0.0
	match skin:
		"galvatron":
			var o := R.cel(R.v([-16,16, -22,-4, -14,-24, 16,-22, 24,-4, 16,16], m), p.armor, p.armor_s)
			return o + R.cel(R.v([-10,-16, 14,-14, 16,-6, -10,-6], m), p.second, p.second_s, 1.8)
		"devastator":
			var o := R.cel(R.v([-20,-16, 22,-16, 24,16, 16,20, -16,20, -22,12], m), p.second, p.second_s)
			return o + R.accent(R.v([-12,-8, 16,-8], m), p.accent, 2.8)
		_:
			var o := R.cel(R.v([-18,-15, 20,-15, 22,14, -18,16], m), p.armor, p.armor_s)
			return o + R.accent(R.v([-12,-7, 15,-7], m), p.second if skin == "soundwave" else p.accent, 2.8)


static func upper_arm(p: Dictionary) -> String:
	return R.cel(R.v([-10,-2, 10,-2, 10,30, -10,30]), p.joint, p.dark_s, 2.8)


static func _forearm(p: Dictionary) -> String:
	return R.cel(R.v([-14,0, 14,0, 17,24, 14,38, -14,38, -17,24]), p.armor, p.armor_s) + R.accent(R.v([-9,14, 9,14]), p.second, 2.4)


static func _fist(p: Dictionary, scale: float = 1.0) -> String:
	return R.scaled(Vector2(0, 0), scale, scale, R.cel(R.v([-12,0, 12,0, 14,10, 10,19, -10,19, -14,10]), p.dark, p.dark_s, 2.4))


static func fist_arm(_skin: String, p: Dictionary) -> String:
	return _forearm(p) + R.joint(Vector2(0, 38), 0.0, _fist(p))


## Arma de cada jefe; la boca o el punto de impacto queda en y≈80.
static func gun(skin: String, p: Dictionary, charge: float) -> String:
	var g := ""
	match skin:
		"brawl":
			# Guantelete enorme: el puñetazo es su ataque.
			g += R.cel(R.v([-17,0, 17,0, 21,30, 17,46, -17,46, -21,30]), p.armor, p.armor_s)
			g += R.cel(R.v([-14,20, 14,20, 14,30, -14,30]), p.accent, p.accent.darkened(0.3), 1.8)
			g += R.joint(Vector2(0, 44), 0.0, R.cel(R.v([-18,0, 18,0, 21,16, 15,32, -15,32, -21,16]), p.dark, p.dark_s, 2.6))
			for x in [-10, 0, 10]:
				g += R.accent(R.v([x,64, x,74]), p.joint, 2.0)
		"devastator":
			# Mazo de demolición sobre un brazo hidráulico.
			g += _forearm(p)
			g += R.cel(R.v([-5,36, 5,36, 5,64, -5,64]), p.joint, p.dark, 2.2)
			g += R.cel(R.v([-30,60, 30,60, 34,72, 30,90, -30,90, -34,72]), p.second, p.second_s)
			g += R.cel(R.v([-22,66, 22,66, 22,84, -22,84]), p.dark, p.dark_s, 1.8)
			g += R.accent(R.v([-18,75, 18,75]), p.accent, 3.0)
		"soundwave":
			# Pistola de concusión sujeta en la mano.
			g += _forearm(p) + R.joint(Vector2(0, 38), 0.0, _fist(p))
			g += R.cel(R.v([-8,46, 8,46, 9,76, 6,80, -6,80, -9,76]), p.accent, p.accent.darkened(0.35), 2.2)
			g += R.cel(R.v([-12,52, 12,52, 12,58, -12,58]), p.dark, p.dark_s, 1.6)
		_:
			# Cañón de brazo enorme, morado con franjas naranjas.
			g += R.cel(R.v([-18,0, 18,0, 22,36, -22,36]), p.armor, p.armor_s)
			g += R.cel(R.v([-15,32, 15,32, 15,74, -15,74]), p.second, p.second_s)
			for y in [42, 56]:
				g += R.cel(R.v([-17,y, 17,y, 17,y + 5, -17,y + 5]), p.accent, p.accent.darkened(0.3), 1.6)
			g += R.cel(R.v([-19,72, 19,72, 22,80, -22,80]), p.dark, p.dark_s, 2.2)
	if charge > 0.01 and skin != "brawl":
		g += R.circle(0, 80, 14.0 + 12.0 * charge, "url(#e_glow)", 0.0, charge)
	return g
