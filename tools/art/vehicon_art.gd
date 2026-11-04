# vehicon_art.gd
# Herramienta de desarrollo: diseño procedural del Vehicon (soldado Decepticon).
# SRP: solo define cómo se DIBUJA el Vehicon y sus animaciones.
# Coordenadas de dibujo: 64x64 (pies en y=61). Lienzo real 80x72 con margen.

extends RefCounted

const P := preload("res://tools/art/painter.gd")

const CANVAS := Vector2i(80, 72)
const SHIFT := Vector2i(8, 8)

const PURPLE := Color("5e2d86")
const DARK := Color("30323f")
const SILVER := Color("a9b0bd")
const EYE := Color("ff3535")


static func _new() -> RefCounted:
	var p = P.new(CANVAS.x, CANVAS.y, SHIFT.x, SHIFT.y)
	p.grain = 0.1
	p.seed_val = 7
	return p


static func _rot(pt: Vector2, deg: float, origin: Vector2) -> Vector2:
	var a := deg_to_rad(deg)
	return origin + Vector2(pt.x * cos(a) - pt.y * sin(a), pt.x * sin(a) + pt.y * cos(a))


# pose: bob, stride, lean, blade (grados), dead
static func vehicon(pose: Dictionary = {}) -> RefCounted:
	var p = _new()
	var ox: int = pose.get("lean", 0)
	var oy: int = pose.get("bob", 0)
	var stride: int = pose.get("stride", 0)
	var blade_deg: float = pose.get("blade", 70.0)
	var eye: Color = Color("3a2a2a") if pose.get("dead", false) else EYE

	p.ellipse_px(32, 61, 16, 2.5, Color(0, 0, 0, 0.35))

	# Propulsores traseros
	for side in [-1, 1]:
		var bx: int = 32 + side * 12
		p.begin()
		p.m_poly([Vector2(bx - 3 * side + ox, 16 + oy), Vector2(bx + 3 * side + ox, 12 + oy),
			Vector2(bx + 4 * side + ox, 30 + oy), Vector2(bx - 2 * side + ox, 32 + oy)])
		p.end(DARK)
		p.rect(bx - 1 + ox, 14 + oy, 2, 3, Color("ff8a3a"))

	# Piernas
	for side in [-1, 1]:
		var s: int = stride * side
		var lx: int = 32 + side * 6 + s * 2
		var ly: int = -2 if s > 0 else 0
		p.begin(); p.m_rect(lx - 4, 40 + ly, 8, 8); p.end(DARK)
		p.begin(); p.m_poly([Vector2(lx - 3, 47 + ly), Vector2(lx + 3, 47 + ly), Vector2(lx + 3, 57 + ly), Vector2(lx - 3, 57 + ly)]); p.end(PURPLE)
		p.poly_px([Vector2(lx - 1, 46 + ly), Vector2(lx + 5, 48 + ly), Vector2(lx - 1, 51 + ly)], SILVER)   # pincho rodilla
		p.begin(); p.m_poly([Vector2(lx - 5, 56 + ly), Vector2(lx + 3, 56 + ly), Vector2(lx + 7, 59 + ly), Vector2(lx + 7, 61 + ly), Vector2(lx - 5, 61 + ly)]); p.end(DARK)
		p.rect(lx - 3, 50 + ly, 6, 1, PURPLE.darkened(0.4))

	# Cadera
	p.begin(); p.m_rect(25, 38, 14, 4); p.end(DARK)

	# Brazo trasero con garra
	p.begin(); p.m_rect(12 + ox, 26 + oy, 7, 9); p.end(DARK)
	p.begin(); p.m_rect(11 + ox, 35 + oy, 7, 8); p.end(PURPLE)
	for k in 3:
		p.poly_px([Vector2(10 + k * 3 + ox, 43 + oy), Vector2(13 + k * 3 + ox, 43 + oy), Vector2(11 + k * 3 + ox, 50 + oy)], SILVER)

	# Torso
	p.begin()
	p.m_poly([Vector2(18 + ox, 22 + oy), Vector2(46 + ox, 22 + oy), Vector2(43 + ox, 41 + oy), Vector2(21 + ox, 41 + oy)])
	p.end(PURPLE)
	# Emblema Decepticon
	p.poly_px([Vector2(27 + ox, 25 + oy), Vector2(37 + ox, 25 + oy), Vector2(36 + ox, 33 + oy),
		Vector2(32 + ox, 37 + oy), Vector2(28 + ox, 33 + oy)], SILVER)
	p.poly_px([Vector2(26 + ox, 25 + oy), Vector2(28 + ox, 21 + oy), Vector2(30 + ox, 25 + oy)], SILVER)
	p.poly_px([Vector2(34 + ox, 25 + oy), Vector2(36 + ox, 21 + oy), Vector2(38 + ox, 25 + oy)], SILVER)
	p.rect(29 + ox, 28 + oy, 2, 2, PURPLE.darkened(0.3))
	p.rect(33 + ox, 28 + oy, 2, 2, PURPLE.darkened(0.3))
	p.rect(31 + ox, 33 + oy, 2, 1, PURPLE.darkened(0.3))
	# Paneles
	p.line_px(Vector2(21 + ox, 32 + oy), Vector2(26 + ox, 32 + oy), PURPLE.darkened(0.45))
	p.line_px(Vector2(38 + ox, 32 + oy), Vector2(43 + ox, 32 + oy), PURPLE.darkened(0.45))
	p.rect(24 + ox, 38 + oy, 16, 2, DARK)

	# Hombrera trasera con pinchos
	p.begin(); p.m_ellipse(17 + ox, 25 + oy, 6.2, 5.2); p.end(DARK)
	p.poly_px([Vector2(12 + ox, 22 + oy), Vector2(14 + ox, 13 + oy), Vector2(18 + ox, 22 + oy)], SILVER)

	# Cabeza
	p.begin(); p.m_rect(29 + ox, 19 + oy, 6, 4); p.end(DARK)
	p.begin()
	p.m_poly([Vector2(25 + ox, 5 + oy), Vector2(39 + ox, 5 + oy), Vector2(41 + ox, 11 + oy),
		Vector2(40 + ox, 20 + oy), Vector2(24 + ox, 20 + oy), Vector2(23 + ox, 11 + oy)])
	p.end(DARK)
	p.poly_px([Vector2(22 + ox, 12 + oy), Vector2(19 + ox, 1 + oy), Vector2(26 + ox, 8 + oy)], DARK.lightened(0.15))   # cuernos
	p.poly_px([Vector2(42 + ox, 12 + oy), Vector2(45 + ox, 1 + oy), Vector2(38 + ox, 8 + oy)], DARK.lightened(0.15))
	p.rect(26 + ox, 10 + oy, 12, 4, eye)                                          # visor
	p.rect(27 + ox, 11 + oy, 10, 1, Color(1, 0.85, 0.8) if not pose.get("dead", false) else eye)
	p.begin(); p.m_rect(27 + ox, 16 + oy, 10, 4); p.end(SILVER)                   # mentón
	p.rect(28 + ox, 17 + oy, 8, 1, DARK)
	p.rect(28 + ox, 19 + oy, 8, 1, DARK)

	# Brazo delantero con cuchilla
	var shoulder := Vector2(47 + ox, 26 + oy)
	var hand := Vector2(50 + ox, 38 + oy) + Vector2(pose.get("reach", 0.0), 0.0)
	p.begin(); p.m_line(shoulder, hand, 6); p.end(PURPLE)
	p.begin(); p.m_ellipse(47 + ox, 25 + oy, 6.2, 5.2); p.end(DARK)
	p.poly_px([Vector2(46 + ox, 22 + oy), Vector2(50 + ox, 13 + oy), Vector2(52 + ox, 22 + oy)], SILVER)
	var blade_local := [Vector2(0, -3), Vector2(16, -2), Vector2(25, 2), Vector2(16, 3), Vector2(0, 3)]
	var pts: Array = []
	for bp in blade_local:
		pts.append(_rot(bp, blade_deg, hand))
	p.begin(); p.m_poly(pts); p.end(SILVER)
	p.line_px(_rot(Vector2(4, 0), blade_deg, hand), _rot(Vector2(22, 1), blade_deg, hand), Color("ff6a6a"))
	p.begin(); p.m_ellipse(hand.x, hand.y, 3.6, 3.4); p.end(DARK)

	p.outline()
	if not pose.get("dead", false):
		for gx in range(26, 38):
			p.px(gx + ox, 9 + oy, Color(1, 0.2, 0.2, 0.22))
			p.px(gx + ox, 14 + oy, Color(1, 0.2, 0.2, 0.22))
	if pose.has("trail"):
		var t: Dictionary = pose.trail
		var outer: Array = []
		var inner: Array = []
		for i in 8:
			var a: float = lerpf(t.from, t.to, float(i) / 7.0)
			outer.append(hand + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 30.0)
			inner.append(hand + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 14.0)
		inner.reverse()
		p.poly_px(outer + inner, Color(1.0, 0.45, 0.45, 0.4))
	return p


static func _wrap(image: Image) -> RefCounted:
	var w = P.new(image.get_width(), image.get_height())
	w.img = image
	return w


static func all_anims() -> Dictionary:
	var anims := {}

	var idle: Array = []
	for i in 4:
		idle.append(vehicon({"bob": [0, -1, -1, 0][i], "blade": 70.0 + i}).img)
	anims["idle"] = idle

	var walk: Array = []
	var strides := [1, 1, 0, -1, -1, 0]
	var bobs := [0, -1, 0, 0, -1, 0]
	for i in 6:
		walk.append(vehicon({"stride": strides[i], "bob": bobs[i], "lean": 1}).img)
	anims["walk"] = walk

	var attack: Array = []
	var atk := [
		{"blade": -60.0, "lean": -2, "reach": -2.0},
		{"blade": -20.0, "lean": 0, "reach": 2.0},
		{"blade": 40.0, "lean": 3, "reach": 6.0, "trail": {"from": -40.0, "to": 40.0}},
		{"blade": 75.0, "lean": 1, "reach": 3.0},
	]
	for pose in atk:
		attack.append(vehicon(pose).img)
	anims["attack"] = attack

	# Muerte: parpadea, cae hacia atrás y explota dejando humo.
	var death: Array = []
	var rots := [0.0, -10.0, -32.0, -62.0, -85.0, -90.0]
	for i in 6:
		var vp = vehicon({"lean": -i if i < 3 else -3, "blade": 80.0 - i * 20.0, "dead": i >= 2})
		if i == 0:
			vp.tint(Color.WHITE, 0.6)
		vp.desaturate([0.0, 0.1, 0.3, 0.5, 0.65, 0.75][i])
		var im: Image = vp.img
		if rots[i] != 0.0:
			im = P.xform(im, 1.0, 1.0, Vector2(40, 48), rots[i])
			im = P.ground(im, 69, 40)
		var w = _wrap(im)
		if i >= 3:
			w.fade([1.0, 1.0, 1.0, 0.9, 0.4, 0.0][i])
			var r: float = [0.0, 0.0, 0.0, 12.0, 22.0, 20.0][i]
			var al: float = [0.0, 0.0, 0.0, 0.9, 0.7, 0.0][i]
			if al > 0.0:
				w.ellipse_px(40, 48, r, r * 0.9, Color(0.9, 0.2, 0.1, al * 0.8))
				w.ellipse_px(40, 48, r * 0.78, r * 0.7, Color(1.0, 0.55, 0.1, al))
				w.ellipse_px(40, 48, r * 0.5, r * 0.45, Color(1.0, 0.9, 0.4, al))
				w.ellipse_px(40, 48, r * 0.22, r * 0.2, Color(1, 1, 1, al))
			if i == 5:
				w.ellipse_px(36, 52, 7, 5, Color(0.28, 0.28, 0.3, 0.55))
				w.ellipse_px(46, 46, 6, 5, Color(0.32, 0.32, 0.34, 0.45))
				w.ellipse_px(40, 38, 5, 4, Color(0.36, 0.36, 0.38, 0.35))
				for k in 7:
					w.px(26 + k * 4, 66 - (k % 3), DARK)            # chatarra
					w.px(27 + k * 4, 66 - (k % 3), PURPLE.darkened(0.3))
		if i > 0 and i < 4:
			var rng := RandomNumberGenerator.new()
			rng.seed = 40 + i
			for k in 8:
				w.px(rng.randi_range(18, 64), rng.randi_range(14, 66),
					[Color("fff6a8"), Color("ffb347"), Color.WHITE][rng.randi() % 3])
		death.append(w.img)
	anims["death"] = death
	return anims
