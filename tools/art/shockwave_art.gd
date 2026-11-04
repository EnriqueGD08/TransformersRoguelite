# shockwave_art.gd
# Herramienta de desarrollo: diseño procedural de Shockwave (robot cíclope con cañón y cañón láser).
# SRP: solo define cómo se DIBUJA Shockwave; no sabe de SpriteFrames.
# Coordenadas de dibujo: 80x80 (pies en y=77). Lienzo real 144x96 con margen.
# La punta del cañón del robot queda en (88, 38); la del modo cañón láser en (90, 47).

extends RefCounted

const P := preload("res://tools/art/painter.gd")

const CANVAS := Vector2i(144, 96)
const SHIFT := Vector2i(32, 16)

# detail: 0 = limpio (G1), 1 = costuras luminosas (Prime), 2 = desgaste (Bay).
const SKINS := {
	"g1": {
		"purple": Color("6c3fa8"), "dark": Color("33273f"), "metal": Color("7c7a90"),
		"silver": Color("c2c4d2"), "eye": Color("ff2a2a"), "glow": Color("ff5a9e"),
		"grain": 0.0, "detail": 0, "seed": 51,
	},
	"prime": {
		"purple": Color("4b2f7c"), "dark": Color("1d1826"), "metal": Color("4a4a5c"),
		"silver": Color("9a9cb0"), "eye": Color("ff3355"), "glow": Color("b57bff"),
		"grain": 0.06, "detail": 1, "seed": 52,
	},
	"bay": {
		"purple": Color("4a3a58"), "dark": Color("1a171f"), "metal": Color("55545f"),
		"silver": Color("767788"), "eye": Color("ff6a3d"), "glow": Color("ff8a3a"),
		"grain": 0.16, "detail": 2, "seed": 53,
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
			var r: float = p._hash(x + 61, y + 31)
			var a: Color = p.img.get_pixel(x + p.tx, y + p.ty)
			if a.a < 0.9:
				continue
			if r > 1.0 - amount * 0.5:
				p.px(x, y, a.lightened(0.28))
				p.px(x + 1, y + 1, a.lightened(0.16))
			elif r < amount * 0.25:
				p.px(x, y, Color("6b3a1e"))


static func _insignia(p, cx: int, cy: int, col: Color, eye: Color) -> void:
	p.poly_px([Vector2(cx - 5, cy - 4), Vector2(cx + 5, cy - 4), Vector2(cx + 4, cy + 2),
		Vector2(cx, cy + 6), Vector2(cx - 4, cy + 2)], col)
	p.poly_px([Vector2(cx - 6, cy - 4), Vector2(cx - 4, cy - 8), Vector2(cx - 2, cy - 4)], col)
	p.poly_px([Vector2(cx + 2, cy - 4), Vector2(cx + 4, cy - 8), Vector2(cx + 6, cy - 4)], col)
	p.rect(cx - 3, cy - 1, 2, 2, eye)
	p.rect(cx + 1, cy - 1, 2, 2, eye)
	p.rect(cx - 1, cy + 3, 2, 1, eye)


# ── ROBOT ─────────────────────────────────────────────────────────────────────
# pose: bob, lean, kneel, stride, recoil, flash, charge, dead

static func robot(pal: Dictionary, pose: Dictionary = {}) -> RefCounted:
	var p = _new(pal)
	var ox: int = pose.get("lean", 0)
	var oy: int = pose.get("bob", 0) + pose.get("kneel", 0)
	var stride: int = pose.get("stride", 0)
	var rc: int = -pose.get("recoil", 0)
	var flash: float = pose.get("flash", 0.0)
	var charge: float = pose.get("charge", 0.3)
	var detail: int = pal.detail
	var dead: bool = pose.get("dead", false)
	var eye: Color = Color("33262a") if dead else pal.eye

	p.ellipse_px(40, 77, 25, 3.5, Color(0, 0, 0, 0.38))

	# Piernas gruesas
	for side in [-1, 1]:
		var s: int = stride * side
		var lx: int = 40 + side * 10 + s * 3
		var ly: int = -2 if s > 0 else 0
		p.begin(); p.m_rect(lx - 7, 52 + ly, 14, 11); p.end(pal.purple)
		p.rect(lx - 7, 57 + ly, 14, 2, pal.dark)
		p.begin(); p.m_ellipse(lx, 62 + ly, 5.0, 3.6); p.end(pal.silver)
		p.begin(); p.m_rect(lx - 6, 64 + ly, 12, 8); p.end(pal.dark)
		p.rect(lx - 6, 67 + ly, 12, 2, pal.metal)
		p.begin()
		p.m_poly([Vector2(lx - 8, 72 + ly), Vector2(lx + 5, 72 + ly), Vector2(lx + 10, 75 + ly),
			Vector2(lx + 10, 77 + ly), Vector2(lx - 8, 77 + ly)])
		p.end(pal.dark)
		if detail == 1:
			p.line_px(Vector2(lx - 5, 53 + ly), Vector2(lx - 5, 62 + ly), pal.glow)
		elif detail == 2:
			_wear(p, Rect2i(lx - 7, 52 + ly, 14, 25), 0.1)

	# Cadera
	p.begin(); p.m_rect(26, 49, 28, 7); p.end(pal.dark)
	p.rect(35, 51, 10, 3, pal.metal)

	# Brazo trasero (puño pesado)
	p.begin(); p.m_line(Vector2(13 + ox, 32 + oy), Vector2(9 + ox, 50 + oy), 9); p.end(pal.purple)
	p.begin(); p.m_line(Vector2(10 + ox, 44 + oy), Vector2(8 + ox, 55 + oy), 9); p.end(pal.dark)
	p.begin(); p.m_ellipse(8 + ox, 58 + oy, 6.0, 5.4); p.end(pal.silver)
	p.rect(4 + ox, 58 + oy, 8, 1, pal.dark)

	# Torso ancho
	p.begin()
	p.m_poly([Vector2(15 + ox, 25 + oy), Vector2(65 + ox, 25 + oy), Vector2(59 + ox, 51 + oy), Vector2(21 + ox, 51 + oy)])
	p.end(pal.purple)
	p.begin()
	p.m_poly([Vector2(26 + ox, 27 + oy), Vector2(54 + ox, 27 + oy), Vector2(50 + ox, 45 + oy), Vector2(30 + ox, 45 + oy)])
	p.end(pal.dark)
	_insignia(p, 40 + ox, 34 + oy, pal.silver, eye)
	p.begin(); p.m_rect(30 + ox, 44 + oy, 20, 7); p.end(pal.metal)
	for ay in [46, 48, 50]:
		p.rect(31 + ox, ay + oy, 18, 1, pal.dark)
	for vx in [18, 58]:
		for vy in [30, 33, 36, 39]:
			p.rect(vx + ox, vy + oy, 4, 1, pal.dark)
	if detail == 1:
		p.line_px(Vector2(26 + ox, 28 + oy), Vector2(30 + ox, 44 + oy), pal.glow)
		p.line_px(Vector2(54 + ox, 28 + oy), Vector2(50 + ox, 44 + oy), pal.glow)
	elif detail == 2:
		_wear(p, Rect2i(15 + ox, 25 + oy, 50, 26), 0.12)

	# Hombrera trasera
	p.begin(); p.m_ellipse(13 + ox, 30 + oy, 10.0, 8.0); p.end(pal.purple)
	p.rect(5 + ox, 29 + oy, 17, 2, pal.silver)
	p.begin(); p.m_ellipse(13 + ox, 30 + oy, 4.2, 3.4); p.end(pal.metal)

	# Cabeza cíclope
	p.begin(); p.m_rect(35 + ox, 20 + oy, 10, 5); p.end(pal.dark)
	p.begin(); p.m_ellipse(40 + ox, 12 + oy, 10.0, 9.4); p.end(pal.dark)          # cúpula
	p.begin(); p.m_rect(33 + ox, 14 + oy, 14, 7); p.end(pal.metal)                # mandíbula
	p.rect(34 + ox, 18 + oy, 12, 1, pal.dark)
	p.rect(35 + ox, 20 + oy, 10, 1, pal.dark)
	p.ellipse_px(40 + ox, 11 + oy, 5.2, 4.6, Color("120c14"))                      # cuenca
	p.ellipse_px(40 + ox, 11 + oy, 3.6, 3.4, eye)                                  # ojo único
	if not dead:
		p.ellipse_px(40 + ox, 11 + oy, 1.6, 1.6, Color(1, 0.9, 0.85))
	p.line_px(Vector2(40 + ox, 3 + oy), Vector2(40 + ox, -3 + oy), pal.silver)     # antena
	p.px(40 + ox, -4 + oy, pal.eye)
	if detail == 2:
		_wear(p, Rect2i(30 + ox, 2 + oy, 20, 22), 0.1)

	# Cañón láser en el brazo derecho
	p.begin(); p.m_ellipse(66 + ox, 30 + oy, 10.0, 8.0); p.end(pal.purple)
	p.rect(57 + ox, 29 + oy, 18, 2, pal.silver)
	p.begin(); p.m_rect(56 + ox + rc, 32 + oy, 17, 14); p.end(pal.dark)            # culata
	p.rect(58 + ox + rc, 35 + oy, 13, 2, pal.purple)
	p.ellipse_px(64 + ox + rc, 41 + oy, 3.2, 3.0, Color(pal.glow.r, pal.glow.g, pal.glow.b, 0.4 + 0.6 * charge))  # núcleo
	p.begin(); p.m_rect(73 + ox + rc, 35 + oy, 13, 7); p.end(pal.metal)            # cañón
	for rx in [75, 79, 83]:
		p.rect(rx + ox + rc, 34 + oy, 2, 9, pal.purple)
	p.begin(); p.m_rect(85 + ox + rc, 33 + oy, 5, 11); p.end(pal.dark)             # boca
	p.rect(86 + ox + rc, 36 + oy, 2, 5, Color(pal.glow.r, pal.glow.g, pal.glow.b, 0.5 + 0.5 * charge))
	if detail == 1:
		p.line_px(Vector2(73 + ox + rc, 38 + oy), Vector2(85 + ox + rc, 38 + oy), pal.glow)
	elif detail == 2:
		_wear(p, Rect2i(56 + ox + rc, 32 + oy, 34, 14), 0.12)

	p.outline()

	if not dead:
		p.ellipse_px(40 + ox, 11 + oy, 6.5, 5.8, Color(pal.eye.r, pal.eye.g, pal.eye.b, 0.2))
	if flash > 0.0:
		var mx := 91 + ox + rc
		var my := 38 + oy
		p.ellipse_px(mx + 2, my, 8 * flash + 2, 6 * flash + 1, Color(pal.glow.r, pal.glow.g, pal.glow.b, 0.5))
		p.poly_px([Vector2(mx, my - 4), Vector2(mx + 15 * flash, my), Vector2(mx, my + 4)], Color(1, 0.85, 0.95, 0.95))
		p.poly_px([Vector2(mx - 2, my - 1), Vector2(mx + 9 * flash, my), Vector2(mx - 2, my + 1)], Color.WHITE)
	return p


# ── CAÑÓN LÁSER ───────────────────────────────────────────────────────────────
# pose: bob, charge (0..1), beam (0..1 intensidad del rayo en la boca), spin (aro giratorio)

static func cannon(pal: Dictionary, pose: Dictionary = {}) -> RefCounted:
	var p = _new(pal)
	var oy: int = pose.get("bob", 0)
	var charge: float = pose.get("charge", 0.5)
	var beam: float = pose.get("beam", 0.0)
	var spin: int = pose.get("spin", 0)
	var detail: int = pal.detail
	var g: Color = pal.glow

	p.ellipse_px(40, 77, 40, 3.5, Color(0, 0, 0, 0.4))

	# Estabilizadores
	for sx in [10, 62]:
		p.begin()
		p.m_poly([Vector2(sx, 58), Vector2(sx + 8, 58), Vector2(sx + 12, 77), Vector2(sx - 4, 77)])
		p.end(pal.dark)
		p.begin(); p.m_rect(sx - 5, 74, 18, 4); p.end(pal.metal)
	# Base
	p.begin(); p.m_rect(8, 62, 64, 12); p.end(pal.purple)
	p.rect(8, 66, 64, 2, pal.dark)
	for bx in [14, 26, 38, 50, 62]:
		p.rect(bx, 69, 5, 3, pal.dark)

	# Cuerpo del cañón
	p.begin()
	p.m_poly([Vector2(12, 62), Vector2(16, 40 + oy), Vector2(48, 38 + oy), Vector2(54, 62)])
	p.end(pal.purple)
	_insignia(p, 30, 50 + oy, pal.silver, pal.eye)
	p.begin(); p.m_rect(14, 36 + oy, 26, 6); p.end(pal.dark)                         # techo
	p.line_px(Vector2(22, 36 + oy), Vector2(22, 27 + oy), pal.silver)                # antena
	p.px(22, 26 + oy, pal.eye)
	# Núcleo de energía trasero
	p.begin(); p.m_ellipse(14, 52 + oy, 7.0, 9.0); p.end(pal.dark)
	p.ellipse_px(14, 52 + oy, 4.6, 6.4, Color(g.r, g.g, g.b, 0.35 + 0.65 * charge))
	p.ellipse_px(14, 52 + oy, 2.2, 3.2, Color(1, 1, 1, 0.5 + 0.5 * charge))
	# Sensor cíclope
	p.ellipse_px(44, 44 + oy, 3.4, 3.4, pal.eye)
	p.px(44, 43 + oy, Color(1, 0.9, 0.85))

	# Cañón principal con aros
	p.begin(); p.m_rect(46, 42 + oy, 30, 11); p.end(pal.metal)
	p.begin(); p.m_rect(74, 41 + oy, 14, 13); p.end(pal.dark)                        # boca
	for k in 4:
		var rx: int = 50 + k * 7
		p.rect(rx, 40 + oy, 3, 15, pal.purple)
		var a: float = clampf(0.3 + 0.7 * charge - 0.12 * ((k + spin) % 4), 0.1, 1.0)
		p.rect(rx, 47 + oy, 3, 2, Color(g.r, g.g, g.b, a))
	p.begin(); p.m_rect(86, 44 + oy, 5, 7); p.end(pal.silver)                        # lente
	p.rect(88, 46 + oy, 2, 3, Color(g.r, g.g, g.b, 0.6 + 0.4 * beam))
	if detail == 1:
		p.line_px(Vector2(14, 56), Vector2(54, 56), g)
		p.line_px(Vector2(46, 47 + oy), Vector2(86, 47 + oy), g.darkened(0.2))
	elif detail == 2:
		_wear(p, Rect2i(8, 26 + oy, 84, 52), 0.1)

	p.outline()

	if beam > 0.0:
		var mx := 92
		var my := 47 + oy
		p.ellipse_px(mx + 1, my, 10 * beam + 2, 9 * beam + 2, Color(g.r, g.g, g.b, 0.35))
		p.ellipse_px(mx + 1, my, 6 * beam + 1, 5 * beam + 1, Color(1, 0.85, 0.95, 0.9))
		p.ellipse_px(mx + 1, my, 3 * beam, 2.6 * beam, Color.WHITE)
		for i in 6:
			var a2: float = float(i) / 6.0 * TAU + spin
			p.line_px(Vector2(mx, my) + Vector2(cos(a2), sin(a2)) * 7, Vector2(mx, my) + Vector2(cos(a2), sin(a2)) * (11 + 4 * beam), Color(1, 1, 1, 0.7))
	return p
