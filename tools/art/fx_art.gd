# fx_art.gd
# Herramienta de desarrollo: efectos visuales (proyectiles y explosiones).
# SRP: solo dibuja efectos; no conoce personajes ni armas.
# Los proyectiles miran hacia la derecha (el juego los rota en vuelo).

extends RefCounted

const P := preload("res://tools/art/painter.gd")


static func _glowball(p, cx: float, cy: float, r: float, core: Color, mid: Color, outer: Color) -> void:
	p.ellipse_px(cx, cy, r * 1.35, r * 1.2, Color(outer.r, outer.g, outer.b, 0.22))
	p.ellipse_px(cx, cy, r, r * 0.9, Color(outer.r, outer.g, outer.b, 0.9))
	p.ellipse_px(cx, cy, r * 0.74, r * 0.66, mid)
	p.ellipse_px(cx, cy, r * 0.42, r * 0.38, core)


## Proyectil del cañón de fusión (bola de energía con estela). 48x24.
static func bolt(frame: int) -> Image:
	var p = P.new(48, 24)
	var pulse: float = [0.0, 0.6, 1.0, 0.6][frame % 4]
	var core := Color("fffbe0")
	var mid := Color("ffc94a")
	var outer := Color("ff6a1a")
	# Estela
	for i in 14:
		var a: float = 0.55 - i * 0.04
		var rr: float = 5.0 - i * 0.28
		if rr > 0.5 and a > 0.0:
			p.ellipse_px(32 - i * 1.7, 12 + sin((i + frame * 2) * 0.9) * 1.2, rr, rr * 0.8,
				Color(outer.r, outer.g, outer.b, a))
	_glowball(p, 34, 12, 7.0 + pulse, core, mid, outer)
	for i in 5:
		var a2: float = float(i) / 5.0 * TAU + frame * 0.7
		p.px(int(34 + cos(a2) * (9 + pulse * 2)), int(12 + sin(a2) * (8 + pulse * 2)), Color(1, 0.9, 0.6, 0.9))
	return p.img


## Proyectil cargado de la transformación de Megatron. 72x40.
static func shell(frame: int) -> Image:
	var p = P.new(72, 40)
	var pulse: float = [0.0, 0.7, 1.0, 0.7][frame % 4]
	var core := Color("ffffff")
	var mid := Color("ff8fd8")
	var outer := Color("9a2bff")
	for i in 22:
		var a: float = 0.6 - i * 0.026
		var rr: float = 9.0 - i * 0.33
		if rr > 0.5 and a > 0.0:
			p.ellipse_px(48 - i * 2.0, 20 + sin((i + frame * 2) * 0.7) * 2.0, rr, rr * 0.85,
				Color(outer.r, outer.g, outer.b, a))
	_glowball(p, 52, 20, 12.0 + pulse * 1.5, core, mid, outer)
	for i in 8:
		var a2: float = float(i) / 8.0 * TAU + frame * 0.6
		var rr2: float = 15.0 + pulse * 3
		p.line_px(Vector2(52 + cos(a2) * 12, 20 + sin(a2) * 11), Vector2(52 + cos(a2) * rr2, 20 + sin(a2) * rr2 * 0.9),
			Color(1, 0.8, 1, 0.8))
	return p.img


## Mancha irregular (bola de fuego orgánica): polígono con radio ruidoso.
static func _blob(p, cx: float, cy: float, r: float, col: Color, seed_val: int, wobble: float = 0.28) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var pts: Array = []
	var n := 22
	var phases: Array = []
	for k in 4:
		phases.append(rng.randf() * TAU)
	for i in n:
		var a: float = float(i) / n * TAU
		var noise: float = sin(a * 2.0 + phases[0]) * 0.5 + sin(a * 3.0 + phases[1]) * 0.35 + sin(a * 5.0 + phases[2]) * 0.2
		var rr: float = r * (1.0 + noise * wobble)
		pts.append(Vector2(cx + cos(a) * rr, cy + sin(a) * rr * 0.9))
	p.poly_px(pts, col)


## Rayo nulificador de Starscream: haz fino y largo, blanco con halo helado. 64x16.
static func ray(frame: int) -> Image:
	var p = P.new(64, 16)
	var f: float = [0.0, 1.0, 0.5, 1.0][frame % 4]
	var ice := Color("63d6ff")
	# Halo y estela
	for i in 30:
		var a: float = 0.5 - i * 0.017
		if a > 0.0:
			p.ellipse_px(52 - i * 1.6, 8, 3.2 - i * 0.07, 2.6 - i * 0.06, Color(ice.r, ice.g, ice.b, a))
	p.line_px(Vector2(6, 8), Vector2(54, 8), Color(0.75, 0.95, 1.0, 0.8))
	p.line_px(Vector2(10 + f * 3, 7), Vector2(54, 7), Color(0.9, 0.99, 1.0, 0.9))
	p.line_px(Vector2(10 + f * 3, 9), Vector2(54, 9), Color(0.9, 0.99, 1.0, 0.9))
	# Cabeza en punta
	p.poly_px([Vector2(46, 4), Vector2(62, 8), Vector2(46, 12)], Color(ice.r, ice.g, ice.b, 0.95))
	p.poly_px([Vector2(48, 6), Vector2(61, 8), Vector2(48, 10)], Color(0.92, 1, 1, 1))
	p.ellipse_px(52, 8, 5 + f, 4 + f * 0.6, Color(1, 1, 1, 0.5))
	for i in 4:
		var a2: float = float(i) / 4.0 * TAU + frame
		p.px(int(52 + cos(a2) * 7), int(8 + sin(a2) * 5), Color(1, 1, 1, 0.9))
	return p.img


## Onda de choque de Shockwave: arcos concéntricos que se ensanchan (se escala en el juego). 64x64.
static func wave(frame: int) -> Image:
	var p = P.new(64, 64)
	var sh: float = [0.0, 1.0, 0.0, -1.0][frame % 4]
	var violet := Color("a860ff")
	var cols := [Color(violet.r, violet.g, violet.b, 0.9), Color(0.75, 0.55, 1.0, 0.6), Color(0.6, 0.4, 0.95, 0.35)]
	var radii := [21.0, 16.0, 11.0]
	for k in 3:
		var r: float = radii[k] + sh * (1.0 if k == 0 else 0.5)
		for step in range(-70, 71, 1):
			var a := deg_to_rad(float(step))
			var thick: float = 3.2 - k * 0.7
			for t in int(thick * 2.0):
				var rr: float = r - t * 0.5
				p.px(int(32 + cos(a) * rr), int(32 + sin(a) * rr), cols[k])
	# Interior tenue
	for step in range(-60, 61, 6):
		var a2 := deg_to_rad(float(step))
		p.line_px(Vector2(32 + cos(a2) * 6, 32 + sin(a2) * 6), Vector2(32 + cos(a2) * 19, 32 + sin(a2) * 19), Color(0.85, 0.7, 1.0, 0.18))
	# Brillos en los extremos y el frente
	for step in [-70, -35, 0, 35, 70]:
		var a3 := deg_to_rad(float(step))
		p.ellipse_px(32 + cos(a3) * 21, 32 + sin(a3) * 21, 2.2, 2.2, Color(1, 1, 1, 0.85))
	return p.img


## Bala fotónica de las pistolas de Arcee: bolita rosa-blanca con estela corta. 32x12.
static func photon(frame: int) -> Image:
	var p = P.new(32, 12)
	var pulse: float = [0.0, 0.5, 1.0, 0.5][frame % 4]
	var pink := Color("ff5fc2")
	for i in 9:
		p.ellipse_px(20 - i * 1.9, 6, 3.0 - i * 0.28, 2.4 - i * 0.22, Color(pink.r, pink.g, pink.b, 0.55 - i * 0.055))
	p.ellipse_px(23, 6, 4.4 + pulse * 0.6, 3.6 + pulse * 0.5, Color(pink.r, pink.g, pink.b, 0.35))
	p.ellipse_px(23, 6, 3.0, 2.6, Color(1.0, 0.7, 0.9, 0.95))
	p.ellipse_px(24, 6, 1.7, 1.5, Color.WHITE)
	return p.img


## Impacto helado del rayo (6 fotogramas). 64x64.
static func ray_hit(frame: int) -> Image:
	var p = P.new(64, 64)
	var t: float = float(frame) / 5.0
	var r: float = lerpf(5.0, 24.0, sqrt(t))
	var a: float = 1.0 - t * 0.85
	var ice := Color("63d6ff")
	p.ellipse_px(32, 32, r, r * 0.9, Color(ice.r, ice.g, ice.b, 0.35 * a))
	p.ring_px(32, 32, r, r * 0.9, Color(0.85, 0.98, 1.0, 0.9 * a), 0.2)
	p.ellipse_px(32, 32, r * 0.4, r * 0.36, Color(1, 1, 1, a))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 10:
		var ang: float = rng.randf() * TAU
		var d: float = r * rng.randf_range(0.6, 1.4)
		p.line_px(Vector2(32 + cos(ang) * r * 0.7, 32 + sin(ang) * r * 0.65),
			Vector2(32 + cos(ang) * d, 32 + sin(ang) * d * 0.9), Color(0.9, 1, 1, 0.8 * a))
	return p.img


## Explosión (8 fotogramas). 128x128.
static func explosion(frame: int) -> Image:
	var p = P.new(128, 128)
	var t: float = float(frame) / 7.0
	var cx := 64.0
	var cy := 64.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 500
	if frame < 6:
		var r: float = lerpf(10.0, 54.0, sqrt(t * 1.15))
		var alpha: float = 1.0 - maxf(t - 0.55, 0.0) * 1.7
		# Capas de fuego irregulares, de fuera (rojo oscuro) a dentro (blanco).
		_blob(p, cx, cy, r * 1.05, Color(0.45, 0.08, 0.05, 0.9 * alpha), 11 + frame, 0.3)
		_blob(p, cx, cy, r * 0.92, Color(0.85, 0.2, 0.07, alpha), 23 + frame, 0.3)
		_blob(p, cx - 1, cy - 1, r * 0.72, Color(1.0, 0.5, 0.1, alpha), 37 + frame, 0.26)
		_blob(p, cx - 2, cy - 2, r * 0.48, Color(1.0, 0.82, 0.3, alpha), 41 + frame, 0.22)
		_blob(p, cx - 2, cy - 3, r * 0.24 * (1.0 - t * 0.4), Color(1, 1, 0.88, alpha), 53 + frame, 0.18)
		# Lenguas de fuego que salen despedidas.
		for i in 9:
			var a: float = rng.randf() * TAU
			var l: float = r * rng.randf_range(0.95, 1.3)
			_blob(p, cx + cos(a) * l * 0.85, cy + sin(a) * l * 0.75, 3.0 + rng.randf() * 5.0,
				Color(1.0, 0.45 + rng.randf() * 0.3, 0.08, 0.85 * alpha), 70 + i, 0.4)
		if frame >= 1 and frame < 5:
			p.ring_px(cx, cy, r * 1.22, r * 1.1, Color(1, 0.92, 0.75, 0.35 * alpha), 0.06)
	# Chispas
	for i in 24:
		var a2: float = rng.randf() * TAU
		var d: float = (14.0 + rng.randf() * 52.0) * (0.35 + t)
		if frame < 7:
			var c: Color = [Color("fff6a8"), Color("ffb347"), Color("ffffff")][i % 3]
			p.px(int(cx + cos(a2) * d), int(cy + sin(a2) * d * 0.9), c)
			if i % 4 == 0:
				p.px(int(cx + cos(a2) * d) + 1, int(cy + sin(a2) * d * 0.9), c)
	# Humo (solo cuando el fuego ya se apaga)
	if frame >= 5:
		var sa: float = 0.55 * (1.0 - float(frame - 5) / 3.0)
		for i in 7:
			var a3: float = rng.randf() * TAU
			var d3: float = 6.0 + rng.randf() * 24.0
			_blob(p, cx + cos(a3) * d3, cy + sin(a3) * d3 * 0.8 - (frame - 4) * 4.0, 7.0 + rng.randf() * 7.0,
				Color(0.2, 0.2, 0.23, sa), 90 + i, 0.3)
	return p.img
