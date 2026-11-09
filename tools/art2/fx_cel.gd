# fx_cel.gd
# Herramienta de desarrollo: efectos, energon e iconos en estilo cel (formas planas con
# sombra de corte duro, contorno grueso y energía que brilla).
# SRP: solo dibuja efectos; no conoce personajes ni armas.
# Todo se dibuja en las MISMAS coordenadas que el arte antiguo (mismo tamaño de lienzo) y
# se rasteriza a FX_K veces su resolución: las escenas lo compensan con su escala.
# Los proyectiles miran hacia la derecha (el juego los rota en vuelo).

extends RefCounted

const R := preload("res://tools/art2/vector_rig.gd")

## Resolución del arte respecto a su lienzo de diseño.
const FX_K := 2.0

const OUT := "#151823"

# Tonos neutros de los iconos: la interfaz los tiñe con el color de cada rama.
const LIGHT := Color("eef1f8")
const MID := Color("b9c0d3")
const DARK := Color("7d86a0")

const ICONS := ["heart", "heart_plus", "boot", "sword", "crosshair", "shield", "feather", "cross",
	"star", "bullets", "hourglass", "clock", "gear", "drop", "skull", "burst", "bolt", "magnet"]

const _PULSE := [0.0, 0.6, 1.0, 0.6]


static func _new(w: int, h: int):
	return R.new(w, h)


static func _pts(flat: Array) -> PackedVector2Array:
	return R.v(flat)


## Estrella o bola de pinchos centrada en c, con n puntas que alternan ro y ri.
static func _spiky(c: Vector2, n: int, ro: float, ri: float, rot_deg: float = 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n * 2:
		var a: float = deg_to_rad(rot_deg) + float(i) / float(n * 2) * TAU
		var r: float = ro if i % 2 == 0 else ri
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out


static func _hex(c: Color) -> String:
	return R.hex(c)


## Brillo suave de un color alrededor de un punto.
static func _halo(r, c: Vector2, radius: float, col: Color, alpha: float) -> String:
	return R.circle(c.x, c.y, radius, r.glow(col), 0.0, alpha)


## Línea con contorno oscuro (para iconos): primero el borde grueso y encima el color.
static func _bar(pts: PackedVector2Array, w: float, col: Color) -> String:
	return R.accent(pts, Color(OUT), w + 2.4) + R.accent(pts, col, w)


## Anillo con contorno oscuro.
static func _ring(cx: float, cy: float, rad: float, w: float, col: Color) -> String:
	return ('<circle cx="%.2f" cy="%.2f" r="%.2f" fill="none" stroke="%s" stroke-width="%.2f"/>'
		+ '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="none" stroke="%s" stroke-width="%.2f"/>') % [
		cx, cy, rad, OUT, w + 2.4, cx, cy, rad, _hex(col), w]

# ── Proyectiles ───────────────────────────────────────────────────────────────

## Cañón de fusión de Megatron: bola de fuego con cola de llamas. Lienzo 48x24, cabeza en x=34.
static func fusion_bolt(frame: int) -> Image:
	var r = _new(48, 24)
	var pulse: float = _PULSE[frame % 4]
	var rh: float = 7.0 + pulse * 0.9
	var j: Array = [[1.0, 2.0, 1.5, 0.5], [2.0, 0.5, 1.0, 2.0], [0.5, 1.5, 2.0, 1.0], [1.5, 1.0, 0.5, 2.0]][frame % 4]
	r.add(_halo(r, Vector2(34, 12), 16.0 + pulse * 2.0, Color("ff7a1f"), 0.55))
	var outer := _pts([42.0 + pulse, 12, 37, 12 - rh, 30, 12 - rh + 1, 20, 8 - j[0], 8, 9 - j[1], 0, 12,
		8, 15 + j[2], 20, 16 + j[3], 30, 12 + rh - 1, 37, 12 + rh])
	r.add(R.cel(outer, Color("ff6a1a"), Color("c9420f"), 1.5))
	var mid := _pts([40.0 + pulse, 12, 35, 8, 24, 10, 12, 12, 24, 14, 35, 16])
	r.add(R.flat(R.path(mid), _hex(Color("ffc94a"))))
	r.add(R.circle(35, 12, 3.4 + pulse * 0.6, _hex(Color("fffbe0"))))
	for i in 3:
		var a: float = float(i) / 3.0 * TAU + frame * 0.9
		r.add(R.circle(34 + cos(a) * (10 + pulse * 2), 12 + sin(a) * (8 + pulse), 1.1, _hex(Color("ffe6a0"))))
	return r.render_scaled(FX_K)


## Proyectil cargado de la transformación de Megatron: orbe violeta con pinchos. 72x40, cabeza en x=52.
static func charged_shell(frame: int) -> Image:
	var r = _new(72, 40)
	var pulse: float = _PULSE[frame % 4]
	var head := Vector2(52, 20)
	r.add(_halo(r, head, 26.0 + pulse * 3.0, Color("9a2bff"), 0.5))
	var tail := _pts([40, 11, 24, 13 - pulse, 4, 20, 24, 27 + pulse, 40, 29])
	r.add(R.cel(tail, Color("9a2bff"), Color("6a1bbf"), 1.6))
	r.add(R.flat(R.path(_pts([40, 15, 24, 17, 10, 20, 24, 23, 40, 25])), _hex(Color("ff8fd8"))))
	r.add(R.cel(_spiky(head, 9, 15.0 + pulse, 11.0, frame * 11.0), Color("9a2bff"), Color("6a1bbf"), 1.8))
	r.add(R.circle(head.x, head.y, 8.0, _hex(Color("ff8fd8")), 0.0))
	r.add(R.circle(head.x - 1.5, head.y - 1.5, 4.2 + pulse * 0.6, _hex(Color.WHITE)))
	r.add(R.faded(0.55, R.accent(_pts([head.x + 10, head.y - 14, head.x + 19, head.y - 2, head.x + 10, head.y + 12]), Color("ffd0f0"), 1.6)))
	return r.render_scaled(FX_K)


## Rayo nulificador de Starscream: lanza de hielo. 64x16, punta en x=62.
static func null_ray(frame: int) -> Image:
	var r = _new(64, 16)
	var ice := Color("63d6ff")
	r.add(_halo(r, Vector2(54, 8), 9.0, ice, 0.55))
	r.add(R.cel(_pts([63, 8, 55, 3.2, 14, 5, 0, 8, 14, 11, 55, 12.8]), ice, Color("2d9fd0"), 1.4))
	r.add(R.flat(R.path(_pts([56, 8, 50, 6, 10, 7, 4, 8, 10, 9, 50, 10])), "#eaffff"))
	for i in 3:
		var x: float = fposmod(frame * 9.0 + i * 20.0, 52.0) + 6.0
		r.add(R.accent(_pts([x, 8, x + 6.0, 8]), Color.WHITE, 1.2))
	return r.render_scaled(FX_K)


## Onda de choque de Shockwave: media luna violeta. 64x64, centro (32,32), radio de arte 21.
static func shock_wave(frame: int) -> Image:
	var r = _new(64, 64)
	var c := Vector2(32, 32)
	var pulse: float = _PULSE[frame % 4]
	r.add(_halo(r, c + Vector2(8, 0), 30.0, Color("a860ff"), 0.35))
	var pts := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 15:
		var a: float = lerpf(-72.0, 72.0, float(i) / 14.0)
		pts.append(c + Vector2.from_angle(deg_to_rad(a)) * (21.0 + pulse * 0.6))
		inner.append(c + Vector2.from_angle(deg_to_rad(a)) * (21.0 - 13.0 * cos(deg_to_rad(a * 1.25))))
	inner.reverse()
	pts.append_array(inner)
	r.add(R.cel(pts, Color("a860ff"), Color("6d35c9"), 1.8))
	var ripple := PackedVector2Array()
	for i in 11:
		var a: float = lerpf(-52.0, 52.0, float(i) / 10.0)
		ripple.append(c + Vector2.from_angle(deg_to_rad(a)) * (17.0 - pulse * 1.2))
	r.add(R.accent(ripple, Color("e6d2ff"), 1.5))
	# Segunda onda más tenue, detrás de la principal.
	var echo := PackedVector2Array()
	for i in 9:
		var a: float = lerpf(-50.0, 50.0, float(i) / 8.0)
		echo.append(c + Vector2.from_angle(deg_to_rad(a)) * (10.0 + pulse))
	r.add(R.faded(0.55, R.accent(echo, Color("c79bff"), 2.2)))
	return r.render_scaled(FX_K)


## Pistolas fotónicas de Arcee: dardo rosa. 32x12, punta en x=30, cabeza hacia x=23.
static func photon(frame: int) -> Image:
	var r = _new(32, 12)
	var pink := Color("ff5fc2")
	var f: int = frame % 4
	r.add(_halo(r, Vector2(24, 6), 7.0, pink, 0.5))
	r.add(R.cel(_pts([31, 6, 25, 2.4, 8, 3.4 - f * 0.1, 0, 6, 8, 8.6 + f * 0.1, 25, 9.6]), pink, Color("c53a96"), 1.2))
	r.add(R.flat(R.path(_pts([27, 6, 23, 4.6, 7, 5.2, 4, 6, 7, 6.8, 23, 7.4])), "#fff0fa"))
	return r.render_scaled(FX_K)


## Disparo de los enemigos: dardo rojo dentado. 32x12.
static func enemy_bolt(frame: int) -> Image:
	var r = _new(32, 12)
	var red := Color("ff2d4a")
	var f: int = frame % 4
	r.add(_halo(r, Vector2(23, 6), 7.0, red, 0.5))
	r.add(R.cel(_pts([31, 6, 24, 1.8, 20, 4.6, 9, 2.6 + f * 0.3, 0, 6, 9, 9.4 - f * 0.3, 20, 7.4, 24, 10.2]), red, Color("b01530"), 1.2))
	r.add(R.flat(R.path(_pts([27, 6, 22, 4.8, 12, 5.2, 8, 6, 12, 6.8, 22, 7.2])), _hex(Color("ffc2b8"))))
	return r.render_scaled(FX_K)


## Esfera de energía de los jefes (fase 2): orbe carmesí con pinchos. 56x56.
static func boss_orb(frame: int) -> Image:
	var r = _new(56, 56)
	var c := Vector2(28, 28)
	var pulse: float = _PULSE[frame % 4]
	var rad: float = 17.0 + pulse
	r.add(_halo(r, c, 28.0, Color("ff2d4a"), 0.5))
	r.add(R.cel(_spiky(c, 10, rad + 4.0, rad - 2.0, frame * 9.0), Color("c01a4e"), Color("8a1038"), 2.0))
	r.add(R.circle(c.x, c.y, rad * 0.66, _hex(Color("ff5a7a")), 0.0))
	r.add(R.circle(c.x - 1.5, c.y - 1.5, rad * 0.34, _hex(Color("ffd0d8"))))
	for i in 3:
		var a: float = float(i) / 3.0 * TAU - frame * 0.8
		r.add(R.circle(c.x + cos(a) * (rad + 8), c.y + sin(a) * (rad + 8), 1.8, _hex(Color("ffb0c0"))))
	return r.render_scaled(FX_K)

# ── Efectos de un solo uso ────────────────────────────────────────────────────

## Impacto del rayo nulificador: estallido de hielo. 64x64, 6 fotogramas.
static func ray_hit(frame: int) -> Image:
	var r = _new(64, 64)
	var c := Vector2(32, 32)
	var t: float = float(frame) / 5.0
	var size: float = [9.0, 18.0, 25.0, 28.0, 26.0, 22.0][frame]
	var fade: float = 1.0 - maxf(t - 0.6, 0.0) / 0.4 * 0.85
	var ice := Color("63d6ff")
	r.add(R.faded(fade, _halo(r, c, size * 1.3, ice, 0.55)))
	r.add(R.faded(fade, R.cel(_spiky(c, 8, size, size * 0.42, frame * 6.0), ice, Color("2d9fd0"), 1.6)))
	r.add(R.faded(fade, R.flat(R.path(_spiky(c, 8, size * 0.6, size * 0.28, frame * 6.0 + 22.5)), "#eaffff")))
	if frame >= 2:
		r.add(R.faded(fade * 0.7, '<circle cx="32" cy="32" r="%.2f" fill="none" stroke="#ffffff" stroke-width="1.4"/>' % (size * 0.92)))
	return r.render_scaled(FX_K)


## Explosión: bola de fuego que crece, se enfría y se deshace en humo. 128x128, 8 fotogramas.
static func explosion(frame: int) -> Image:
	var r = _new(128, 128)
	var c := Vector2(64, 64)
	var t: float = float(frame) / 7.0
	var size: float = [18.0, 34.0, 48.0, 54.0, 53.0, 50.0, 47.0, 44.0][frame]
	var fire: float = clampf(1.0 - (t - 0.4) * 1.7, 0.0, 1.0)
	var fade: float = 1.0 - maxf(t - 0.7, 0.0) / 0.3 * 0.7
	# Humo detrás, que gana protagonismo según se apaga el fuego.
	r.add(R.faded(fade * (0.25 + 0.5 * (1.0 - fire)), R.cel(_spiky(c + Vector2(0, -4.0 * t * 5.0), 7, size * 1.05, size * 0.84, 10.0), Color("5a5a62"), Color("3a3a42"), 2.2)))
	if fire > 0.0:
		var s: float = size * lerpf(0.55, 1.0, fire)
		r.add(R.faded(fade, R.cel(_spiky(c, 8, s, s * 0.74, frame * 7.0), Color("e8452c"), Color("9a2412"), 2.4)))
		r.add(R.faded(fade, R.cel(_spiky(c + Vector2(-1.5, -1.5), 7, s * 0.74, s * 0.55, frame * 7.0 + 14.0), Color("ff9a2e"), Color("d4600f"), 1.8)))
		r.add(R.faded(fade, R.flat(R.path(_spiky(c + Vector2(-2.5, -2.5), 6, s * 0.48, s * 0.34, frame * 7.0 + 30.0)), _hex(Color("ffe27a")))))
		if t < 0.7:
			r.add(R.circle(c.x - 3, c.y - 3, s * 0.2, _hex(Color.WHITE)))
	# Chispas y escombros que salen despedidos.
	for i in 8:
		var a: float = float(i) / 8.0 * TAU + 0.4
		var d: float = size * (0.9 + 0.55 * minf(t * 1.6, 1.0)) + float(i % 3) * 4.0
		var p: Vector2 = c + Vector2.from_angle(a) * d
		var sz: float = (3.0 - t * 1.6) * (1.0 + float(i % 2) * 0.4)
		if sz > 0.4:
			r.add(R.faded(fade, R.cel(_spiky(p, 2, sz * 1.6, sz * 0.6, rad_to_deg(a)), Color("ffc94a") if i % 2 == 0 else Color("e8452c"), Color("9a2412"), 1.0)))
	return r.render_scaled(FX_K)


# ── Energon ───────────────────────────────────────────────────────────────────

## Cubo de energon. 32x32, 6 fotogramas: el brillo le recorre las caras.
static func energon_cube(frame: int) -> Image:
	var r = _new(32, 32)
	var pulse: float = sin(float(frame) / 6.0 * TAU) * 0.5 + 0.5
	r.add(_halo(r, Vector2(16, 17), 16.0, Color("2db6ea"), 0.35 + 0.25 * pulse))
	var top := _pts([16, 4.5, 26.5, 10, 16, 16, 5.5, 10])
	var left := _pts([5.5, 10, 16, 16, 16, 28.5, 5.5, 22])
	var right := _pts([26.5, 10, 16, 16, 16, 28.5, 26.5, 22])
	r.add(R.shape(R.path(left), _hex(Color("2db6ea")), 1.6))
	r.add(R.shape(R.path(right), _hex(Color("1675b8")), 1.6))
	r.add(R.shape(R.path(top), _hex(Color("a8f6ff")), 1.6))
	r.add(R.accent(_pts([16, 16, 16, 28.5]), Color("e8fdff"), 1.0))
	# Destello que cruza la cara izquierda.
	var s: float = float(frame) / 5.0
	r.add(R.flat(R.path(_pts([7.5 + s * 6, 13.5 + s * 3, 9.5 + s * 6, 14.5 + s * 3, 9.5 + s * 6, 20 + s * 3, 7.5 + s * 6, 19 + s * 3])), "#ffffff", 0.45 + 0.4 * (1.0 - absf(s - 0.5) * 2.0)))
	# Chispa en una esquina.
	var a: float = 0.4 + 0.6 * pulse
	r.add(R.faded(a, R.flat(R.path(_spiky(Vector2(24, 6), 4, 3.6, 0.9)), "#ffffff")))
	return r.render_scaled(FX_K)


## Chispas al recoger energon: rombos que salen despedidos y un aro. 32x32, 5 fotogramas.
static func energon_spark(frame: int) -> Image:
	var r = _new(32, 32)
	var c := Vector2(16, 16)
	var t: float = float(frame) / 4.0
	var fade: float = 1.0 - t * 0.8
	r.add(R.faded(fade, '<circle cx="16" cy="16" r="%.2f" fill="none" stroke="#a8f6ff" stroke-width="2"/>' % (4.0 + 11.0 * t)))
	for i in 8:
		var a: float = float(i) / 8.0 * TAU + 0.3
		var d: float = 3.0 + 12.0 * sqrt(t) * (0.8 + 0.2 * float(i % 2))
		var s: float = (2.8 - t * 1.6) * (1.0 + 0.3 * float(i % 2))
		r.add(R.faded(fade, R.cel(_spiky(c + Vector2.from_angle(a) * d, 2, s * 1.7, s * 0.6, rad_to_deg(a)), Color("a8f6ff"), Color("2db6ea"), 0.9)))
	return r.render_scaled(FX_K)

# ── Iconos del árbol de habilidades (32x32) ───────────────────────────────────

static func icon(icon_name: String) -> Image:
	var r = _new(32, 32)
	r.add(_icon_svg(icon_name))
	return r.render_scaled(FX_K)


static func _icon_svg(icon_name: String) -> String:
	var s := ""
	match icon_name:
		"heart", "heart_plus":
			s += R.cel(_pts([16, 28.5, 4, 16, 2.5, 9, 7, 4, 13, 4.5, 16, 9, 19, 4.5, 25, 4, 29.5, 9, 28, 16]), LIGHT, MID, 1.8)
			if icon_name == "heart_plus":
				s += R.shape(R.path(_pts([14, 10, 18, 10, 18, 14, 22, 14, 22, 18, 18, 18, 18, 22, 14, 22, 14, 18, 10, 18, 10, 14, 14, 14])), _hex(DARK), 1.4)
		"boot":
			s += R.cel(_pts([9, 3.5, 19, 3.5, 19, 15, 28, 19, 28.5, 27, 5.5, 27, 7, 16]), LIGHT, MID, 1.8)
			s += R.accent(_pts([6, 24, 28, 24]), DARK, 2.2)
			s += R.accent(_pts([9, 9, 19, 9]), MID, 2.0)
		"sword":
			var sword := R.cel(_pts([16, 1.5, 19.5, 6, 19.5, 20, 12.5, 20, 12.5, 6]), LIGHT, MID, 1.6)
			sword += R.accent(_pts([16, 5, 16, 18]), DARK, 1.4)
			sword += R.cel(_pts([7.5, 20, 24.5, 20, 24.5, 23.5, 7.5, 23.5]), MID, DARK, 1.6)
			sword += R.cel(_pts([14, 23.5, 18, 23.5, 18, 28, 14, 28]), DARK, DARK, 1.4)
			sword += R.circle(16, 29.5, 2.2, _hex(MID), 1.4)
			s += R.rotated(Vector2(16, 16), 45.0, sword)
		"crosshair":
			s += _ring(16, 16, 10.0, 2.6, LIGHT)
			for p in [[16, 2.5, 16, 11], [16, 21, 16, 29.5], [2.5, 16, 11, 16], [21, 16, 29.5, 16]]:
				s += _bar(_pts(p), 2.6, LIGHT)
			s += R.circle(16, 16, 2.4, _hex(DARK), 1.2)
		"shield":
			s += R.cel(_pts([16, 2.5, 27.5, 6.5, 26.5, 18, 16, 29.5, 5.5, 18, 4.5, 6.5]), LIGHT, MID, 1.8)
			s += R.accent(_pts([16, 7, 16, 24]), DARK, 1.8)
			s += R.accent(_pts([9, 12, 16, 15, 23, 12]), DARK, 1.8)
		"feather":
			s += R.cel(_pts([28, 3.5, 18, 5, 10, 11, 6.5, 21, 5, 29, 8, 27, 15, 23, 23.5, 16, 28.5, 8]), LIGHT, MID, 1.8)
			s += R.accent(_pts([6, 28, 24, 8]), DARK, 1.8)
			s += R.accent(_pts([12, 21, 17, 22]), MID, 1.4)
		"cross":
			s += R.cel(_pts([12, 3.5, 20, 3.5, 20, 12, 28.5, 12, 28.5, 20, 20, 20, 20, 28.5, 12, 28.5, 12, 20, 3.5, 20, 3.5, 12, 12, 12]), LIGHT, MID, 1.8)
		"star":
			s += R.cel(_spiky(Vector2(16, 17), 5, 14.0, 6.0, -90.0), LIGHT, MID, 1.8)
		"burst":
			s += R.cel(_spiky(Vector2(16, 16), 8, 14.5, 7.0, -90.0), LIGHT, MID, 1.8)
			s += R.circle(16, 16, 3.4, _hex(DARK), 1.2)
		"bullets":
			for k in 3:
				var x: float = 3.5 + k * 9.2
				s += R.cel(_pts([x, 27, x, 13.5, x + 3, 4.5, x + 6, 13.5, x + 6, 27]), LIGHT, MID, 1.6)
				s += R.accent(_pts([x, 23, x + 6, 23]), DARK, 2.2)
		"hourglass":
			s += R.cel(_pts([6.5, 3.5, 25.5, 3.5, 25.5, 7, 18.5, 15.5, 25.5, 25, 25.5, 28.5, 6.5, 28.5, 6.5, 25, 13.5, 15.5, 6.5, 7]), LIGHT, MID, 1.8)
			s += R.flat(R.path(_pts([10.5, 27, 21.5, 27, 16, 20])), _hex(DARK))
			s += R.accent(_pts([16, 14, 16, 19]), DARK, 1.2)
		"clock":
			s += R.circle(16, 16, 13.0, _hex(LIGHT), 1.8)
			s += R.accent(_pts([16, 3.5, 16, 6]), DARK, 1.8) + R.accent(_pts([16, 26, 16, 28.5]), DARK, 1.8)
			s += R.accent(_pts([3.5, 16, 6, 16]), DARK, 1.8) + R.accent(_pts([26, 16, 28.5, 16]), DARK, 1.8)
			s += _bar(_pts([16, 16, 16, 8]), 2.0, DARK) + _bar(_pts([16, 16, 22, 19.5]), 2.0, DARK)
			s += R.circle(16, 16, 1.8, _hex(MID), 1.0)
		"gear":
			# Ocho dientes: cada uno es un trapecio (ancho en la base, estrecho en la punta).
			var gear := PackedVector2Array()
			for i in 8:
				var a0: float = float(i) / 8.0 * TAU
				for q in [[-0.30, 10.0], [-0.15, 14.0], [0.15, 14.0], [0.30, 10.0]]:
					gear.append(Vector2(16, 16) + Vector2.from_angle(a0 + q[0]) * q[1])
			s += R.cel(gear, LIGHT, MID, 1.8)
			s += R.circle(16, 16, 4.6, OUT) + R.circle(16, 16, 2.6, _hex(DARK))
		"drop":
			s += R.cel(_pts([16, 2.5, 24, 14.5, 26.5, 21, 22.5, 27.5, 16, 29.5, 9.5, 27.5, 5.5, 21, 8, 14.5]), LIGHT, MID, 1.8)
			s += R.flat(R.path(_pts([10.5, 19, 12, 16, 13, 21, 12, 24])), "#ffffff", 0.7)
		"skull":
			s += R.cel(_pts([16, 2.5, 25, 6.5, 28, 14.5, 23.5, 20, 23.5, 27.5, 8.5, 27.5, 8.5, 20, 4, 14.5, 7, 6.5]), LIGHT, MID, 1.8)
			s += R.circle(11.2, 14.5, 3.4, OUT) + R.circle(20.8, 14.5, 3.4, OUT)
			s += R.flat(R.path(_pts([16, 17.5, 18, 21, 14, 21])), OUT)
			for x in [12.5, 16.0, 19.5]:
				s += R.accent(_pts([x, 23.5, x, 27]), DARK, 1.5)
		"bolt":
			s += R.cel(_pts([19.5, 1.5, 6.5, 17.5, 14, 17.5, 11, 30.5, 25.5, 12.5, 17.5, 12.5]), LIGHT, MID, 1.8)
		"magnet":
			s += R.cel(_pts([4.5, 3.5, 13, 3.5, 13, 17, 19, 17, 19, 3.5, 27.5, 3.5, 27.5, 19, 16, 30.5, 4.5, 19]), LIGHT, MID, 1.8)
			s += R.cel(_pts([4.5, 3.5, 13, 3.5, 13, 9.5, 4.5, 9.5]), Color("e8453c"), Color("a82a24"), 1.6)
			s += R.cel(_pts([19, 3.5, 27.5, 3.5, 27.5, 9.5, 19, 9.5]), Color("4a7fd6"), Color("2c55a0"), 1.6)
	return s
