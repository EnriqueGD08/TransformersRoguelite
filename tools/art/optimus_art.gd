# optimus_art.gd
# Herramienta de desarrollo: diseño procedural de Optimus Prime (robot y camión).
# SRP: solo define cómo se DIBUJA Optimus; no sabe de SpriteFrames ni de Godot-juego.
# Coordenadas de dibujo: 80x80 (pies en y=77). El lienzo real es 112x96 con margen.

extends RefCounted

const P := preload("res://tools/art/painter.gd")

const CANVAS := Vector2i(144, 96)
const SHIFT := Vector2i(32, 16)  # margen izquierdo/superior del lienzo

# Paletas por skin. detail: 0 = limpio (G1), 1 = costuras luminosas (Prime), 2 = desgaste (Bay).
const SKINS := {
	"g1": {
		"red": Color("d32f2f"), "blue": Color("2a55c4"), "silver": Color("c7cfdb"),
		"dark": Color("454c5c"), "eye": Color("a8f4ff"), "glass": Color("8fdcff"),
		"blade": Color("35d6ff"), "blade_hi": Color("eaffff"), "flame": Color("4aa3ff"),
		"grain": 0.0, "detail": 0, "seed": 1,
	},
	"prime": {
		"red": Color("b5211f"), "blue": Color("1d3d94"), "silver": Color("9fabbd"),
		"dark": Color("272c38"), "eye": Color("00f0ff"), "glass": Color("4fc3f7"),
		"blade": Color("00d8ff"), "blade_hi": Color("d6ffff"), "flame": Color("2f7bff"),
		"grain": 0.05, "detail": 1, "seed": 2,
	},
	"bay": {
		"red": Color("86302a"), "blue": Color("2d4160"), "silver": Color("7d8795"),
		"dark": Color("1e222a"), "eye": Color("86d8ff"), "glass": Color("3f7f9f"),
		"blade": Color("5cc8ff"), "blade_hi": Color("e6f8ff"), "flame": Color("3c6fb5"),
		"grain": 0.14, "detail": 2, "seed": 3,
	},
}

# ── Utilidades ────────────────────────────────────────────────────────────────

static func _new(pal: Dictionary) -> RefCounted:
	var p = P.new(CANVAS.x, CANVAS.y, SHIFT.x, SHIFT.y)
	p.grain = pal.grain
	p.seed_val = pal.seed
	return p


static func _rot(pt: Vector2, deg: float, origin: Vector2) -> Vector2:
	var a := deg_to_rad(deg)
	return origin + Vector2(pt.x * cos(a) - pt.y * sin(a), pt.x * sin(a) + pt.y * cos(a))


## Desgaste estilo película (Bay): arañazos y óxido en una zona.
static func _wear(p, rect: Rect2i, amount: float) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var r: float = p._hash(x + 11, y + 5)
			var a: Color = p.img.get_pixel(x + p.tx, y + p.ty)
			if a.a < 0.9:
				continue
			if r > 1.0 - amount * 0.5:
				p.px(x, y, a.lightened(0.28))
				p.px(x + 1, y + 1, a.lightened(0.18))
			elif r < amount * 0.25:
				p.px(x, y, Color("8a4b24"))

# ── ROBOT ─────────────────────────────────────────────────────────────────────
# pose: bob, lean, kneel, stride, axe (grados), hand (Vector2), trail {from,to},
#       dead (bool: ojos apagados)

static func robot(pal: Dictionary, pose: Dictionary = {}) -> RefCounted:
	var p = _new(pal)
	var ox: int = pose.get("lean", 0)
	var oy: int = pose.get("bob", 0) + pose.get("kneel", 0)
	var stride: int = pose.get("stride", 0)
	var axe_deg: float = pose.get("axe", -70.0)
	var hand: Vector2 = pose.get("hand", Vector2.ZERO)
	var detail: int = pal.detail
	var eye_col: Color = Color("30323c") if pose.get("dead", false) else pal.eye
	var glass_light: Color = pal.glass.lightened(0.45)
	var glass_dark: Color = pal.glass.darkened(0.45)

	p.ellipse_px(40, 77, 22, 3, Color(0, 0, 0, 0.35))

	# ── Piernas ──
	for side in [-1, 1]:
		var s: int = stride * side
		var lx: int = 40 + side * 8 + s * 3
		var ly: int = -2 if s > 0 else 0
		p.begin(); p.m_rect(lx - 5, 52 + ly, 10, 11); p.end(pal.blue)           # muslo
		p.begin(); p.m_ellipse(lx, 62 + ly, 4.8, 3.8); p.end(pal.silver)        # rodilla
		p.begin(); p.m_rect(lx - 4, 64 + ly, 8, 9); p.end(pal.blue)             # espinilla
		p.begin(); p.m_rect(lx - 5, 66 + ly, 10, 4); p.end(pal.silver)          # placa
		p.begin()                                                                 # pie
		p.m_poly([Vector2(lx - 6, 72 + ly), Vector2(lx + 3, 72 + ly), Vector2(lx + 8, 75 + ly),
			Vector2(lx + 8, 77 + ly), Vector2(lx - 6, 77 + ly)])
		p.end(pal.dark)
		p.rect(lx - 3, 74 + ly, 5, 1, pal.silver.darkened(0.2))                  # tira del pie
		p.rect(lx - 1, 55 + ly, 2, 4, pal.dark)                                  # hueco articulación
		if detail == 1:
			p.line_px(Vector2(lx - 3, 53 + ly), Vector2(lx - 3, 60 + ly), pal.eye)
			p.px(lx, 62 + ly, pal.eye)
		elif detail == 2:
			p.rect(lx - 4, 58 + ly, 8, 1, pal.blue.darkened(0.5))
			_wear(p, Rect2i(lx - 5, 52 + ly, 10, 24), 0.1)

	# ── Cadera ──
	p.begin(); p.m_rect(28, 49, 24, 6); p.end(pal.dark)
	p.rect(37, 50, 6, 3, pal.silver)
	p.rect(39, 51, 2, 1, pal.red)

	# ── Chimeneas (detrás de los hombros) ──
	for sx in [17, 59]:
		p.begin(); p.m_rect(sx + ox, 4 + oy, 4, 25); p.end(pal.silver)
		p.rect(sx + ox, 4 + oy, 4, 3, Color("14141b"))
		p.rect(sx + ox, 12 + oy, 4, 1, pal.dark)
		p.rect(sx + ox, 18 + oy, 4, 1, pal.dark)

	# ── Brazo trasero (izquierda del espectador) ──
	p.begin(); p.m_rect(11 + ox, 33 + oy, 9, 10); p.end(pal.red)
	p.begin(); p.m_rect(11 + ox, 43 + oy, 8, 9); p.end(pal.blue)
	p.rect(11 + ox, 43 + oy, 8, 1, pal.dark)
	p.rect(13 + ox, 46 + oy, 4, 1, pal.silver)
	p.begin(); p.m_ellipse(15 + ox, 55 + oy, 4.6, 4.2); p.end(pal.silver)
	p.rect(13 + ox, 55 + oy, 5, 1, pal.dark)

	# ── Torso ──
	p.begin()
	p.m_poly([Vector2(21 + ox, 27 + oy), Vector2(59 + ox, 27 + oy),
		Vector2(56 + ox, 51 + oy), Vector2(24 + ox, 51 + oy)])
	p.end(pal.red)
	# Ventanas del parabrisas del pecho
	for wx in [26, 42]:
		p.rect(wx - 1 + ox, 28 + oy, 14, 12, pal.silver.darkened(0.15))
		p.rect(wx + ox, 29 + oy, 12, 10, glass_dark)
		p.rect(wx + ox, 29 + oy, 12, 8, pal.glass)
		p.rect(wx + ox, 29 + oy, 12, 1, glass_light)
		for i in 5:
			p.px(wx + 2 + i + ox, 36 - i + oy, Color(1, 1, 1, 0.85))
		p.px(wx + 9 + ox, 31 + oy, Color(1, 1, 1, 0.7))
	# Rejilla inferior
	p.begin(); p.m_rect(27 + ox, 41 + oy, 26, 7); p.end(pal.silver)
	for ly in [43, 45]:
		p.rect(28 + ox, ly + oy, 24, 1, pal.dark)
	p.rect(38 + ox, 41 + oy, 4, 6, pal.red)
	p.rect(39 + ox, 42 + oy, 2, 2, pal.silver)
	# Abdomen
	p.begin(); p.m_rect(29 + ox, 48 + oy, 22, 4); p.end(pal.dark)
	if detail == 1:
		p.line_px(Vector2(23 + ox, 30 + oy), Vector2(25 + ox, 48 + oy), pal.eye)
		p.line_px(Vector2(57 + ox, 30 + oy), Vector2(55 + ox, 48 + oy), pal.eye)
		p.line_px(Vector2(27 + ox, 40 + oy), Vector2(53 + ox, 40 + oy), pal.eye.darkened(0.3))
	elif detail == 2:
		p.line_px(Vector2(33 + ox, 41 + oy), Vector2(33 + ox, 51 + oy), pal.red.darkened(0.55))
		p.line_px(Vector2(47 + ox, 41 + oy), Vector2(47 + ox, 51 + oy), pal.red.darkened(0.55))
		_wear(p, Rect2i(21 + ox, 27 + oy, 38, 24), 0.11)

	# Hombrera izquierda
	p.begin(); p.m_ellipse(17 + ox, 31 + oy, 7.8, 6.8); p.end(pal.red)
	p.line_px(Vector2(11 + ox, 33 + oy), Vector2(23 + ox, 33 + oy), pal.silver)

	# ── Cabeza ──
	p.begin(); p.m_rect(37 + ox, 24 + oy, 6, 4); p.end(pal.dark)               # cuello
	p.begin()                                                                    # casco
	p.m_poly([Vector2(34 + ox, 7 + oy), Vector2(46 + ox, 7 + oy), Vector2(48 + ox, 11 + oy),
		Vector2(48 + ox, 18 + oy), Vector2(32 + ox, 18 + oy), Vector2(32 + ox, 11 + oy)])
	p.end(pal.blue)
	p.begin()                                                                    # orejeras
	p.m_poly([Vector2(28 + ox, 8 + oy), Vector2(32 + ox, 10 + oy), Vector2(32 + ox, 20 + oy), Vector2(29 + ox, 20 + oy)])
	p.end(pal.blue)
	p.begin()
	p.m_poly([Vector2(52 + ox, 8 + oy), Vector2(48 + ox, 10 + oy), Vector2(48 + ox, 20 + oy), Vector2(51 + ox, 20 + oy)])
	p.end(pal.blue)
	p.begin(); p.m_rect(38 + ox, 3 + oy, 4, 4); p.end(pal.blue)                 # antena
	p.rect(39 + ox, 3 + oy, 2, 1, pal.red)
	p.rect(38 + ox, 9 + oy, 4, 3, pal.red)                                       # frente
	p.begin()                                                                    # máscara
	p.m_poly([Vector2(34 + ox, 15 + oy), Vector2(46 + ox, 15 + oy), Vector2(45 + ox, 25 + oy), Vector2(35 + ox, 25 + oy)])
	p.end(pal.silver)
	p.rect(35 + ox, 15 + oy, 4, 2, eye_col)                                      # ojos
	p.rect(41 + ox, 15 + oy, 4, 2, eye_col)
	p.px(36 + ox, 15 + oy, Color(1, 1, 1))
	p.px(42 + ox, 15 + oy, Color(1, 1, 1))
	p.rect(37 + ox, 21 + oy, 6, 1, pal.dark)                                     # boca
	p.rect(38 + ox, 23 + oy, 4, 1, pal.dark.darkened(0.3))
	p.px(36 + ox, 19 + oy, pal.silver.darkened(0.35))
	p.px(44 + ox, 19 + oy, pal.silver.darkened(0.35))
	if detail == 2:
		_wear(p, Rect2i(32 + ox, 8 + oy, 17, 17), 0.1)

	# ── Brazo del hacha ──
	var shoulder := Vector2(63 + ox, 33 + oy)
	var hnd := Vector2(63 + ox, 46 + oy) + hand
	p.begin(); p.m_line(shoulder, hnd, 6); p.end(pal.blue)
	p.begin(); p.m_line(shoulder, shoulder.lerp(hnd, 0.42), 7); p.end(pal.red)
	p.begin(); p.m_ellipse(63 + ox, 31 + oy, 7.8, 6.8); p.end(pal.red)          # hombrera
	p.line_px(Vector2(57 + ox, 33 + oy), Vector2(69 + ox, 33 + oy), pal.silver)

	# ── Hacha de energon ──
	var handle_a := _rot(Vector2(-9, 0), axe_deg, hnd)
	var handle_b := _rot(Vector2(26, 0), axe_deg, hnd)
	p.begin(); p.m_line(handle_a, handle_b, 3); p.end(pal.dark.lightened(0.15))
	for t in [0.15, 0.35, 0.55]:
		var c := handle_a.lerp(handle_b, t)
		p.px(int(c.x), int(c.y), pal.silver)
	var k := 0.92
	var blade_local := [Vector2(21, 2), Vector2(22, 10), Vector2(28, 16), Vector2(37, 18),
		Vector2(46, 14), Vector2(44, 9), Vector2(37, 9), Vector2(32, 5), Vector2(31, -3),
		Vector2(27, -9), Vector2(21, -3)]
	var blade_pts: Array = []
	for bp in blade_local:
		blade_pts.append(_rot(bp * k, axe_deg, hnd))
	p.begin(); p.m_poly(blade_pts)
	var glow_cells: Array = p.mask_dilated(3)
	p.end(pal.blade)
	# Núcleo brillante de la hoja
	var core_local := [Vector2(26, 5), Vector2(28, 11), Vector2(36, 14), Vector2(41, 12),
		Vector2(36, 11), Vector2(31, 8), Vector2(29, 3)]
	var core_pts: Array = []
	for cp in core_local:
		core_pts.append(_rot(cp * k, axe_deg, hnd))
	p.poly_px(core_pts, pal.blade_hi)
	p.begin(); p.m_ellipse(hnd.x, hnd.y, 4.6, 4.2)                                  # puño sobre el mango
	p.end(pal.silver)
	p.rect(int(hnd.x) - 3, int(hnd.y), 6, 1, pal.dark)

	p.outline()

	# ── Efectos posteriores al contorno ──
	p.glow(glow_cells, Color(pal.blade.r, pal.blade.g, pal.blade.b, 0.32))
	if not pose.get("dead", false):
		for gx in range(33, 48):
			for gy in [14, 17]:
				p.px(gx + ox, gy + oy, Color(pal.eye.r, pal.eye.g, pal.eye.b, 0.22))
	if pose.has("trail"):
		var tr: Dictionary = pose.trail
		_draw_trail(p, hnd, tr.from, tr.to)
	return p


## Estela curva del hachazo.
static func _draw_trail(p, center: Vector2, from_deg: float, to_deg: float) -> void:
	var outer: Array = []
	var inner: Array = []
	var steps := 9
	for i in steps + 1:
		var a: float = lerpf(from_deg, to_deg, float(i) / steps)
		outer.append(center + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 40.0)
		inner.append(center + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 22.0)
	inner.reverse()
	p.poly_px(outer + inner, Color(0.7, 0.97, 1.0, 0.38))
	var o2: Array = []
	var i2: Array = []
	for i in steps + 1:
		var a: float = lerpf(from_deg, to_deg, float(i) / steps)
		o2.append(center + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 37.0)
		i2.append(center + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 29.0)
	i2.reverse()
	p.poly_px(o2 + i2, Color(1, 1, 1, 0.5))

# ── CAMIÓN ────────────────────────────────────────────────────────────────────
# pose: bob, lunge, wheel (grados), smoke (fase 0..3), burst (bool)

static func truck(pal: Dictionary, pose: Dictionary = {}) -> RefCounted:
	var p = _new(pal)
	var oy: int = pose.get("bob", 0)
	var ox: int = pose.get("lunge", 0)
	var wheel_a: float = pose.get("wheel", 0.0)
	var detail: int = pal.detail
	var glass_light: Color = pal.glass.lightened(0.45)
	var glass_dark: Color = pal.glass.darkened(0.45)
	var tire := Color("1b1d25")

	p.ellipse_px(40 + ox, 77, 38, 3, Color(0, 0, 0, 0.35))

	# Tráiler
	p.begin(); p.m_rect(1 + ox, 18 + oy, 25, 41); p.end(pal.silver)
	for i in 4:
		p.rect(6 + i * 6 + ox, 19 + oy, 1, 39, Color(0, 0, 0, 0.22))
	p.rect(2 + ox, 46 + oy, 24, 4, pal.blue)
	p.rect(2 + ox, 47 + oy, 24, 1, pal.blue.lightened(0.25))
	# Logo Autobot
	p.poly_px([Vector2(8 + ox, 25 + oy), Vector2(19 + ox, 25 + oy), Vector2(18 + ox, 33 + oy),
		Vector2(16 + ox, 38 + oy), Vector2(11 + ox, 38 + oy), Vector2(9 + ox, 33 + oy)], pal.red)
	p.rect(10 + ox, 28 + oy, 2, 2, pal.eye)
	p.rect(15 + ox, 28 + oy, 2, 2, pal.eye)
	p.rect(11 + ox, 33 + oy, 5, 2, pal.silver)
	p.rect(1 + ox, 18 + oy, 1, 41, pal.dark)
	# Chasis
	p.begin(); p.m_rect(1 + ox, 58 + oy, 76, 4); p.end(Color("262932"))

	# Chimeneas
	for sx in [32, 36]:
		var top := 1 if sx == 32 else 7
		p.begin(); p.m_rect(sx + ox, top + oy, 3, 42 - top); p.end(pal.silver)
		p.rect(sx + ox, top + oy, 3, 3, Color("14141b"))
		p.rect(sx + ox, top + 12 + oy, 3, 1, pal.dark)
		p.rect(sx + ox, top + 24 + oy, 3, 1, pal.dark)

	# Litera (parte trasera azul de la cabina)
	p.begin(); p.m_rect(26 + ox, 25 + oy, 14, 33); p.end(pal.blue)
	p.rect(28 + ox, 30 + oy, 10, 1, pal.blue.darkened(0.4))
	p.rect(28 + ox, 34 + oy, 10, 1, pal.blue.darkened(0.4))
	# Cabina
	p.begin()
	p.m_poly([Vector2(40 + ox, 24 + oy), Vector2(52 + ox, 24 + oy), Vector2(58 + ox, 36 + oy),
		Vector2(58 + ox, 58 + oy), Vector2(40 + ox, 58 + oy)])
	p.end(pal.red)
	p.begin(); p.m_rect(39 + ox, 20 + oy, 15, 5); p.end(pal.blue)               # visera/techo
	p.rect(40 + ox, 21 + oy, 13, 1, pal.blue.lightened(0.3))
	# Parabrisas y ventana lateral
	p.poly_px([Vector2(49 + ox, 26 + oy), Vector2(52 + ox, 26 + oy), Vector2(58 + ox, 36 + oy),
		Vector2(58 + ox, 43 + oy), Vector2(49 + ox, 43 + oy)], pal.glass)
	p.rect(49 + ox, 42 + oy, 9, 1, glass_dark)
	p.line_px(Vector2(51 + ox, 40 + oy), Vector2(55 + ox, 31 + oy), Color(1, 1, 1, 0.8))
	p.line_px(Vector2(53 + ox, 41 + oy), Vector2(56 + ox, 36 + oy), Color(1, 1, 1, 0.5))
	p.rect(41 + ox, 27 + oy, 8, 16, glass_dark)
	p.rect(42 + ox, 28 + oy, 6, 14, pal.glass)
	p.rect(42 + ox, 28 + oy, 6, 1, glass_light)
	p.line_px(Vector2(43 + ox, 40 + oy), Vector2(46 + ox, 31 + oy), Color(1, 1, 1, 0.7))
	# Puerta y manilla
	p.rect(41 + ox, 45 + oy, 16, 1, pal.red.darkened(0.5))
	p.rect(41 + ox, 45 + oy, 1, 13, pal.red.darkened(0.5))
	p.rect(56 + ox, 45 + oy, 1, 13, pal.red.darkened(0.5))
	p.rect(53 + ox, 48 + oy, 3, 1, pal.silver)
	# Capó
	p.begin()
	p.m_poly([Vector2(57 + ox, 41 + oy), Vector2(70 + ox, 43 + oy), Vector2(76 + ox, 47 + oy),
		Vector2(76 + ox, 58 + oy), Vector2(57 + ox, 58 + oy)])
	p.end(pal.red)
	# Llamas azules
	p.begin()
	p.m_poly([Vector2(58 + ox, 57 + oy), Vector2(60 + ox, 49 + oy), Vector2(63 + ox, 54 + oy),
		Vector2(66 + ox, 46 + oy), Vector2(68 + ox, 53 + oy), Vector2(72 + ox, 49 + oy),
		Vector2(74 + ox, 57 + oy)])
	p.end(pal.flame)
	p.px(60 + ox, 51 + oy, Color(1, 1, 1, 0.9))
	p.px(66 + ox, 48 + oy, Color(1, 1, 1, 0.9))
	p.px(72 + ox, 51 + oy, Color(1, 1, 1, 0.9))
	# Parrilla, parachoques, faro
	p.begin(); p.m_rect(75 + ox, 44 + oy, 3, 14); p.end(pal.silver)
	for gy in [46, 49, 52, 55]:
		p.rect(75 + ox, gy + oy, 3, 1, pal.dark)
	p.begin(); p.m_rect(73 + ox, 57 + oy, 6, 4); p.end(pal.silver)
	p.ellipse_px(72 + ox, 46 + oy, 2.4, 2.2, Color("ffe27a"))
	p.px(71 + ox, 45 + oy, Color(1, 1, 1))
	if detail == 1:
		p.line_px(Vector2(2 + ox, 52 + oy), Vector2(25 + ox, 52 + oy), pal.eye)
		p.line_px(Vector2(41 + ox, 24 + oy), Vector2(41 + ox, 57 + oy), pal.eye.darkened(0.25))
		p.line_px(Vector2(27 + ox, 26 + oy), Vector2(27 + ox, 56 + oy), pal.eye.darkened(0.25))
	elif detail == 2:
		_wear(p, Rect2i(1 + ox, 18 + oy, 77, 42), 0.1)

	# Ruedas
	for cx in [16, 42, 66]:
		p.begin(); p.m_ellipse(cx + ox, 69, 8.6, 8.6); p.end(tire, false)
		p.begin(); p.m_ellipse(cx + ox, 69, 5.2, 5.2); p.end(pal.silver)
		for sp in 3:
			var a: float = deg_to_rad(wheel_a + sp * 60.0)
			p.line_px(Vector2(cx + ox, 69) - Vector2(cos(a), sin(a)) * 5,
				Vector2(cx + ox, 69) + Vector2(cos(a), sin(a)) * 5, pal.dark)
		p.begin(); p.m_ellipse(cx + ox, 69, 2.0, 2.0); p.end(pal.dark.lightened(0.1))
		p.px(cx + ox, 69, pal.silver)
		p.rect(cx - 8 + ox, 60, 16, 2, Color("14141b"))                          # guardabarros

	p.outline()

	# Luz del faro y humo
	p.ellipse_px(76 + ox, 46 + oy, 5, 4, Color(1, 0.9, 0.5, 0.18))
	var phase: int = pose.get("smoke", 0)
	for sx in [33, 37]:
		var base_y := 1 if sx == 33 else 7
		for i in 3:
			var yy := base_y - 3 - i * 4 - (phase % 4)
			var xx: int = sx + 1 + (i % 2) * 2 - 1 + ox
			p.ellipse_px(xx, yy, 2.2 + i * 0.7, 1.9 + i * 0.6, Color(0.75, 0.75, 0.8, 0.5 - i * 0.14))
	if pose.get("burst", false):
		for i in 3:
			p.ring_px(80 + ox + i * 4, 52, 6 + i * 4, 16 + i * 4, Color(0.6, 0.95, 1.0, 0.7 - i * 0.2), 0.22)
		for i in 5:
			p.line_px(Vector2(-4 + ox, 30 + i * 8), Vector2(-14 + ox, 30 + i * 8), Color(1, 1, 1, 0.5))
	return p
