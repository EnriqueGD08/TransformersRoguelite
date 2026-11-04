# starscream_art.gd
# Herramienta de desarrollo: diseño procedural de Starscream (robot con rifle y jet F-22).
# SRP: solo define cómo se DIBUJA Starscream; no sabe de SpriteFrames.
# Coordenadas de dibujo: 80x80 (pies en y=77). Lienzo real 144x96 con margen.
# La punta del rifle queda en (88, 38) en coordenadas de dibujo.

extends RefCounted

const P := preload("res://tools/art/painter.gd")

const CANVAS := Vector2i(144, 96)
const SHIFT := Vector2i(32, 16)

# detail: 0 = limpio (G1), 1 = costuras luminosas (Prime), 2 = desgaste (Bay).
const SKINS := {
	"g1": {
		"white": Color("e4e8f0"), "grey": Color("8c95a6"), "red": Color("d8372a"),
		"blue": Color("2e3f78"), "dark": Color("2c303c"), "eye": Color("ff3535"),
		"glass": Color("ffcf6e"), "glow": Color("7fe8ff"), "flame": Color("58b6ff"),
		"grain": 0.0, "detail": 0, "seed": 31,
	},
	"prime": {
		"white": Color("a6adbb"), "grey": Color("565e6e"), "red": Color("b32436"),
		"blue": Color("2a2f4f"), "dark": Color("1f222b"), "eye": Color("ff4757"),
		"glass": Color("ff9a52"), "glow": Color("ff6a7d"), "flame": Color("ff7a3a"),
		"grain": 0.06, "detail": 1, "seed": 32,
	},
	"bay": {
		"white": Color("8f95a1"), "grey": Color("525963"), "red": Color("8d2f26"),
		"blue": Color("2a3347"), "dark": Color("1b1d23"), "eye": Color("ff6a3d"),
		"glass": Color("c98a3d"), "glow": Color("9fd8ff"), "flame": Color("5a9fe0"),
		"grain": 0.16, "detail": 2, "seed": 33,
	},
}


static func _new(pal: Dictionary) -> RefCounted:
	var p = P.new(CANVAS.x, CANVAS.y, SHIFT.x, SHIFT.y)
	p.grain = pal.grain
	p.seed_val = pal.seed
	return p


static func _wear(p, rect: Rect2i, amount: float) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var r: float = p._hash(x + 41, y + 13)
			var a: Color = p.img.get_pixel(x + p.tx, y + p.ty)
			if a.a < 0.9:
				continue
			if r > 1.0 - amount * 0.5:
				p.px(x, y, a.lightened(0.28))
				p.px(x + 1, y + 1, a.lightened(0.16))
			elif r < amount * 0.25:
				p.px(x, y, Color("6b3a1e"))


# ── ROBOT ─────────────────────────────────────────────────────────────────────
# pose: bob, lean, kneel, stride, recoil, flash, wing (0..2), dead

static func robot(pal: Dictionary, pose: Dictionary = {}) -> RefCounted:
	var p = _new(pal)
	var ox: int = pose.get("lean", 0)
	var oy: int = pose.get("bob", 0) + pose.get("kneel", 0)
	var stride: int = pose.get("stride", 0)
	var rc: int = -pose.get("recoil", 0)
	var flash: float = pose.get("flash", 0.0)
	var wing: int = pose.get("wing", 0)
	var detail: int = pal.detail
	var eye: Color = Color("33262a") if pose.get("dead", false) else pal.eye
	var glass_light: Color = pal.glass.lightened(0.45)
	var glass_dark: Color = pal.glass.darkened(0.45)

	p.ellipse_px(40, 77, 20, 3, Color(0, 0, 0, 0.35))

	# Alas (detrás del cuerpo)
	for side in [-1, 1]:
		var pts: Array = []
		for v in [Vector2(27, 26), Vector2(9, 11 - wing), Vector2(-1, 6 - wing), Vector2(5, 22), Vector2(21, 40), Vector2(27, 40)]:
			pts.append(Vector2(40.0 + side * (40.0 - v.x) + ox, v.y + oy))
		if side == 1:
			pts.reverse()
		p.begin(); p.m_poly(pts); p.end(pal.grey)
		var tip_a := Vector2(40.0 + side * (40.0 - 1.0) + ox, 6.0 - wing + oy)
		p.poly_px([tip_a, tip_a + Vector2(-side * 8, 1), tip_a + Vector2(-side * 5, 8)], pal.red)
		p.line_px(Vector2(40.0 + side * 31.0 + ox, 14 + oy), Vector2(40.0 + side * 17.0 + ox, 36 + oy), pal.dark)

	# Piernas
	for side in [-1, 1]:
		var s: int = stride * side
		var lx: int = 40 + side * 6 + s * 3
		var ly: int = -2 if s > 0 else 0
		p.begin(); p.m_rect(lx - 4, 52 + ly, 8, 10); p.end(pal.blue)
		p.begin(); p.m_ellipse(lx, 62 + ly, 4.0, 3.2); p.end(pal.white)
		p.begin(); p.m_rect(lx - 3, 64 + ly, 7, 9); p.end(pal.grey)
		p.rect(lx - 3, 67 + ly, 7, 2, pal.red)
		p.begin()
		p.m_poly([Vector2(lx - 5, 72 + ly), Vector2(lx + 3, 72 + ly), Vector2(lx + 8, 75 + ly),
			Vector2(lx + 8, 77 + ly), Vector2(lx - 5, 77 + ly)])
		p.end(pal.dark)
		if detail == 1:
			p.line_px(Vector2(lx - 2, 53 + ly), Vector2(lx - 2, 60 + ly), pal.glow)
		elif detail == 2:
			_wear(p, Rect2i(lx - 4, 52 + ly, 9, 25), 0.1)

	# Cadera
	p.begin(); p.m_rect(31, 49, 18, 6); p.end(pal.dark)
	p.rect(38, 50, 4, 3, pal.red)

	# Brazo trasero
	p.begin(); p.m_line(Vector2(24 + ox, 32 + oy), Vector2(21 + ox, 49 + oy), 6); p.end(pal.grey)
	p.rect(19 + ox, 40 + oy, 5, 1, pal.dark)
	p.begin(); p.m_ellipse(21 + ox, 52 + oy, 4.2, 4.0); p.end(pal.white)

	# Torso
	p.begin()
	p.m_poly([Vector2(27 + ox, 25 + oy), Vector2(53 + ox, 25 + oy), Vector2(50 + ox, 50 + oy), Vector2(30 + ox, 50 + oy)])
	p.end(pal.white)
	p.poly_px([Vector2(32 + ox, 27 + oy), Vector2(48 + ox, 27 + oy), Vector2(46 + ox, 38 + oy), Vector2(34 + ox, 38 + oy)], pal.glass)  # cabina
	p.rect(32 + ox, 27 + oy, 16, 1, glass_light)
	p.rect(34 + ox, 37 + oy, 12, 1, glass_dark)
	p.line_px(Vector2(34 + ox, 36 + oy), Vector2(40 + ox, 29 + oy), Color(1, 1, 1, 0.85))
	p.line_px(Vector2(38 + ox, 36 + oy), Vector2(43 + ox, 30 + oy), Color(1, 1, 1, 0.6))
	p.line_px(Vector2(40 + ox, 27 + oy), Vector2(40 + ox, 37 + oy), pal.dark)
	p.rect(30 + ox, 39 + oy, 20, 2, pal.red)                                     # franja roja
	p.begin(); p.m_rect(32 + ox, 42 + oy, 16, 8); p.end(pal.grey)               # abdomen
	for ay in [44, 46, 48]:
		p.rect(33 + ox, ay + oy, 14, 1, pal.dark)
	if detail == 1:
		p.line_px(Vector2(28 + ox, 27 + oy), Vector2(31 + ox, 49 + oy), pal.glow)
		p.line_px(Vector2(52 + ox, 27 + oy), Vector2(49 + ox, 49 + oy), pal.glow)
	elif detail == 2:
		p.line_px(Vector2(36 + ox, 42 + oy), Vector2(36 + ox, 50 + oy), pal.dark)
		_wear(p, Rect2i(27 + ox, 25 + oy, 26, 26), 0.12)

	# Tomas de aire en los hombros
	for sx in [14, 54]:
		p.begin(); p.m_rect(sx + ox, 24 + oy, 12, 13); p.end(pal.grey)
		p.rect(sx + 2 + ox, 27 + oy, 8, 8, pal.dark)
		p.rect(sx + 3 + ox, 28 + oy, 6, 1, pal.grey.lightened(0.2))
		p.rect(sx + 3 + ox, 31 + oy, 6, 1, pal.grey.lightened(0.2))
		p.rect(sx + ox, 24 + oy, 12, 2, pal.red)

	# Cabeza con cresta
	p.begin(); p.m_rect(37 + ox, 20 + oy, 6, 5); p.end(pal.dark)
	p.begin()
	p.m_poly([Vector2(34 + ox, 6 + oy), Vector2(46 + ox, 6 + oy), Vector2(48 + ox, 11 + oy),
		Vector2(47 + ox, 20 + oy), Vector2(33 + ox, 20 + oy), Vector2(32 + ox, 11 + oy)])
	p.end(pal.white)
	p.poly_px([Vector2(37 + ox, 6 + oy), Vector2(40 + ox, -4 + oy), Vector2(43 + ox, 6 + oy)], pal.white)    # cresta
	p.poly_px([Vector2(39 + ox, -1 + oy), Vector2(40 + ox, -4 + oy), Vector2(41 + ox, -1 + oy)], pal.red)
	p.poly_px([Vector2(32 + ox, 11 + oy), Vector2(27 + ox, 2 + oy), Vector2(35 + ox, 8 + oy)], pal.grey)     # cuernos
	p.poly_px([Vector2(48 + ox, 11 + oy), Vector2(53 + ox, 2 + oy), Vector2(45 + ox, 8 + oy)], pal.grey)
	p.rect(34 + ox, 12 + oy, 12, 3, eye)                                          # visor
	p.rect(35 + ox, 12 + oy, 10, 1, Color(1, 0.88, 0.8) if not pose.get("dead", false) else eye)
	p.begin(); p.m_rect(35 + ox, 16 + oy, 10, 5); p.end(pal.grey)                  # máscara
	p.rect(36 + ox, 18 + oy, 8, 1, pal.dark)
	p.poly_px([Vector2(38 + ox, 20 + oy), Vector2(40 + ox, 24 + oy), Vector2(42 + ox, 20 + oy)], pal.grey)  # barbilla
	if detail == 2:
		_wear(p, Rect2i(32 + ox, 6 + oy, 16, 15), 0.1)

	# Brazo del rifle y Rayo Nulificador
	p.begin(); p.m_line(Vector2(56 + ox, 32 + oy), Vector2(62 + ox + rc, 40 + oy), 6); p.end(pal.grey)
	p.begin(); p.m_rect(58 + ox + rc, 35 + oy, 14, 7); p.end(pal.dark)            # cuerpo del rifle
	p.rect(60 + ox + rc, 34 + oy, 7, 2, pal.red)                                  # mira
	p.begin(); p.m_rect(72 + ox + rc, 37 + oy, 13, 3); p.end(pal.white)           # cañón largo
	p.rect(76 + ox + rc, 36 + oy, 2, 5, pal.dark)
	p.rect(81 + ox + rc, 36 + oy, 2, 5, pal.dark)
	p.begin(); p.m_rect(84 + ox + rc, 35 + oy, 5, 6); p.end(pal.dark)             # boca
	p.rect(85 + ox + rc, 37 + oy, 3, 2, pal.glow)
	p.begin(); p.m_ellipse(62 + ox + rc, 41 + oy, 4.0, 3.6); p.end(pal.white)     # mano
	if detail == 1:
		p.line_px(Vector2(72 + ox + rc, 38 + oy), Vector2(84 + ox + rc, 38 + oy), pal.glow)
	elif detail == 2:
		_wear(p, Rect2i(58 + ox + rc, 34 + oy, 31, 8), 0.12)

	p.outline()

	if not pose.get("dead", false):
		for gx in range(33, 47):
			p.px(gx + ox, 11 + oy, Color(pal.eye.r, pal.eye.g, pal.eye.b, 0.22))
			p.px(gx + ox, 15 + oy, Color(pal.eye.r, pal.eye.g, pal.eye.b, 0.22))
	if flash > 0.0:
		var mx := 91 + ox + rc
		var my := 38 + oy
		p.ellipse_px(mx + 2, my, 7 * flash + 2, 5 * flash + 1, Color(pal.glow.r, pal.glow.g, pal.glow.b, 0.5))
		p.poly_px([Vector2(mx, my - 3), Vector2(mx + 15 * flash, my), Vector2(mx, my + 3)], Color(0.8, 0.97, 1.0, 0.95))
		p.poly_px([Vector2(mx - 2, my - 1), Vector2(mx + 9 * flash, my), Vector2(mx - 2, my + 1)], Color.WHITE)
	return p


# ── JET F-22 ──────────────────────────────────────────────────────────────────
# pose: bob, flame (0..1), recoil, flash, lines (bool), bank (0 o 1: alas inclinadas)

static func jet(pal: Dictionary, pose: Dictionary = {}) -> RefCounted:
	var p = _new(pal)
	var oy: int = pose.get("bob", 0) - 6
	var rc: int = -pose.get("recoil", 0)
	var flash: float = pose.get("flash", 0.0)
	var flame: float = pose.get("flame", 0.5)
	var detail: int = pal.detail
	var glass_light: Color = pal.glass.lightened(0.45)
	var glass_dark: Color = pal.glass.darkened(0.45)

	# Sombra en el suelo (el jet vuela)
	p.ellipse_px(40, 77, 28, 3, Color(0, 0, 0, 0.3))

	# Ala lejana y estabilizador lejano (más oscuros)
	p.begin(); p.m_poly([Vector2(30, 40 + oy), Vector2(46, 40 + oy), Vector2(38, 28 + oy), Vector2(22, 29 + oy)]); p.end(pal.grey.darkened(0.2))
	p.begin(); p.m_poly([Vector2(13, 38 + oy), Vector2(20, 38 + oy), Vector2(16, 24 + oy), Vector2(9, 25 + oy)]); p.end(pal.grey.darkened(0.15))

	# Fuselaje
	p.begin()
	p.m_poly([Vector2(5, 44 + oy), Vector2(14, 38 + oy), Vector2(40, 35 + oy), Vector2(60, 38 + oy),
		Vector2(80, 46 + oy), Vector2(62, 51 + oy), Vector2(36, 53 + oy), Vector2(10, 51 + oy)])
	p.end(pal.white)
	p.begin(); p.m_poly([Vector2(62, 38 + oy), Vector2(80, 46 + oy), Vector2(62, 51 + oy), Vector2(66, 44 + oy)]); p.end(pal.dark)  # morro
	p.rect(10, 47 + oy, 50, 2, pal.red)                                          # franja roja
	p.rect(10, 49 + oy, 52, 1, pal.blue)
	# Cabina
	p.poly_px([Vector2(44, 36 + oy), Vector2(56, 37 + oy), Vector2(65, 44 + oy), Vector2(46, 43 + oy)], pal.glass)
	p.line_px(Vector2(45, 37 + oy), Vector2(56, 38 + oy), glass_light)
	p.line_px(Vector2(47, 43 + oy), Vector2(64, 44 + oy), glass_dark)
	p.line_px(Vector2(49, 41 + oy), Vector2(54, 38 + oy), Color(1, 1, 1, 0.85))
	p.line_px(Vector2(52, 41 + oy), Vector2(56, 39 + oy), Color(1, 1, 1, 0.55))
	p.line_px(Vector2(52, 36 + oy), Vector2(52, 43 + oy), pal.dark)
	# Toma de aire
	p.begin(); p.m_poly([Vector2(36, 44 + oy), Vector2(46, 45 + oy), Vector2(44, 51 + oy), Vector2(34, 51 + oy)]); p.end(pal.dark)
	p.rect(37, 46 + oy, 6, 1, pal.grey)

	# Ala cercana (barrida hacia abajo, perspectiva)
	p.begin(); p.m_poly([Vector2(26, 48 + oy), Vector2(48, 48 + oy), Vector2(37, 70 + oy), Vector2(12, 66 + oy)]); p.end(pal.grey)
	p.poly_px([Vector2(14, 63 + oy), Vector2(37, 68 + oy), Vector2(35, 70 + oy), Vector2(12, 66 + oy)], pal.red)
	p.line_px(Vector2(30, 52 + oy), Vector2(22, 64 + oy), pal.dark)
	p.line_px(Vector2(40, 52 + oy), Vector2(32, 66 + oy), pal.dark)

	# Derivas gemelas y estabilizador cercano
	p.begin(); p.m_poly([Vector2(5, 44 + oy), Vector2(14, 40 + oy), Vector2(10, 20 + oy), Vector2(2, 22 + oy)]); p.end(pal.white)
	p.poly_px([Vector2(2, 22 + oy), Vector2(10, 20 + oy), Vector2(9, 25 + oy), Vector2(3, 27 + oy)], pal.red)
	p.poly_px([Vector2(5, 33 + oy), Vector2(9, 32 + oy), Vector2(8, 38 + oy), Vector2(5, 39 + oy)], pal.glow.darkened(0.2) if detail == 1 else pal.dark)
	p.begin(); p.m_poly([Vector2(10, 50 + oy), Vector2(24, 50 + oy), Vector2(14, 60 + oy), Vector2(4, 57 + oy)]); p.end(pal.grey)

	# Tobera y postquemador
	p.begin(); p.m_rect(1, 42 + oy, 6, 9); p.end(pal.dark)
	if detail == 1:
		p.line_px(Vector2(14, 45 + oy), Vector2(58, 45 + oy), pal.glow)
	elif detail == 2:
		_wear(p, Rect2i(2, 20 + oy, 80, 52), 0.1)

	p.outline()

	# Llama del postquemador (después del contorno para que brille)
	var fl: float = 7.0 + 12.0 * flame
	p.poly_px([Vector2(1, 43 + oy), Vector2(-fl, 46 + oy), Vector2(1, 49 + oy)], Color(pal.flame.r, pal.flame.g, pal.flame.b, 0.8))
	p.poly_px([Vector2(1, 44 + oy), Vector2(-fl * 0.62, 46 + oy), Vector2(1, 48 + oy)], Color(1, 0.95, 0.8, 0.95))
	p.ellipse_px(0, 46 + oy, 4, 4, Color(pal.flame.r, pal.flame.g, pal.flame.b, 0.25))
	if pose.get("lines", false):
		for i in 5:
			p.line_px(Vector2(-6 - fl * 0.4, 36 + i * 5 + oy), Vector2(-20 - fl * 0.6 - i * 2, 36 + i * 5 + oy), Color(1, 1, 1, 0.4))
	if flash > 0.0:
		var mx := 82 + rc
		var my := 46 + oy
		p.ellipse_px(mx + 2, my, 7 * flash + 2, 5 * flash + 1, Color(pal.glow.r, pal.glow.g, pal.glow.b, 0.5))
		p.poly_px([Vector2(mx, my - 3), Vector2(mx + 15 * flash, my), Vector2(mx, my + 3)], Color(0.8, 0.97, 1.0, 0.95))
		p.poly_px([Vector2(mx - 2, my - 1), Vector2(mx + 9 * flash, my), Vector2(mx - 2, my + 1)], Color.WHITE)
	return p
