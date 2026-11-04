# arcee_art.gd
# Herramienta de desarrollo: diseño procedural de Arcee (robot con cuchillas o pistolas, y moto).
# SRP: solo define cómo se DIBUJA Arcee; no sabe de SpriteFrames.
# Coordenadas de dibujo: 80x80 (pies en y=77). Lienzo real 144x96 con margen.
# Puntas de las pistolas (modo a distancia): ~ (79, 44) en coordenadas de dibujo.

extends RefCounted

const P := preload("res://tools/art/painter.gd")

const CANVAS := Vector2i(144, 96)
const SHIFT := Vector2i(32, 16)

# detail: 0 = limpio (G1), 1 = costuras luminosas (Prime), 2 = desgaste (Bay).
const SKINS := {
	"g1": {
		"body": Color("e8488e"), "accent": Color("f5f0f6"), "dark": Color("5a2748"),
		"silver": Color("c7ccd8"), "eye": Color("69d8ff"), "glass": Color("8fdcff"),
		"glow": Color("57e6ff"), "blade": Color("d8f6ff"),
		"grain": 0.0, "detail": 0, "seed": 41,
	},
	"prime": {
		"body": Color("3f6fd6"), "accent": Color("e5559c"), "dark": Color("1f2a52"),
		"silver": Color("a8b4c8"), "eye": Color("45e6ff"), "glass": Color("55c8ff"),
		"glow": Color("30e0ff"), "blade": Color("c8f1ff"),
		"grain": 0.05, "detail": 1, "seed": 42,
	},
	"bay": {
		"body": Color("5a3a52"), "accent": Color("b0407a"), "dark": Color("1e1822"),
		"silver": Color("7a8190"), "eye": Color("ff6aa8"), "glass": Color("5a7d98"),
		"glow": Color("ff6aa8"), "blade": Color("b9c4d4"),
		"grain": 0.16, "detail": 2, "seed": 43,
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
			var r: float = p._hash(x + 53, y + 23)
			var a: Color = p.img.get_pixel(x + p.tx, y + p.ty)
			if a.a < 0.9:
				continue
			if r > 1.0 - amount * 0.5:
				p.px(x, y, a.lightened(0.28))
				p.px(x + 1, y + 1, a.lightened(0.16))
			elif r < amount * 0.25:
				p.px(x, y, Color("6b3a1e"))


static func _elbow(shoulder: Vector2, target: Vector2, len1: float, len2: float) -> Vector2:
	var d := shoulder.distance_to(target)
	d = clampf(d, 1.0, len1 + len2 - 0.5)
	var dir := (target - shoulder).normalized()
	var a := (len1 * len1 - len2 * len2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(len1 * len1 - a * a, 0.0))
	var perp := Vector2(-dir.y, dir.x)
	if perp.y < 0.0:
		perp = -perp
	return shoulder + dir * a + perp * h


## Brazo con IK. mode "melee": cuchilla en el antebrazo. mode "ranged": pistola en la mano.
static func _arm(p, pal: Dictionary, shoulder: Vector2, target: Vector2, mode: String, extend: float) -> void:
	var elbow := _elbow(shoulder, target, 10.5, 10.5)
	p.begin(); p.m_line(shoulder, elbow, 5); p.end(pal.body)
	p.begin(); p.m_line(elbow, target, 5); p.end(pal.silver)
	p.begin(); p.m_ellipse(elbow.x, elbow.y, 3.2, 3.2); p.end(pal.dark)
	var dir := (target - elbow).normalized()
	var nrm := Vector2(-dir.y, dir.x)
	if mode == "melee":
		# Cuchilla de energon a lo largo del antebrazo.
		var base := target - dir * 3.0
		var tip := target + dir * (8.0 + 12.0 * extend)
		p.begin()
		p.m_poly([base + nrm * 2.5, tip, base - nrm * 1.5])
		p.end(pal.blade)
		p.line_px(base + nrm * 2.0, tip, pal.glow)
		p.begin(); p.m_ellipse(target.x, target.y, 3.6, 3.4); p.end(pal.dark)
	else:
		p.begin(); p.m_ellipse(target.x, target.y, 3.4, 3.2); p.end(pal.silver)
		p.begin(); p.m_rect(int(target.x) - 1, int(target.y) - 3, 11, 5); p.end(pal.dark)   # pistola
		p.rect(int(target.x) + 7, int(target.y) - 2, 5, 3, pal.silver)
		p.px(int(target.x) + 11, int(target.y) - 1, pal.glow)
		p.rect(int(target.x) + 1, int(target.y) - 2, 4, 1, pal.accent)


# ── ROBOT ─────────────────────────────────────────────────────────────────────
# pose: mode ("melee"|"ranged"), bob, lean, kneel, stride, front, back, extend,
#       flash (0..1), recoil, slash (0..1), dead

static func robot(pal: Dictionary, pose: Dictionary = {}) -> RefCounted:
	var p = _new(pal)
	var mode: String = pose.get("mode", "melee")
	var ox: int = pose.get("lean", 0)
	var oy: int = pose.get("bob", 0) + pose.get("kneel", 0)
	var stride: int = pose.get("stride", 0)
	var detail: int = pal.detail
	var eye: Color = Color("2a2d38") if pose.get("dead", false) else pal.eye
	var glass_light: Color = pal.glass.lightened(0.45)
	var glass_dark: Color = pal.glass.darkened(0.45)
	var front: Vector2 = pose.get("front", Vector2(61, 52) if mode == "melee" else Vector2(66, 44))
	var back: Vector2 = pose.get("back", Vector2(19, 52) if mode == "melee" else Vector2(58, 48))
	var off := Vector2(ox, oy)

	p.ellipse_px(40, 77, 19, 3, Color(0, 0, 0, 0.35))

	# Ruedas de moto en la espalda
	for sx in [21, 59]:
		p.begin(); p.m_ellipse(sx + ox, 31 + oy, 5.0, 12.0); p.end(pal.dark)
		p.begin(); p.m_ellipse(sx + ox, 31 + oy, 2.6, 7.4); p.end(pal.silver)
		p.px(sx + ox, 31 + oy, pal.dark)

	# Piernas
	for side in [-1, 1]:
		var s: int = stride * side
		var lx: int = 40 + side * 6 + s * 3
		var ly: int = -2 if s > 0 else 0
		p.begin(); p.m_rect(lx - 3, 52 + ly, 7, 10); p.end(pal.body)
		p.begin(); p.m_ellipse(lx, 62 + ly, 3.6, 3.0); p.end(pal.silver)
		p.begin(); p.m_rect(lx - 3, 64 + ly, 6, 9); p.end(pal.accent)
		p.rect(lx - 3, 67 + ly, 6, 1, pal.body)
		p.begin()
		p.m_poly([Vector2(lx - 4, 72 + ly), Vector2(lx + 3, 72 + ly), Vector2(lx + 7, 75 + ly),
			Vector2(lx + 7, 77 + ly), Vector2(lx - 4, 77 + ly)])
		p.end(pal.dark)
		if detail == 1:
			p.line_px(Vector2(lx - 1, 53 + ly), Vector2(lx - 1, 61 + ly), pal.glow)
		elif detail == 2:
			_wear(p, Rect2i(lx - 3, 52 + ly, 8, 25), 0.1)

	# Cadera
	p.begin(); p.m_rect(32, 49, 16, 5); p.end(pal.dark)
	p.rect(38, 50, 4, 3, pal.accent)

	# Brazo trasero
	_arm(p, pal, Vector2(30 + ox, 32 + oy), back + off, mode, pose.get("extend", 0.0))

	# Torso estilizado
	p.begin()
	p.m_poly([Vector2(29 + ox, 26 + oy), Vector2(51 + ox, 26 + oy), Vector2(48 + ox, 47 + oy), Vector2(32 + ox, 47 + oy)])
	p.end(pal.body)
	p.poly_px([Vector2(33 + ox, 28 + oy), Vector2(47 + ox, 28 + oy), Vector2(45 + ox, 37 + oy), Vector2(35 + ox, 37 + oy)], pal.glass)
	p.rect(33 + ox, 28 + oy, 14, 1, glass_light)
	p.rect(35 + ox, 36 + oy, 10, 1, glass_dark)
	p.line_px(Vector2(36 + ox, 35 + oy), Vector2(41 + ox, 29 + oy), Color(1, 1, 1, 0.85))
	p.line_px(Vector2(40 + ox, 28 + oy), Vector2(40 + ox, 36 + oy), pal.dark)
	p.begin(); p.m_rect(34 + ox, 39 + oy, 12, 8); p.end(pal.accent)               # abdomen
	p.rect(35 + ox, 41 + oy, 10, 1, pal.body)
	p.rect(35 + ox, 44 + oy, 10, 1, pal.body)
	p.begin(); p.m_rect(34 + ox, 46 + oy, 12, 3); p.end(pal.dark)                  # cintura
	if detail == 1:
		p.line_px(Vector2(30 + ox, 28 + oy), Vector2(33 + ox, 46 + oy), pal.glow)
		p.line_px(Vector2(50 + ox, 28 + oy), Vector2(47 + ox, 46 + oy), pal.glow)
	elif detail == 2:
		_wear(p, Rect2i(29 + ox, 26 + oy, 22, 22), 0.12)

	# Hombreras
	for side in [-1, 1]:
		var sx: float = 40.0 + side * 12.0
		p.begin(); p.m_ellipse(sx + ox, 30 + oy, 5.2, 4.6); p.end(pal.accent)

	# Cabeza con cresta hacia atrás
	p.begin(); p.m_rect(37 + ox, 22 + oy, 6, 4); p.end(pal.dark)
	p.begin()
	p.m_poly([Vector2(32 + ox, 10 + oy), Vector2(45 + ox, 9 + oy), Vector2(47 + ox, 15 + oy),
		Vector2(45 + ox, 22 + oy), Vector2(35 + ox, 22 + oy), Vector2(32 + ox, 16 + oy)])
	p.end(pal.body)
	p.poly_px([Vector2(33 + ox, 10 + oy), Vector2(24 + ox, 6 + oy), Vector2(13 + ox, 12 + oy),
		Vector2(22 + ox, 14 + oy), Vector2(33 + ox, 15 + oy)], pal.accent)           # cresta-coleta
	p.poly_px([Vector2(33 + ox, 11 + oy), Vector2(24 + ox, 8 + oy), Vector2(17 + ox, 11 + oy), Vector2(24 + ox, 11 + oy)], pal.body)
	p.begin(); p.m_poly([Vector2(35 + ox, 14 + oy), Vector2(45 + ox, 14 + oy), Vector2(44 + ox, 22 + oy), Vector2(36 + ox, 22 + oy)]); p.end(pal.silver)
	p.rect(36 + ox, 15 + oy, 3, 2, eye)                                           # ojos
	p.rect(41 + ox, 15 + oy, 3, 2, eye)
	p.px(37 + ox, 15 + oy, Color.WHITE)
	p.px(42 + ox, 15 + oy, Color.WHITE)
	p.rect(37 + ox, 19 + oy, 6, 1, pal.dark)
	p.rect(38 + ox, 20 + oy, 4, 1, pal.accent)
	p.line_px(Vector2(44 + ox, 10 + oy), Vector2(47 + ox, 3 + oy), pal.silver)    # antena
	if detail == 2:
		_wear(p, Rect2i(32 + ox, 9 + oy, 15, 14), 0.1)

	# Brazo delantero
	_arm(p, pal, Vector2(50 + ox, 32 + oy), front + off, mode, pose.get("extend", 0.0))

	p.outline()

	if not pose.get("dead", false):
		for gx in range(35, 46):
			p.px(gx + ox, 14 + oy, Color(pal.eye.r, pal.eye.g, pal.eye.b, 0.22))
			p.px(gx + ox, 18 + oy, Color(pal.eye.r, pal.eye.g, pal.eye.b, 0.22))

	# Ráfagas
	var flash: float = pose.get("flash", 0.0)
	if flash > 0.0 and mode == "ranged":
		for tip in [front + off, back + off]:
			var mx: float = tip.x + 13
			var my: float = tip.y - 1
			p.ellipse_px(mx + 1, my, 4 * flash + 1, 3 * flash + 1, Color(pal.accent.r, pal.accent.g, pal.accent.b, 0.55))
			p.poly_px([Vector2(mx, my - 2), Vector2(mx + 8 * flash, my), Vector2(mx, my + 2)], Color(1, 0.9, 0.97, 0.95))
	var slash: float = pose.get("slash", 0.0)
	if slash > 0.0 and mode == "melee":
		# Tajo en X delante del cuerpo.
		var c := Vector2(40 + ox + 6, 38 + oy)
		for dir in [1, -1]:
			var a := c + Vector2(-26, -20 * dir) * slash
			var b := c + Vector2(26, 20 * dir) * slash
			for w in [3, 2, 1]:
				p.line_px(a + Vector2(0, w * 0.5), b + Vector2(0, w * 0.5), Color(0.8, 0.97, 1.0, 0.18 * (4 - w)))
				p.line_px(a - Vector2(0, w * 0.5), b - Vector2(0, w * 0.5), Color(0.8, 0.97, 1.0, 0.18 * (4 - w)))
			p.line_px(a, b, Color(1, 1, 1, 0.9))
		for i in 7:
			var sa: float = float(i) / 7.0 * TAU + slash
			p.px(int(c.x + cos(sa) * 26 * slash), int(c.y + sin(sa) * 20 * slash), Color(1, 1, 1, 0.9))
	return p


# ── MOTO ──────────────────────────────────────────────────────────────────────
# pose: bob, wheel, lunge, trail, slash (0..1)

static func bike(pal: Dictionary, pose: Dictionary = {}) -> RefCounted:
	var p = _new(pal)
	var oy: int = pose.get("bob", 0)
	var ox: int = pose.get("lunge", 0)
	var wheel_a: float = pose.get("wheel", 0.0)
	var detail: int = pal.detail
	var glass_light: Color = pal.glass.lightened(0.45)
	var tire := Color("191b23")

	p.ellipse_px(40 + ox, 77, 36, 3, Color(0, 0, 0, 0.35))

	# Horquilla y basculante
	p.line_px(Vector2(60 + ox, 44 + oy), Vector2(66 + ox, 66), pal.silver)
	p.line_px(Vector2(61 + ox, 44 + oy), Vector2(67 + ox, 66), pal.silver)
	p.line_px(Vector2(16 + ox, 58 + oy), Vector2(14 + ox, 66), pal.silver)
	p.line_px(Vector2(17 + ox, 58 + oy), Vector2(15 + ox, 66), pal.silver)

	# Ruedas
	for cx in [14, 66]:
		p.begin(); p.m_ellipse(cx + ox, 66, 11.0, 11.0); p.end(tire, false)
		p.begin(); p.m_ellipse(cx + ox, 66, 7.0, 7.0); p.end(pal.silver)
		for sp in 6:
			var a: float = deg_to_rad(wheel_a + sp * 60.0)
			p.line_px(Vector2(cx + ox, 66), Vector2(cx + ox, 66) + Vector2(cos(a), sin(a)) * 6.5, pal.dark)
		p.begin(); p.m_ellipse(cx + ox, 66, 2.2, 2.2); p.end(pal.accent)
		p.px(cx + ox, 66, pal.silver)

	# Carenado inferior y motor
	p.begin()
	p.m_poly([Vector2(16 + ox, 62 + oy), Vector2(24 + ox, 52 + oy), Vector2(48 + ox, 50 + oy),
		Vector2(58 + ox, 54 + oy), Vector2(66 + ox, 62 + oy), Vector2(54 + ox, 67 + oy), Vector2(28 + ox, 67 + oy)])
	p.end(pal.body)
	p.begin(); p.m_rect(30 + ox, 56 + oy, 18, 8); p.end(pal.dark)                  # motor
	for ex in [32, 37, 42]:
		p.rect(ex + ox, 57 + oy, 2, 6, pal.silver.darkened(0.3))
	p.begin(); p.m_poly([Vector2(6 + ox, 58 + oy), Vector2(28 + ox, 60 + oy), Vector2(28 + ox, 63 + oy), Vector2(6 + ox, 62 + oy)]); p.end(pal.silver)  # escape
	# Depósito y carenado superior
	p.begin()
	p.m_poly([Vector2(26 + ox, 52 + oy), Vector2(34 + ox, 41 + oy), Vector2(50 + ox, 40 + oy), Vector2(58 + ox, 52 + oy)])
	p.end(pal.accent)
	p.rect(36 + ox, 41 + oy, 12, 1, glass_light)
	p.line_px(Vector2(38 + ox, 49 + oy), Vector2(44 + ox, 43 + oy), Color(1, 1, 1, 0.8))
	# Asiento y cola
	p.begin(); p.m_poly([Vector2(6 + ox, 51 + oy), Vector2(30 + ox, 47 + oy), Vector2(32 + ox, 53 + oy), Vector2(10 + ox, 57 + oy)]); p.end(pal.dark)
	p.begin(); p.m_poly([Vector2(5 + ox, 49 + oy), Vector2(12 + ox, 47 + oy), Vector2(10 + ox, 54 + oy), Vector2(4 + ox, 55 + oy)]); p.end(pal.accent)
	p.rect(4 + ox, 50 + oy, 2, 3, Color("ff3b4a"))
	# Parabrisas y manillar
	p.poly_px([Vector2(55 + ox, 50 + oy), Vector2(60 + ox, 37 + oy), Vector2(66 + ox, 40 + oy), Vector2(62 + ox, 51 + oy)], pal.glass)
	p.line_px(Vector2(57 + ox, 49 + oy), Vector2(61 + ox, 40 + oy), Color(1, 1, 1, 0.8))
	p.line_px(Vector2(60 + ox, 38 + oy), Vector2(67 + ox, 37 + oy), pal.silver)
	p.rect(66 + ox, 36 + oy, 3, 2, pal.dark)
	# Faro y morro
	p.begin(); p.m_poly([Vector2(62 + ox, 50 + oy), Vector2(72 + ox, 50 + oy), Vector2(76 + ox, 56 + oy), Vector2(64 + ox, 58 + oy)]); p.end(pal.body)
	p.ellipse_px(72 + ox, 52 + oy, 2.4, 2.0, Color("fff6c8"))
	p.px(71 + ox, 51 + oy, Color.WHITE)
	# Logo Autobot
	p.poly_px([Vector2(38 + ox, 55 + oy), Vector2(44 + ox, 55 + oy), Vector2(43 + ox, 60 + oy), Vector2(41 + ox, 62 + oy), Vector2(39 + ox, 60 + oy)], pal.accent)
	if detail == 1:
		p.line_px(Vector2(18 + ox, 63 + oy), Vector2(64 + ox, 63 + oy), pal.glow)
		p.line_px(Vector2(28 + ox, 48 + oy), Vector2(54 + ox, 48 + oy), pal.glow.darkened(0.3))
	elif detail == 2:
		_wear(p, Rect2i(4 + ox, 36 + oy, 76, 34), 0.1)

	p.outline()

	for x in range(8, 70):
		p.px(x + ox, 76, Color(pal.accent.r, pal.accent.g, pal.accent.b, 0.4))
		p.px(x + ox, 75, Color(pal.accent.r, pal.accent.g, pal.accent.b, 0.18))
	p.ellipse_px(75 + ox, 52 + oy, 5, 4, Color(1, 0.95, 0.7, 0.18))
	if pose.get("trail", false):
		for i in 5:
			var y := 44 + i * 6
			p.line_px(Vector2(-2 + ox, y), Vector2(-14 - i * 2 + ox, y), Color(pal.accent.r, pal.accent.g, pal.accent.b, 0.55 - i * 0.08))
	var slash: float = pose.get("slash", 0.0)
	if slash > 0.0:
		# Estela cortante del dash: arco luminoso delante y estela blanca detrás.
		p.line_px(Vector2(-10 + ox, 56), Vector2(30 + ox, 56), Color(0.85, 0.97, 1.0, 0.7 * slash))
		p.line_px(Vector2(-20 + ox, 59), Vector2(24 + ox, 59), Color(1, 1, 1, 0.5 * slash))
		var pts: Array = []
		for i in 9:
			var a: float = lerpf(-1.2, 1.2, float(i) / 8.0)
			pts.append(Vector2(78 + ox + cos(a) * 12 * slash, 56 + sin(a) * 26 * slash))
		for i in range(8, -1, -1):
			var a2: float = lerpf(-1.2, 1.2, float(i) / 8.0)
			pts.append(Vector2(78 + ox + cos(a2) * 6 * slash, 56 + sin(a2) * 22 * slash))
		p.poly_px(pts, Color(0.8, 0.97, 1.0, 0.65 * slash))
	return p
