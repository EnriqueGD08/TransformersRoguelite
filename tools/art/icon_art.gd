# icon_art.gd
# Herramienta de desarrollo: iconos pixel art 32x32 del árbol de habilidades.
# SRP: solo dibuja iconos. Se dibujan en tonos neutros claros; la interfaz los tiñe
#      con el color de cada rama (ataque, transformación, defensa).

extends RefCounted

const P := preload("res://tools/art/painter.gd")

const LIGHT := Color("eef1f8")
const MID := Color("b9c0d3")
const DARK := Color("7d86a0")

const ICONS := ["heart", "heart_plus", "boot", "sword", "crosshair", "shield", "feather", "cross",
	"star", "bullets", "hourglass", "clock", "gear", "drop", "skull", "burst", "bolt", "magnet"]


static func make(icon_name: String) -> Image:
	var p = P.new(32, 32)
	match icon_name:
		"heart": _heart(p)
		"heart_plus": _heart(p); _plus(p, 16, 14, 3, DARK)
		"boot": _boot(p)
		"sword": _sword(p)
		"crosshair": _crosshair(p)
		"shield": _shield(p)
		"feather": _feather(p)
		"cross": _cross(p)
		"star": _star(p, 5, 13.0, 6.0)
		"bullets": _bullets(p)
		"hourglass": _hourglass(p)
		"clock": _clock(p)
		"gear": _gear(p)
		"drop": _drop(p)
		"skull": _skull(p)
		"burst": _star(p, 8, 14.0, 7.0)
		"bolt": _bolt(p)
		"magnet": _magnet(p)
	p.outline(Color("151823"))
	return p.img


static func _heart(p) -> void:
	p.begin()
	p.m_ellipse(11.5, 12, 6.5, 6.0)
	p.m_ellipse(20.5, 12, 6.5, 6.0)
	p.m_poly([Vector2(5.5, 14), Vector2(26.5, 14), Vector2(16, 27)])
	p.end(LIGHT)


static func _plus(p, cx: int, cy: int, t: int, col: Color) -> void:
	p.rect(cx - t, cy - 1, t * 2 + 1, 3, col)
	p.rect(cx - 1, cy - t, 3, t * 2 + 1, col)


static func _cross(p) -> void:
	p.begin()
	p.m_rect(12, 4, 8, 24)
	p.m_rect(4, 12, 24, 8)
	p.end(LIGHT)


static func _boot(p) -> void:
	# Dos chevrones "»" que sugieren velocidad.
	for k in 2:
		p.begin()
		var x: float = 6.0 + k * 10.0
		p.m_poly([Vector2(x, 6), Vector2(x + 6, 6), Vector2(x + 13, 16), Vector2(x + 6, 26), Vector2(x, 26), Vector2(x + 7, 16)])
		p.end(LIGHT if k == 1 else MID)


static func _sword(p) -> void:
	p.begin()
	p.m_poly([Vector2(27, 3), Vector2(29, 5), Vector2(14, 21), Vector2(11, 18)])
	p.end(LIGHT)
	p.begin()
	p.m_poly([Vector2(7, 15), Vector2(17, 25), Vector2(14, 28), Vector2(4, 18)])
	p.end(MID)
	p.begin()
	p.m_poly([Vector2(3, 24), Vector2(8, 29), Vector2(4, 30), Vector2(2, 28)])
	p.end(DARK)


static func _crosshair(p) -> void:
	p.begin()
	p.m_ellipse(16, 16, 11, 11)
	p.end(LIGHT)
	p.ellipse_px(16, 16, 7, 7, Color(0, 0, 0, 0))
	p.begin()
	p.m_ellipse(16, 16, 6.5, 6.5)
	p.end(Color("5a6180"))
	p.begin()
	p.m_rect(15, 2, 3, 8)
	p.m_rect(15, 22, 3, 8)
	p.m_rect(2, 15, 8, 3)
	p.m_rect(22, 15, 8, 3)
	p.end(LIGHT)
	p.rect(15, 15, 3, 3, LIGHT)


static func _shield(p) -> void:
	p.begin()
	p.m_poly([Vector2(5, 5), Vector2(27, 5), Vector2(27, 17), Vector2(16, 29), Vector2(5, 17)])
	p.end(LIGHT)
	p.begin()
	p.m_poly([Vector2(16, 5), Vector2(27, 5), Vector2(27, 17), Vector2(16, 29)])
	p.end(MID)
	p.rect(14, 9, 4, 12, DARK)


static func _feather(p) -> void:
	p.begin()
	p.m_poly([Vector2(26, 4), Vector2(28, 14), Vector2(20, 24), Vector2(10, 26), Vector2(8, 20), Vector2(14, 10)])
	p.end(LIGHT)
	p.line_px(Vector2(7, 27), Vector2(24, 8), DARK)
	for i in 4:
		p.line_px(Vector2(11 + i * 3, 24 - i * 4), Vector2(17 + i * 3, 21 - i * 4), MID)


static func _star(p, points: int, r_out: float, r_in: float) -> void:
	var pts: Array = []
	for i in points * 2:
		var a: float = -PI / 2.0 + float(i) * PI / points
		var r: float = r_out if i % 2 == 0 else r_in
		pts.append(Vector2(16 + cos(a) * r, 16 + sin(a) * r))
	p.begin()
	p.m_poly(pts)
	p.end(LIGHT)


static func _bullets(p) -> void:
	for k in 3:
		var x: int = 4 + k * 9
		p.begin()
		p.m_rect(x, 12, 6, 15)
		p.end(MID)
		p.begin()
		p.m_poly([Vector2(x, 12), Vector2(x + 6, 12), Vector2(x + 3, 4)])
		p.end(LIGHT)
		p.rect(x, 24, 6, 3, DARK)


static func _hourglass(p) -> void:
	p.begin()
	p.m_poly([Vector2(7, 4), Vector2(25, 4), Vector2(25, 6), Vector2(18, 16), Vector2(25, 26), Vector2(25, 28), Vector2(7, 28), Vector2(7, 26), Vector2(14, 16), Vector2(7, 6)])
	p.end(LIGHT)
	p.poly_px([Vector2(11, 7), Vector2(21, 7), Vector2(16, 15)], DARK)
	p.poly_px([Vector2(12, 26), Vector2(20, 26), Vector2(16, 20)], MID)


static func _clock(p) -> void:
	p.begin()
	p.m_ellipse(16, 16, 12.5, 12.5)
	p.end(LIGHT)
	p.begin()
	p.m_ellipse(16, 16, 9.5, 9.5)
	p.end(Color("4a5170"))
	p.line_px(Vector2(16, 16), Vector2(16, 8), LIGHT)
	p.line_px(Vector2(16, 16), Vector2(22, 19), LIGHT)
	p.rect(15, 15, 3, 3, LIGHT)


static func _gear(p) -> void:
	p.begin()
	p.m_ellipse(16, 16, 9.5, 9.5)
	for i in 8:
		var a: float = float(i) * PI / 4.0
		p.m_poly([
			Vector2(16 + cos(a - 0.22) * 8, 16 + sin(a - 0.22) * 8),
			Vector2(16 + cos(a - 0.22) * 14, 16 + sin(a - 0.22) * 14),
			Vector2(16 + cos(a + 0.22) * 14, 16 + sin(a + 0.22) * 14),
			Vector2(16 + cos(a + 0.22) * 8, 16 + sin(a + 0.22) * 8)])
	p.end(LIGHT)
	p.begin()
	p.m_ellipse(16, 16, 4.5, 4.5)
	p.end(Color("4a5170"))


static func _drop(p) -> void:
	p.begin()
	p.m_ellipse(16, 19, 8.5, 8.5)
	p.m_poly([Vector2(16, 3), Vector2(8, 17), Vector2(24, 17)])
	p.end(LIGHT)
	p.ellipse_px(13, 20, 2.0, 3.0, DARK)


static func _skull(p) -> void:
	p.begin()
	p.m_ellipse(16, 14, 11, 10.5)
	p.m_rect(10, 19, 12, 9)
	p.end(LIGHT)
	p.begin()
	p.m_ellipse(11.5, 14, 3.2, 3.6)
	p.m_ellipse(20.5, 14, 3.2, 3.6)
	p.end(Color("3a4060"))
	p.poly_px([Vector2(16, 18), Vector2(14, 22), Vector2(18, 22)], DARK)
	for x in [12, 15, 18]:
		p.rect(x, 24, 2, 4, DARK)


static func _bolt(p) -> void:
	p.begin()
	p.m_poly([Vector2(19, 2), Vector2(8, 17), Vector2(15, 17), Vector2(12, 30), Vector2(25, 13), Vector2(17, 13)])
	p.end(LIGHT)


static func _magnet(p) -> void:
	# Imán en U con los polos marcados.
	p.begin()
	p.m_poly([Vector2(5, 5), Vector2(12, 5), Vector2(12, 17), Vector2(14, 21), Vector2(18, 21), Vector2(20, 17), Vector2(20, 5), Vector2(27, 5), Vector2(27, 18), Vector2(22, 28), Vector2(10, 28), Vector2(5, 18)])
	p.end(LIGHT)
	p.rect(5, 5, 7, 6, DARK)
	p.rect(20, 5, 7, 6, DARK)
	p.rect(5, 11, 7, 2, MID)
	p.rect(20, 11, 7, 2, MID)
