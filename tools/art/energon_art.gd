# energon_art.gd
# Herramienta de desarrollo: el cubo de energon (pickup) y su destello de recogida.
# SRP: solo dibuja estos dos efectos.

extends RefCounted

const P := preload("res://tools/art/painter.gd")

const TOP := Color("a8f6ff")
const LEFT := Color("2db6ea")
const RIGHT := Color("1675b8")
const EDGE := Color("e8fdff")


## Cubo isométrico translúcido que late y brilla (6 fotogramas). 32x32.
static func cube(frame: int) -> Image:
	var p = P.new(32, 32)
	var pulse: float = 0.5 + 0.5 * sin(float(frame) / 6.0 * TAU)

	# Halo exterior que respira
	p.ellipse_px(16, 17, 14 + pulse * 1.2, 13 + pulse, Color(0.3, 0.85, 1.0, 0.12 + pulse * 0.08))

	# Caras del cubo
	p.poly_px([Vector2(16, 6), Vector2(26, 11.5), Vector2(16, 17), Vector2(6, 11.5)], TOP)
	p.poly_px([Vector2(6, 11.5), Vector2(16, 17), Vector2(16, 29), Vector2(6, 23.5)], LEFT)
	p.poly_px([Vector2(16, 17), Vector2(26, 11.5), Vector2(26, 23.5), Vector2(16, 29)], RIGHT)

	# Núcleo de energía en el interior
	p.ellipse_px(16, 17, 4.5 + pulse, 4.0 + pulse, Color(1, 1, 1, 0.35 + 0.3 * pulse))
	p.ellipse_px(16, 17, 2.2, 2.0, Color(1, 1, 1, 0.85))

	# Aristas
	for e in [[Vector2(16, 6), Vector2(26, 11.5)], [Vector2(26, 11.5), Vector2(26, 23.5)], [Vector2(26, 23.5), Vector2(16, 29)],
			[Vector2(16, 29), Vector2(6, 23.5)], [Vector2(6, 23.5), Vector2(6, 11.5)], [Vector2(6, 11.5), Vector2(16, 6)],
			[Vector2(6, 11.5), Vector2(16, 17)], [Vector2(26, 11.5), Vector2(16, 17)], [Vector2(16, 17), Vector2(16, 29)]]:
		p.line_px(e[0], e[1], Color(EDGE.r, EDGE.g, EDGE.b, 0.55))
	p.outline(Color("0b2a44"))

	# Destello que recorre la cara superior
	var g: float = float(frame) / 6.0
	var gx: float = lerpf(9, 22, g)
	var gy: float = lerpf(13.5, 9.5, g)
	p.px(int(gx), int(gy), Color.WHITE)
	p.px(int(gx) - 1, int(gy), Color(1, 1, 1, 0.7))
	p.px(int(gx) + 1, int(gy), Color(1, 1, 1, 0.7))
	p.px(int(gx), int(gy) - 1, Color(1, 1, 1, 0.7))
	p.px(int(gx), int(gy) + 1, Color(1, 1, 1, 0.7))
	return p.img


## Destello de recogida: anillo que se abre y chispas (5 fotogramas). 32x32.
static func spark(frame: int) -> Image:
	var p = P.new(32, 32)
	var t: float = float(frame) / 4.0
	var r: float = lerpf(4.0, 14.0, sqrt(t))
	var a: float = 1.0 - t * 0.85
	p.ellipse_px(16, 16, r * 0.8, r * 0.8, Color(0.5, 0.9, 1.0, 0.3 * a))
	p.ring_px(16, 16, r, r, Color(0.8, 0.98, 1.0, 0.95 * a), 0.22)
	p.ellipse_px(16, 16, 3.5 * (1.0 - t * 0.5), 3.5 * (1.0 - t * 0.5), Color(1, 1, 1, a))
	for i in 8:
		var ang: float = float(i) / 8.0 * TAU + 0.3
		var d: float = r * 1.05 + 1.0
		p.px(int(16 + cos(ang) * d), int(16 + sin(ang) * d), Color(1, 1, 1, a))
	return p.img
