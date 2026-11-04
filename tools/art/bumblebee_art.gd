# bumblebee_art.gd
# Herramienta de desarrollo: diseño procedural de Bumblebee (robot y Camaro).
# SRP: solo define cómo se DIBUJA Bumblebee; no sabe de SpriteFrames.
# Coordenadas de dibujo: 80x80 (pies en y=77). Lienzo real 128x96 con margen.

extends RefCounted

const P := preload("res://tools/art/painter.gd")

const CANVAS := Vector2i(128, 96)
const SHIFT := Vector2i(24, 16)

# detail: 0 = limpio (G1), 1 = costuras luminosas (Prime), 2 = desgaste (Bay).
const SKINS := {
	"g1": {
		"yellow": Color("ffd51c"), "black": Color("24242c"), "silver": Color("c9d1de"),
		"eye": Color("6fd2ff"), "glass": Color("7ec4ff"), "energy": Color("5fe0ff"),
		"grain": 0.0, "detail": 0, "seed": 11,
	},
	"prime": {
		"yellow": Color("f5b800"), "black": Color("1c1d24"), "silver": Color("9ba6b8"),
		"eye": Color("33e6ff"), "glass": Color("3fc3f5"), "energy": Color("00e0ff"),
		"grain": 0.05, "detail": 1, "seed": 12,
	},
	"bay": {
		"yellow": Color("d9a21a"), "black": Color("17181d"), "silver": Color("727b8b"),
		"eye": Color("8bd8ff"), "glass": Color("3c7897"), "energy": Color("69c8ff"),
		"grain": 0.14, "detail": 2, "seed": 13,
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
			var r: float = p._hash(x + 3, y + 17)
			var a: Color = p.img.get_pixel(x + p.tx, y + p.ty)
			if a.a < 0.9:
				continue
			if r > 1.0 - amount * 0.5:
				p.px(x, y, a.lightened(0.28))
				p.px(x + 1, y + 1, a.lightened(0.16))
			elif r < amount * 0.25:
				p.px(x, y, Color("7a4520"))


## Cinemática inversa de 2 huesos: devuelve la posición del codo.
static func _elbow(shoulder: Vector2, target: Vector2, len1: float, len2: float) -> Vector2:
	var d := shoulder.distance_to(target)
	d = clampf(d, 1.0, len1 + len2 - 0.5)
	var dir := (target - shoulder).normalized()
	var a := (len1 * len1 - len2 * len2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(len1 * len1 - a * a, 0.0))
	var perp := Vector2(-dir.y, dir.x)
	if perp.y < 0.0:
		perp = -perp  # el codo siempre apunta hacia abajo
	return shoulder + dir * a + perp * h


static func _arm(p, pal: Dictionary, shoulder: Vector2, target: Vector2, glow: float) -> void:
	var elbow := _elbow(shoulder, target, 12.0, 12.0)
	p.begin(); p.m_line(shoulder, elbow, 6); p.end(pal.yellow)
	p.begin(); p.m_line(elbow, target, 6); p.end(pal.yellow)
	p.begin(); p.m_ellipse(elbow.x, elbow.y, 3.8, 3.8); p.end(pal.black)          # codo
	p.px(int(elbow.x), int(elbow.y), pal.silver)
	var cuff := elbow.lerp(target, 0.55)
	p.begin(); p.m_line(cuff, target, 6); p.end(pal.black)                         # puño-cañón
	p.begin(); p.m_ellipse(target.x, target.y, 4.8, 4.6); p.end(pal.silver)
	if glow > 0.0:
		p.ellipse_px(target.x, target.y, 3.0, 3.0, Color(pal.energy.r, pal.energy.g, pal.energy.b, 0.9 * glow))
		p.px(int(target.x), int(target.y), Color.WHITE)


# ── ROBOT ─────────────────────────────────────────────────────────────────────
# pose: bob, lean, kneel, stride, front (Vector2), back (Vector2), glow, shock {r, a}, dead

static func robot(pal: Dictionary, pose: Dictionary = {}) -> RefCounted:
	var p = _new(pal)
	var ox: int = pose.get("lean", 0)
	var oy: int = pose.get("bob", 0) + pose.get("kneel", 0)
	var stride: int = pose.get("stride", 0)
	var detail: int = pal.detail
	var front: Vector2 = pose.get("front", Vector2(67, 49))
	var back: Vector2 = pose.get("back", Vector2(13, 49))
	var glow: float = pose.get("glow", 0.0)
	var eye: Color = Color("2c2f38") if pose.get("dead", false) else pal.eye
	var glass_light: Color = pal.glass.lightened(0.45)
	var glass_dark: Color = pal.glass.darkened(0.45)
	var off := Vector2(ox, oy)

	p.ellipse_px(40, 77, 20, 3, Color(0, 0, 0, 0.35))

	# Piernas
	for side in [-1, 1]:
		var s: int = stride * side
		var lx: int = 40 + side * 7 + s * 3
		var ly: int = -2 if s > 0 else 0
		p.begin(); p.m_rect(lx - 4, 53 + ly, 8, 11); p.end(pal.yellow)
		p.begin(); p.m_ellipse(lx, 63 + ly, 4.2, 3.4); p.end(pal.silver)
		p.begin(); p.m_rect(lx - 3, 65 + ly, 7, 8); p.end(pal.yellow)
		p.rect(lx - 3, 67 + ly, 7, 2, pal.black)
		p.begin()
		p.m_poly([Vector2(lx - 5, 72 + ly), Vector2(lx + 3, 72 + ly), Vector2(lx + 7, 75 + ly),
			Vector2(lx + 7, 77 + ly), Vector2(lx - 5, 77 + ly)])
		p.end(pal.black)
		p.rect(lx - 3, 74 + ly, 5, 1, pal.silver.darkened(0.3))
		if detail == 1:
			p.line_px(Vector2(lx - 2, 54 + ly), Vector2(lx - 2, 61 + ly), pal.eye)
		elif detail == 2:
			_wear(p, Rect2i(lx - 4, 53 + ly, 9, 22), 0.1)

	# Cadera
	p.begin(); p.m_rect(30, 50, 20, 6); p.end(pal.black)
	p.rect(37, 51, 6, 4, pal.yellow)

	# Alas-puerta (detrás de los hombros)
	for side in [-1, 1]:
		var wx: float = 40.0 + side * 21.0
		p.begin()
		p.m_poly([Vector2(wx + side * 3 + ox, 10 + oy), Vector2(wx - side * 3 + ox, 20 + oy),
			Vector2(wx - side * 3 + ox, 40 + oy), Vector2(wx + side * 4 + ox, 28 + oy)])
		p.end(pal.yellow)
		p.poly_px([Vector2(wx + side * 2 + ox, 14 + oy), Vector2(wx - side * 1 + ox, 20 + oy),
			Vector2(wx - side * 1 + ox, 27 + oy), Vector2(wx + side * 3 + ox, 22 + oy)], pal.glass)
		p.line_px(Vector2(wx + side * 4 + ox, 28 + oy), Vector2(wx - side * 3 + ox, 40 + oy), pal.black)

	# Brazo trasero
	_arm(p, pal, Vector2(21 + ox, 32 + oy), back + off, 0.0)

	# Torso
	p.begin()
	p.m_poly([Vector2(24 + ox, 26 + oy), Vector2(56 + ox, 26 + oy), Vector2(53 + ox, 51 + oy), Vector2(27 + ox, 51 + oy)])
	p.end(pal.yellow)
	p.begin()
	p.m_poly([Vector2(31 + ox, 28 + oy), Vector2(49 + ox, 28 + oy), Vector2(47 + ox, 42 + oy), Vector2(33 + ox, 42 + oy)])
	p.end(pal.black)
	for wx in [32, 41]:                                                          # parabrisas del pecho
		p.poly_px([Vector2(wx + 1 + ox, 30 + oy), Vector2(wx + 8 + ox, 30 + oy),
			Vector2(wx + 7 + ox, 38 + oy), Vector2(wx + 2 + ox, 38 + oy)], pal.glass)
		p.rect(wx + 1 + ox, 30 + oy, 7, 1, glass_light)
		p.line_px(Vector2(wx + 2 + ox, 37 + oy), Vector2(wx + 6 + ox, 31 + oy), Color(1, 1, 1, 0.8))
		p.rect(wx + 2 + ox, 38 + oy, 5, 1, glass_dark)
	p.rect(39 + ox, 28 + oy, 2, 14, pal.yellow)                                  # franja central
	p.begin(); p.m_rect(33 + ox, 42 + oy, 14, 8); p.end(pal.black)               # abdomen
	for ay in [44, 46, 48]:
		p.rect(34 + ox, ay + oy, 12, 1, pal.yellow.darkened(0.2))
	p.rect(26 + ox, 38 + oy, 5, 2, pal.black)                                    # franjas laterales
	p.rect(49 + ox, 38 + oy, 5, 2, pal.black)
	if detail == 1:
		p.line_px(Vector2(25 + ox, 28 + oy), Vector2(27 + ox, 49 + oy), pal.eye)
		p.line_px(Vector2(55 + ox, 28 + oy), Vector2(53 + ox, 49 + oy), pal.eye)
	elif detail == 2:
		p.line_px(Vector2(30 + ox, 28 + oy), Vector2(30 + ox, 50 + oy), pal.yellow.darkened(0.55))
		p.line_px(Vector2(50 + ox, 28 + oy), Vector2(50 + ox, 50 + oy), pal.yellow.darkened(0.55))
		_wear(p, Rect2i(24 + ox, 26 + oy, 32, 25), 0.12)

	# Hombreras
	for side in [-1, 1]:
		var sx: float = 40.0 + side * 19.0
		p.begin(); p.m_ellipse(sx + ox, 30 + oy, 6.6, 5.8); p.end(pal.yellow)
		p.begin(); p.m_rect(int(sx) - 4 + ox, 27 + oy, 8, 2); p.end(pal.black)

	# Cabeza
	p.begin(); p.m_rect(37 + ox, 22 + oy, 6, 4); p.end(pal.black)
	p.begin()
	p.m_poly([Vector2(34 + ox, 12 + oy), Vector2(46 + ox, 12 + oy), Vector2(47 + ox, 16 + oy),
		Vector2(46 + ox, 23 + oy), Vector2(34 + ox, 23 + oy), Vector2(33 + ox, 16 + oy)])
	p.end(pal.yellow)
	for side in [-1, 1]:                                                         # cuernos
		var hx: float = 40.0 + side * 6.0
		p.begin()
		p.m_poly([Vector2(hx + ox, 13 + oy), Vector2(hx + side * 2 + ox, 5 + oy),
			Vector2(hx + side * 5 + ox, 2 + oy), Vector2(hx + side * 4 + ox, 8 + oy),
			Vector2(hx + side * 3 + ox, 13 + oy)])
		p.end(pal.black)
		p.px(int(hx + side * 4) + ox, 3 + oy, pal.yellow)
	p.begin()                                                                    # máscara
	p.m_poly([Vector2(35 + ox, 17 + oy), Vector2(45 + ox, 17 + oy), Vector2(44 + ox, 26 + oy), Vector2(36 + ox, 26 + oy)])
	p.end(pal.silver)
	p.rect(35 + ox, 17 + oy, 4, 3, eye)                                          # ojos
	p.rect(41 + ox, 17 + oy, 4, 3, eye)
	p.px(36 + ox, 17 + oy, Color.WHITE)
	p.px(42 + ox, 17 + oy, Color.WHITE)
	p.rect(36 + ox, 22 + oy, 8, 1, pal.black)                                    # boca
	p.rect(38 + ox, 24 + oy, 4, 1, pal.black)
	p.rect(34 + ox, 14 + oy, 12, 2, pal.black)                                   # banda del casco
	p.rect(39 + ox, 12 + oy, 2, 3, pal.yellow)
	if detail == 2:
		_wear(p, Rect2i(33 + ox, 12 + oy, 14, 14), 0.1)

	# Brazo delantero
	_arm(p, pal, Vector2(59 + ox, 32 + oy), front + off, glow)

	p.outline()

	# Brillos del visor y energía
	if not pose.get("dead", false):
		for gx in range(34, 47):
			for gy in [16, 20]:
				p.px(gx + ox, gy + oy, Color(pal.eye.r, pal.eye.g, pal.eye.b, 0.22))
	if glow > 0.0:
		var f: Vector2 = front + off
		p.ellipse_px(f.x, f.y, 8, 7, Color(pal.energy.r, pal.energy.g, pal.energy.b, 0.28 * glow))
		for i in 6:
			var a := float(i) / 6.0 * TAU + 0.4
			p.line_px(f + Vector2(cos(a), sin(a)) * 6, f + Vector2(cos(a), sin(a)) * (10 + 4 * glow),
				Color(1, 1, 1, 0.7 * glow))
	if pose.has("shock"):
		var s: Dictionary = pose.shock
		var r: float = s.r
		var a: float = s.a
		p.ring_px(40 + ox, 75, r, r * 0.28, Color(pal.energy.r, pal.energy.g, pal.energy.b, a), 0.16)
		p.ring_px(40 + ox, 75, r * 0.72, r * 0.2, Color(1, 1, 1, a * 0.7), 0.14)
	if pose.has("punch_ring"):
		var f2: Vector2 = front + off
		p.ring_px(f2.x + 6, f2.y, 7, 11, Color(pal.energy.r, pal.energy.g, pal.energy.b, 0.8), 0.2)
		p.ring_px(f2.x + 10, f2.y, 5, 8, Color(1, 1, 1, 0.6), 0.2)
	return p


# ── CAMARO ────────────────────────────────────────────────────────────────────
# pose: bob, wheel, lunge, trail (bool), underglow (bool), shield (0..1)

static func car(pal: Dictionary, pose: Dictionary = {}) -> RefCounted:
	var p = _new(pal)
	var oy: int = pose.get("bob", 0)
	var ox: int = pose.get("lunge", 0)
	var wheel_a: float = pose.get("wheel", 0.0)
	var detail: int = pal.detail
	var glass_light: Color = pal.glass.lightened(0.45)
	var glass_dark: Color = pal.glass.darkened(0.45)
	var tire := Color("1b1d25")

	p.ellipse_px(40 + ox, 77, 38, 3, Color(0, 0, 0, 0.35))

	# Carrocería inferior
	p.begin()
	p.m_poly([Vector2(4 + ox, 64 + oy), Vector2(4 + ox, 51 + oy), Vector2(9 + ox, 46 + oy),
		Vector2(58 + ox, 46 + oy), Vector2(70 + ox, 49 + oy), Vector2(77 + ox, 54 + oy),
		Vector2(77 + ox, 64 + oy)])
	p.end(pal.yellow)
	# Cabina
	p.begin()
	p.m_poly([Vector2(23 + ox, 47 + oy), Vector2(31 + ox, 32 + oy), Vector2(50 + ox, 32 + oy), Vector2(61 + ox, 47 + oy)])
	p.end(pal.yellow)
	# Ventanas
	p.poly_px([Vector2(27 + ox, 46 + oy), Vector2(33 + ox, 35 + oy), Vector2(40 + ox, 35 + oy), Vector2(40 + ox, 46 + oy)], pal.glass)
	p.poly_px([Vector2(42 + ox, 46 + oy), Vector2(42 + ox, 35 + oy), Vector2(49 + ox, 35 + oy), Vector2(56 + ox, 46 + oy)], pal.glass)
	p.rect(33 + ox, 35 + oy, 17, 1, glass_light)
	p.rect(27 + ox, 45 + oy, 29, 1, glass_dark)
	p.line_px(Vector2(30 + ox, 44 + oy), Vector2(35 + ox, 37 + oy), Color(1, 1, 1, 0.8))
	p.line_px(Vector2(45 + ox, 44 + oy), Vector2(50 + ox, 37 + oy), Color(1, 1, 1, 0.7))
	p.rect(40 + ox, 35 + oy, 2, 11, pal.black)                                   # pilar
	# Franjas de carreras
	p.rect(31 + ox, 32 + oy, 19, 2, pal.black)                                   # techo
	p.poly_px([Vector2(58 + ox, 46 + oy), Vector2(70 + ox, 49 + oy), Vector2(72 + ox, 51 + oy), Vector2(58 + ox, 48 + oy)], pal.black)  # capó
	p.rect(6 + ox, 47 + oy, 18, 2, pal.black)                                    # maletero
	p.rect(5 + ox, 58 + oy, 72, 2, pal.black)                                    # lateral
	# Spoiler
	p.begin(); p.m_rect(3 + ox, 46 + oy, 8, 3); p.end(pal.black)
	p.rect(5 + ox, 49 + oy, 2, 2, pal.black)
	# Luces, parrilla, parachoques
	p.rect(4 + ox, 51 + oy, 3, 4, Color("e63232"))
	p.px(5 + ox, 52 + oy, Color(1, 0.7, 0.7))
	p.begin(); p.m_rect(75 + ox, 55 + oy, 3, 8); p.end(pal.black)
	for gy in [57, 59, 61]:
		p.rect(75 + ox, gy + oy, 3, 1, pal.silver)
	p.begin(); p.m_rect(73 + ox, 62 + oy, 5, 3); p.end(pal.silver)
	p.ellipse_px(73 + ox, 52 + oy, 2.6, 2.2, Color("fff4c2"))
	p.px(72 + ox, 51 + oy, Color.WHITE)
	# Puerta, manilla, retrovisor, logo
	p.line_px(Vector2(25 + ox, 47 + oy), Vector2(25 + ox, 62 + oy), pal.yellow.darkened(0.5))
	p.line_px(Vector2(56 + ox, 47 + oy), Vector2(58 + ox, 62 + oy), pal.yellow.darkened(0.5))
	p.line_px(Vector2(41 + ox, 47 + oy), Vector2(41 + ox, 62 + oy), pal.yellow.darkened(0.5))
	p.rect(45 + ox, 51 + oy, 4, 1, pal.silver)
	p.rect(53 + ox, 42 + oy, 4, 3, pal.black)
	p.poly_px([Vector2(29 + ox, 51 + oy), Vector2(35 + ox, 51 + oy), Vector2(34 + ox, 57 + oy), Vector2(30 + ox, 57 + oy)], Color("d33"))
	p.rect(30 + ox, 53 + oy, 1, 1, pal.eye)
	p.rect(33 + ox, 53 + oy, 1, 1, pal.eye)
	if detail == 1:
		p.line_px(Vector2(5 + ox, 61 + oy), Vector2(77 + ox, 61 + oy), pal.eye)
		p.line_px(Vector2(27 + ox, 36 + oy), Vector2(56 + ox, 46 + oy), pal.eye.darkened(0.35))
	elif detail == 2:
		_wear(p, Rect2i(4 + ox, 32 + oy, 74, 32), 0.1)

	# Ruedas con pasos de rueda
	for cx in [19, 58]:
		p.begin(); p.m_ellipse(cx + ox, 64, 10.5, 9.5); p.end(pal.black, false)
		p.begin(); p.m_ellipse(cx + ox, 68, 8.0, 8.0); p.end(tire, false)
		p.begin(); p.m_ellipse(cx + ox, 68, 5.0, 5.0); p.end(pal.silver)
		for sp in 5:
			var a: float = deg_to_rad(wheel_a + sp * 72.0)
			p.line_px(Vector2(cx + ox, 68), Vector2(cx + ox, 68) + Vector2(cos(a), sin(a)) * 4.5, pal.black)
		p.begin(); p.m_ellipse(cx + ox, 68, 1.6, 1.6); p.end(pal.black)
		p.px(cx + ox, 68, pal.silver)

	p.outline()

	# Efectos
	if pose.get("underglow", false):
		for x in range(8, 74):
			p.px(x + ox, 76, Color(pal.energy.r, pal.energy.g, pal.energy.b, 0.45))
			p.px(x + ox, 75, Color(pal.energy.r, pal.energy.g, pal.energy.b, 0.2))
	p.ellipse_px(76 + ox, 52 + oy, 5, 4, Color(1, 0.95, 0.6, 0.18))
	if pose.get("trail", false):
		for i in 6:
			var y := 40 + i * 6
			p.line_px(Vector2(-2 + ox, y), Vector2(-16 - i * 2 + ox, y), Color(pal.energy.r, pal.energy.g, pal.energy.b, 0.6 - i * 0.07))
		p.line_px(Vector2(-4 + ox, 56), Vector2(-24 + ox, 56), Color(1, 1, 1, 0.55))
	if pose.get("burst", false):
		for i in 3:
			p.ring_px(80 + ox + i * 4, 56, 6 + i * 4, 15 + i * 4, Color(pal.energy.r, pal.energy.g, pal.energy.b, 0.75 - i * 0.2), 0.22)
	var sh: float = pose.get("shield", 0.0)
	if sh > 0.0:
		p.ring_px(40 + ox, 56, 44, 30, Color(0.6, 1, 1, 0.6 * sh), 0.1)
		p.ellipse_px(40 + ox, 56, 43, 29, Color(0.5, 0.95, 1, 0.1 * sh))
	return p
