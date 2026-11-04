# megatron_art.gd
# Herramienta de desarrollo: diseño procedural de Megatron (robot con cañón y tanque).
# SRP: solo define cómo se DIBUJA Megatron; no sabe de SpriteFrames.
# Coordenadas de dibujo: 80x80 (pies en y=77). Lienzo real 144x96 con margen.
# La punta del cañón queda en (88, 38) en coordenadas de dibujo.

extends RefCounted

const P := preload("res://tools/art/painter.gd")

const CANVAS := Vector2i(144, 96)
const SHIFT := Vector2i(32, 16)

# detail: 0 = limpio (G1), 1 = costuras luminosas (Prime), 2 = desgaste (Bay).
const SKINS := {
	"g1": {
		"metal": Color("747d8c"), "dark": Color("3b404b"), "accent": Color("7a35a8"),
		"silver": Color("c5cbd6"), "eye": Color("ff2d2d"), "glow": Color("ff9a2e"),
		"grain": 0.0, "detail": 0, "seed": 21,
	},
	"prime": {
		"metal": Color("4c5361"), "dark": Color("262a33"), "accent": Color("5b2a8c"),
		"silver": Color("9aa3b3"), "eye": Color("ff3b3b"), "glow": Color("ff3a5a"),
		"grain": 0.06, "detail": 1, "seed": 22,
	},
	"bay": {
		"metal": Color("50555f"), "dark": Color("1d2026"), "accent": Color("44304f"),
		"silver": Color("737b89"), "eye": Color("ff6a3d"), "glow": Color("ff7a2a"),
		"grain": 0.16, "detail": 2, "seed": 23,
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
			var r: float = p._hash(x + 29, y + 7)
			var a: Color = p.img.get_pixel(x + p.tx, y + p.ty)
			if a.a < 0.9:
				continue
			if r > 1.0 - amount * 0.5:
				p.px(x, y, a.lightened(0.3))
				p.px(x + 1, y + 1, a.lightened(0.16))
			elif r < amount * 0.25:
				p.px(x, y, Color("6b3a1e"))


## Cara Decepticon (insignia). Centro (cx, cy), ancho aproximado 9.
static func _insignia(p, cx: int, cy: int, col: Color, eye: Color) -> void:
	p.poly_px([Vector2(cx - 5, cy - 4), Vector2(cx + 5, cy - 4), Vector2(cx + 4, cy + 2),
		Vector2(cx, cy + 6), Vector2(cx - 4, cy + 2)], col)
	p.poly_px([Vector2(cx - 6, cy - 4), Vector2(cx - 4, cy - 8), Vector2(cx - 2, cy - 4)], col)
	p.poly_px([Vector2(cx + 2, cy - 4), Vector2(cx + 4, cy - 8), Vector2(cx + 6, cy - 4)], col)
	p.rect(cx - 3, cy - 1, 2, 2, eye)
	p.rect(cx + 1, cy - 1, 2, 2, eye)
	p.rect(cx - 1, cy + 3, 2, 1, eye)


# ── ROBOT ─────────────────────────────────────────────────────────────────────
# pose: bob, lean, kneel, stride, recoil, flash (0..1), charge (0..1), dead

static func robot(pal: Dictionary, pose: Dictionary = {}) -> RefCounted:
	var p = _new(pal)
	var ox: int = pose.get("lean", 0)
	var oy: int = pose.get("bob", 0) + pose.get("kneel", 0)
	var stride: int = pose.get("stride", 0)
	var recoil: int = pose.get("recoil", 0)
	var flash: float = pose.get("flash", 0.0)
	var charge: float = pose.get("charge", 0.3)
	var detail: int = pal.detail
	var eye: Color = Color("33262a") if pose.get("dead", false) else pal.eye

	p.ellipse_px(40, 77, 24, 3.5, Color(0, 0, 0, 0.38))

	# Piernas
	for side in [-1, 1]:
		var s: int = stride * side
		var lx: int = 40 + side * 9 + s * 3
		var ly: int = -2 if s > 0 else 0
		p.begin(); p.m_rect(lx - 6, 52 + ly, 12, 11); p.end(pal.metal)
		p.rect(lx - 6, 56 + ly, 12, 2, pal.accent)
		p.poly_px([Vector2(lx - 1, 61 + ly), Vector2(lx + 7, 63 + ly), Vector2(lx - 1, 67 + ly)], pal.silver)  # pincho rodilla
		p.begin(); p.m_rect(lx - 5, 64 + ly, 10, 8); p.end(pal.dark)
		p.rect(lx - 5, 67 + ly, 10, 2, pal.metal)
		p.begin()
		p.m_poly([Vector2(lx - 7, 72 + ly), Vector2(lx + 4, 72 + ly), Vector2(lx + 9, 75 + ly),
			Vector2(lx + 9, 77 + ly), Vector2(lx - 7, 77 + ly)])
		p.end(pal.dark)
		p.rect(lx - 4, 74 + ly, 6, 1, pal.accent)
		if detail == 1:
			p.line_px(Vector2(lx - 4, 53 + ly), Vector2(lx - 4, 62 + ly), pal.glow.darkened(0.2))
		elif detail == 2:
			_wear(p, Rect2i(lx - 6, 52 + ly, 12, 25), 0.1)

	# Cadera
	p.begin(); p.m_rect(26, 49, 28, 7); p.end(pal.dark)
	p.rect(36, 51, 8, 3, pal.accent)

	# Brazo trasero (puño)
	p.begin(); p.m_line(Vector2(14 + ox, 32 + oy), Vector2(10 + ox, 50 + oy), 8); p.end(pal.metal)
	p.begin(); p.m_line(Vector2(11 + ox, 44 + oy), Vector2(9 + ox, 54 + oy), 8); p.end(pal.dark)
	p.begin(); p.m_ellipse(9 + ox, 57 + oy, 5.4, 5.0); p.end(pal.silver)
	p.rect(6 + ox, 57 + oy, 7, 1, pal.dark)

	# Torso
	p.begin()
	p.m_poly([Vector2(17 + ox, 25 + oy), Vector2(63 + ox, 25 + oy), Vector2(58 + ox, 51 + oy), Vector2(22 + ox, 51 + oy)])
	p.end(pal.metal)
	p.begin()
	p.m_poly([Vector2(27 + ox, 27 + oy), Vector2(53 + ox, 27 + oy), Vector2(50 + ox, 44 + oy), Vector2(30 + ox, 44 + oy)])
	p.end(pal.accent)
	_insignia(p, 40 + ox, 33 + oy, pal.silver, pal.eye)
	p.begin(); p.m_rect(30 + ox, 44 + oy, 20, 7); p.end(pal.dark)
	for ay in [46, 48, 50]:
		p.rect(31 + ox, ay + oy, 18, 1, pal.metal.darkened(0.2))
	for vx in [20, 56]:                                                          # rejillas laterales
		for vy in [30, 33, 36]:
			p.rect(vx + ox, vy + oy, 4, 1, pal.dark)
	if detail == 1:
		p.line_px(Vector2(27 + ox, 28 + oy), Vector2(30 + ox, 43 + oy), pal.glow)
		p.line_px(Vector2(53 + ox, 28 + oy), Vector2(50 + ox, 43 + oy), pal.glow)
	elif detail == 2:
		p.line_px(Vector2(33 + ox, 45 + oy), Vector2(33 + ox, 51 + oy), pal.dark.darkened(0.4))
		_wear(p, Rect2i(17 + ox, 25 + oy, 46, 26), 0.12)

	# Hombrera trasera con pinchos
	p.begin(); p.m_ellipse(14 + ox, 29 + oy, 9.5, 7.6); p.end(pal.metal)
	p.rect(6 + ox, 28 + oy, 16, 2, pal.accent)
	p.poly_px([Vector2(8 + ox, 25 + oy), Vector2(11 + ox, 12 + oy), Vector2(16 + ox, 24 + oy)], pal.silver)

	# Cabeza con corona
	p.begin(); p.m_rect(36 + ox, 20 + oy, 8, 5); p.end(pal.dark)
	p.begin()
	p.m_poly([Vector2(32 + ox, 5 + oy), Vector2(48 + ox, 5 + oy), Vector2(51 + ox, 10 + oy),
		Vector2(50 + ox, 20 + oy), Vector2(30 + ox, 20 + oy), Vector2(29 + ox, 10 + oy)])
	p.end(pal.dark)
	p.poly_px([Vector2(37 + ox, 5 + oy), Vector2(40 + ox, -1 + oy), Vector2(43 + ox, 5 + oy)], pal.silver)   # cresta
	p.poly_px([Vector2(29 + ox, 10 + oy), Vector2(25 + ox, 1 + oy), Vector2(33 + ox, 7 + oy)], pal.metal.lightened(0.15))
	p.poly_px([Vector2(51 + ox, 10 + oy), Vector2(55 + ox, 1 + oy), Vector2(47 + ox, 7 + oy)], pal.metal.lightened(0.15))
	p.rect(32 + ox, 11 + oy, 16, 4, eye)                                          # visor
	p.rect(33 + ox, 12 + oy, 14, 1, Color(1, 0.88, 0.8) if not pose.get("dead", false) else eye)
	p.begin(); p.m_rect(34 + ox, 16 + oy, 12, 5); p.end(pal.silver)               # máscara
	p.rect(35 + ox, 18 + oy, 10, 1, pal.dark)
	p.rect(35 + ox, 20 + oy, 10, 1, pal.dark)
	if detail == 2:
		_wear(p, Rect2i(29 + ox, 5 + oy, 22, 16), 0.1)

	# Cañón de fusión (brazo derecho)
	var cx: int = -recoil
	p.begin(); p.m_ellipse(66 + ox, 30 + oy, 9.4, 7.6); p.end(pal.metal)          # hombrera
	p.rect(58 + ox, 29 + oy, 16, 2, pal.accent)
	p.poly_px([Vector2(64 + ox, 24 + oy), Vector2(69 + ox, 12 + oy), Vector2(73 + ox, 25 + oy)], pal.silver)
	p.begin(); p.m_rect(56 + ox + cx, 32 + oy, 16, 13); p.end(pal.dark)           # culata
	p.rect(58 + ox + cx, 34 + oy, 12, 2, pal.accent)
	p.begin(); p.m_rect(72 + ox + cx, 35 + oy, 14, 7); p.end(pal.metal)           # cañón
	for rx in [75, 80]:
		p.rect(rx + ox + cx, 34 + oy, 2, 9, pal.accent)
	p.begin(); p.m_rect(85 + ox + cx, 33 + oy, 5, 11); p.end(pal.dark)            # freno de boca
	p.rect(86 + ox + cx, 36 + oy, 2, 5, Color(pal.glow.r, pal.glow.g, pal.glow.b, 0.5 + 0.5 * charge))
	p.ellipse_px(65 + ox + cx, 38 + oy, 2.5, 2.5, Color(pal.glow.r, pal.glow.g, pal.glow.b, 0.4 + 0.6 * charge))
	if detail == 1:
		p.line_px(Vector2(72 + ox + cx, 38 + oy), Vector2(84 + ox + cx, 38 + oy), pal.glow)
	elif detail == 2:
		_wear(p, Rect2i(56 + ox + cx, 32 + oy, 34, 13), 0.12)

	p.outline()

	if not pose.get("dead", false):
		for gx in range(31, 49):
			p.px(gx + ox, 10 + oy, Color(pal.eye.r, pal.eye.g, pal.eye.b, 0.22))
			p.px(gx + ox, 15 + oy, Color(pal.eye.r, pal.eye.g, pal.eye.b, 0.22))
	if flash > 0.0:
		var mx := 91 + ox + cx
		var my := 38 + oy
		p.ellipse_px(mx + 3, my, 8 * flash + 2, 6 * flash + 1, Color(1, 0.55, 0.15, 0.5))
		p.poly_px([Vector2(mx, my - 3), Vector2(mx + 14 * flash, my), Vector2(mx, my + 3)], Color(1, 0.85, 0.35, 0.95))
		p.poly_px([Vector2(mx, my - 6 * flash), Vector2(mx + 5, my), Vector2(mx, my + 6 * flash)], Color(1, 0.95, 0.7, 0.9))
		p.poly_px([Vector2(mx - 2, my - 1), Vector2(mx + 8 * flash, my), Vector2(mx - 2, my + 1)], Color.WHITE)
	return p


# ── TANQUE ────────────────────────────────────────────────────────────────────
# pose: bob, recoil, flash, charge, tread (fase de las orugas), smoke

static func tank(pal: Dictionary, pose: Dictionary = {}) -> RefCounted:
	var p = _new(pal)
	var oy: int = pose.get("bob", 0)
	var recoil: int = pose.get("recoil", 0)
	var flash: float = pose.get("flash", 0.0)
	var charge: float = pose.get("charge", 0.3)
	var tread: int = pose.get("tread", 0)
	var detail: int = pal.detail

	p.ellipse_px(40, 77, 42, 3.5, Color(0, 0, 0, 0.38))

	# Orugas
	p.begin()
	p.m_rect(9, 63, 62, 14)
	p.m_ellipse(9, 70, 7, 7)
	p.m_ellipse(71, 70, 7, 7)
	p.end(pal.dark)
	for x in range(5, 78, 4):
		var xx: int = x + (tread % 4)
		if xx < 77:
			p.rect(xx, 63, 2, 1, pal.metal.lightened(0.1))
			p.rect(xx, 76, 2, 1, pal.metal.lightened(0.1))
	for wx in [11, 26, 40, 54, 69]:
		p.begin(); p.m_ellipse(wx, 70, 5.4, 5.4); p.end(pal.metal)
		p.begin(); p.m_ellipse(wx, 70, 2.2, 2.2); p.end(pal.silver)
		var a := deg_to_rad(tread * 40.0 + wx * 7.0)
		p.line_px(Vector2(wx, 70), Vector2(wx, 70) + Vector2(cos(a), sin(a)) * 4.0, pal.dark)

	# Casco
	p.begin()
	p.m_poly([Vector2(10, 50 + oy), Vector2(64, 50 + oy), Vector2(75, 58 + oy), Vector2(75, 64 + oy),
		Vector2(8, 64 + oy), Vector2(5, 57 + oy)])
	p.end(pal.metal)
	p.rect(8, 58 + oy, 66, 2, pal.accent)
	p.poly_px([Vector2(73, 56 + oy), Vector2(80, 59 + oy), Vector2(73, 62 + oy)], pal.silver)   # pincho frontal
	p.rect(10, 52 + oy, 6, 1, pal.dark)
	for ex in [6, 9]:                                                            # escape
		p.rect(ex, 54 + oy, 2, 4, pal.dark)

	# Torreta
	p.begin()
	p.m_poly([Vector2(22, 50 + oy), Vector2(27, 38 + oy), Vector2(50, 36 + oy), Vector2(58, 50 + oy)])
	p.end(pal.accent)
	_insignia(p, 38, 44 + oy, pal.silver, pal.eye)
	p.begin(); p.m_ellipse(33, 37 + oy, 5, 2.5); p.end(pal.dark)                  # escotilla
	p.line_px(Vector2(46, 36 + oy), Vector2(47, 24 + oy), pal.silver)             # antena
	p.px(47, 23 + oy, pal.eye)
	p.rect(53, 41 + oy, 4, 2, pal.eye)                                           # visor de la torreta

	# Cañón principal
	var rc: int = -recoil
	p.begin(); p.m_rect(54 + rc, 39 + oy, 18, 8); p.end(pal.dark)                  # mantelete
	p.begin(); p.m_rect(70 + rc, 41 + oy, 16, 5); p.end(pal.metal)                 # cañón
	for rx in [74, 79]:
		p.rect(rx + rc, 40 + oy, 2, 7, pal.accent)
	p.begin(); p.m_rect(85 + rc, 39 + oy, 6, 9); p.end(pal.dark)                   # freno de boca
	p.rect(87 + rc, 42 + oy, 2, 3, Color(pal.glow.r, pal.glow.g, pal.glow.b, 0.5 + 0.5 * charge))
	if detail == 1:
		p.line_px(Vector2(8, 61 + oy), Vector2(74, 61 + oy), pal.glow.darkened(0.2))
		p.line_px(Vector2(70 + rc, 43 + oy), Vector2(85 + rc, 43 + oy), pal.glow)
	elif detail == 2:
		_wear(p, Rect2i(5, 36 + oy, 86, 28), 0.11)

	p.outline()

	# Humo del escape
	var sm: int = pose.get("smoke", 0)
	for i in 3:
		p.ellipse_px(5 - i * 3 - (sm % 3), 50 + oy - i * 5, 2.4 + i * 0.7, 2.0 + i * 0.6,
			Color(0.3, 0.3, 0.34, 0.5 - i * 0.14))
	if flash > 0.0:
		var mx := 93 + rc
		var my := 43 + oy
		p.ellipse_px(mx + 3, my, 9 * flash + 2, 7 * flash + 1, Color(1, 0.55, 0.15, 0.5))
		p.poly_px([Vector2(mx, my - 4), Vector2(mx + 16 * flash, my), Vector2(mx, my + 4)], Color(1, 0.85, 0.35, 0.95))
		p.poly_px([Vector2(mx - 2, my - 1), Vector2(mx + 9 * flash, my), Vector2(mx - 2, my + 1)], Color.WHITE)
	return p
