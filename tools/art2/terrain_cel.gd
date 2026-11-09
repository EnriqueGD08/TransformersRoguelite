# terrain_cel.gd
# Herramienta de desarrollo: el terreno de la arena en estilo cel (Cybertron: placas de metal).
# SRP: solo dibuja texturas de suelo; no conoce personajes ni oleadas.
#
# Son dos capas que se repiten ("tile") con tamaños distintos para que el patrón no se note:
#   floor():  placas de metal con juntas, remaches y algunos paneles especiales. Referencia
#             de movimiento: se ve en todo momento cuánto y hacia dónde te desplazas.
#   decals(): manchas, escombros y marcas sobre fondo transparente, repartidas con huecos.
# Contraste bajo a propósito: el suelo no debe competir con los personajes.
# Las coordenadas de diseño son píxeles del mundo; se rasteriza a doble resolución (FX_K).

extends RefCounted

const R := preload("res://tools/art2/vector_rig.gd")

## Resolución del arte respecto a su lienzo de diseño (la escena compensa con escala 0.5).
const K := 2.0

## Lado del bloque de suelo y de las placas, en píxeles del mundo.
const FLOOR_SIZE := 640
const PLATE := 128

## Lado del bloque de manchas: distinto del suelo para que no coincidan las repeticiones.
const DECAL_SIZE := 768

## Las manchas son blandas y escasas: a menor resolución pesan la mitad de memoria.
const DECAL_K := 1.5

# Paleta: pizarra azulada, un poco más clara que el fondo plano anterior.
const BASE := Color("4f5766")
const SEAM := Color("262b35")
const LIGHT := Color("626b7c")
const SHADE := Color("3b424f")
const GRATE := Color("2d323d")
const HAZARD := Color("a8892e")
const HAZARD_DARK := Color("2a2c33")
const OUT := "#14161f"


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


static func _rect(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)])


static func _tone(c: Color, amount: float) -> Color:
	return c.lightened(amount) if amount >= 0.0 else c.darkened(-amount)

# ── Suelo ─────────────────────────────────────────────────────────────────────

static func floor_tile() -> Image:
	var r = R.new(FLOOR_SIZE, FLOOR_SIZE)
	var rng := _rng(7)
	var n: int = FLOOR_SIZE / PLATE
	# Fondo: el color de las juntas (lo que se ve entre placa y placa).
	r.add(R.flat(R.path(_rect(0, 0, FLOOR_SIZE, FLOOR_SIZE)), R.hex(SEAM)))
	for gy in n:
		for gx in n:
			r.add(_plate(gx, gy, rng))
	return r.render_scaled(K)


## Una placa: tono propio, bisel, remaches, arañazos y, según la posición, un detalle especial.
static func _plate(gx: int, gy: int, rng: RandomNumberGenerator) -> String:
	var x: float = gx * PLATE + 3.0
	var y: float = gy * PLATE + 3.0
	var s: float = PLATE - 6.0
	var tone: float = rng.randf_range(-0.07, 0.07)
	var col: Color = _tone(BASE, tone)
	var out := R.flat(R.path(_rect(x, y, s, s)), R.hex(col))
	# Sombra dura abajo a la derecha (cel): media placa en diagonal más oscura.
	out += R.flat(R.path(PackedVector2Array([Vector2(x + s, y + s * 0.45), Vector2(x + s, y + s), Vector2(x + s * 0.45, y + s)])), R.hex(_tone(col, -0.12)), 0.55)
	# Bisel: luz arriba e izquierda, sombra abajo y derecha.
	out += R.accent(PackedVector2Array([Vector2(x, y + s), Vector2(x, y), Vector2(x + s, y)]), LIGHT, 2.2)
	out += R.accent(PackedVector2Array([Vector2(x + s, y), Vector2(x + s, y + s), Vector2(x, y + s)]), SHADE, 2.2)
	# Remaches en las esquinas.
	for c in [Vector2(x + 9, y + 9), Vector2(x + s - 9, y + 9), Vector2(x + 9, y + s - 9), Vector2(x + s - 9, y + s - 9)]:
		out += R.circle(c.x, c.y, 3.2, R.hex(_tone(col, -0.2)), 1.0)
		out += R.circle(c.x - 0.8, c.y - 0.8, 1.1, R.hex(LIGHT))
	# Arañazos.
	for i in rng.randi_range(0, 2):
		var a := Vector2(x + rng.randf_range(20, s - 40), y + rng.randf_range(24, s - 24))
		var b: Vector2 = a + Vector2(rng.randf_range(10, 28), rng.randf_range(-8, 8))
		out += R.accent(PackedVector2Array([a, b]), _tone(col, -0.22), 1.3)
		out += R.accent(PackedVector2Array([a + Vector2(1, 1.6), b + Vector2(1, 1.6)]), LIGHT, 0.9)
	# Detalles especiales en placas concretas (se repiten cada FLOOR_SIZE, pocos y sin orden).
	match Vector2i(gx, gy):
		Vector2i(1, 1), Vector2i(4, 3):
			out += _vent(x, y, s)
		Vector2i(3, 0), Vector2i(0, 4):
			out += _hatch(x + s * 0.5, y + s * 0.5)
		Vector2i(2, 4), Vector2i(4, 1):
			out += _hazard_band(x, y + s - 22.0, s)
		Vector2i(0, 2), Vector2i(3, 3):
			out += _circuit(x, y, s, col)
	return out


## Rejilla de ventilación: hueco oscuro con listones.
static func _vent(x: float, y: float, s: float) -> String:
	var out := R.cel(_rect(x + 22, y + 22, s - 44, s - 44), GRATE, GRATE.darkened(0.3), 2.4)
	for i in 6:
		var yy: float = y + 32.0 + i * (s - 64.0) / 5.0
		out += R.accent(PackedVector2Array([Vector2(x + 30, yy), Vector2(x + s - 30, yy)]), SHADE.lightened(0.08), 3.0)
		out += R.accent(PackedVector2Array([Vector2(x + 30, yy + 2.6), Vector2(x + s - 30, yy + 2.6)]), Color("171a21"), 1.4)
	return out


## Escotilla redonda con asa.
static func _hatch(cx: float, cy: float) -> String:
	var out := R.circle(cx, cy, 40.0, R.hex(SHADE), 2.6)
	out += R.circle(cx, cy, 31.0, R.hex(_tone(BASE, 0.05)), 2.0)
	out += R.circle(cx - 1.2, cy - 1.2, 12.0, R.hex(SHADE), 1.8)
	out += R.accent(PackedVector2Array([Vector2(cx - 9, cy), Vector2(cx + 9, cy)]), LIGHT, 3.0)
	for i in 4:
		var a: float = float(i) / 4.0 * TAU + 0.78
		out += R.circle(cx + cos(a) * 35.0, cy + sin(a) * 35.0, 2.2, R.hex(SEAM))
	return out


## Franja de peligro (amarillo y negro) en el borde inferior de una placa.
static func _hazard_band(x: float, y: float, w: float) -> String:
	var out := R.flat(R.path(_rect(x, y, w, 16)), R.hex(HAZARD_DARK))
	var step := 18.0
	var i := -1
	while float(i) * step < w:
		var x0: float = x + float(i) * step
		var poly := PackedVector2Array([Vector2(x0 + 6, y), Vector2(x0 + 6 + step * 0.5, y),
			Vector2(x0 + step * 0.5, y + 16), Vector2(x0 - 0.0, y + 16)])
		for p in Geometry2D.intersect_polygons(poly, _rect(x, y, w, 16)):
			out += R.flat(R.path(p), R.hex(HAZARD), 0.9)
		i += 1
	return out + '<rect x="%.1f" y="%.1f" width="%.1f" height="16" fill="none" stroke="%s" stroke-width="1.6"/>' % [x, y, w, OUT]


## Líneas de circuito apagadas (en tonos de la propia placa, para no confundirlas con el energon).
static func _circuit(x: float, y: float, s: float, col: Color) -> String:
	var line: Color = _tone(col, -0.16)
	var out := R.accent(PackedVector2Array([Vector2(x + 14, y + 40), Vector2(x + 60, y + 40), Vector2(x + 60, y + 78), Vector2(x + s - 16, y + 78)]), line, 2.4)
	out += R.accent(PackedVector2Array([Vector2(x + 30, y + s - 16), Vector2(x + 30, y + 58)]), line, 2.4)
	out += R.accent(PackedVector2Array([Vector2(x + s - 40, y + 14), Vector2(x + s - 40, y + 50), Vector2(x + 84, y + 50)]), line, 2.4)
	for p in [Vector2(x + 60, y + 40), Vector2(x + 60, y + 78), Vector2(x + 30, y + 58), Vector2(x + 84, y + 50)]:
		out += R.cel(_rect(p.x - 4, p.y - 4, 8, 8), _tone(col, 0.04), _tone(col, -0.12), 1.4)
	return out

# ── Manchas y escombros ───────────────────────────────────────────────────────

static func decals() -> Image:
	var r = R.new(DECAL_SIZE, DECAL_SIZE)
	var rng := _rng(21)
	# Se reparten en una cuadrícula de celdas con huecos: sin amontonarse ni cruzar el borde.
	var cell := 192
	var n: int = DECAL_SIZE / cell
	var kinds := ["scorch", "oil", "scrap", "skid", "scrap", "crack", "scorch", "scrap"]
	var idx := 0
	for gy in n:
		for gx in n:
			if rng.randf() < 0.35:
				continue
			var c := Vector2(gx * cell + cell * 0.5 + rng.randf_range(-40, 40), gy * cell + cell * 0.5 + rng.randf_range(-40, 40))
			r.add(_decal(kinds[idx % kinds.size()], c, rng))
			idx += 1
	return r.render_scaled(DECAL_K)


static func _decal(kind: String, c: Vector2, rng: RandomNumberGenerator) -> String:
	match kind:
		"scorch":
			# Quemadura: mancha irregular oscura con un centro más negro.
			var out := R.flat(R.path(_blob(c, rng.randf_range(34, 50), 9, rng)), "#0f1116", 0.30)
			return out + R.flat(R.path(_blob(c + Vector2(2, 1), rng.randf_range(16, 26), 7, rng)), "#0a0b0f", 0.28)
		"oil":
			# Charco de aceite: óvalo azulado con un reflejo.
			var w: float = rng.randf_range(34, 52)
			var out := R.ellipse(c.x, c.y, w, w * 0.55, "#1a2230", 0.42)
			out += R.accent(PackedVector2Array([c + Vector2(-w * 0.55, -w * 0.12), c + Vector2(-w * 0.1, -w * 0.3), c + Vector2(w * 0.25, -w * 0.28)]), Color(1, 1, 1, 0.09), 2.0)
			return out
		"scrap":
			# Chatarra: un par de piezas de metal sueltas, con contorno.
			var out := ""
			for i in 2:
				var p: Vector2 = c + Vector2(rng.randf_range(-22, 22), rng.randf_range(-14, 14))
				var pts := PackedVector2Array()
				for k in 5:
					var a: float = float(k) / 5.0 * TAU + rng.randf_range(-0.3, 0.3)
					pts.append(p + Vector2.from_angle(a) * rng.randf_range(6, 13))
				out += R.cel(pts, Color("737b8b"), Color("505867"), 1.5)
			return out
		"skid":
			# Marcas de derrape: dos curvas paralelas.
			var a := c + Vector2(-46, 10)
			var b := c + Vector2(46, -12)
			var m := c + Vector2(rng.randf_range(-10, 10), rng.randf_range(10, 22))
			var out := ""
			for off in [0.0, 7.0]:
				var pts := PackedVector2Array()
				for i in 13:
					var t: float = float(i) / 12.0
					var q: Vector2 = a.lerp(m, t).lerp(m.lerp(b, t), t)
					pts.append(q + Vector2(0, off))
				out += R.accent(pts, Color(0.05, 0.06, 0.08, 0.2), 3.2)
			return out
		_:
			# Grieta: línea quebrada con ramas cortas.
			var pts := PackedVector2Array([c + Vector2(-40, -6)])
			var cur: Vector2 = pts[0]
			for i in 5:
				cur += Vector2(rng.randf_range(12, 20), rng.randf_range(-12, 12))
				pts.append(cur)
			var out := R.accent(pts, Color(0.04, 0.05, 0.07, 0.5), 2.4)
			out += R.accent(PackedVector2Array([pts[2], pts[2] + Vector2(8, 18), pts[2] + Vector2(10, 30)]), Color(0.04, 0.05, 0.07, 0.4), 1.6)
			return out


## Polígono irregular alrededor de c (radio medio r, n puntas).
static func _blob(c: Vector2, rad: float, n: int, rng: RandomNumberGenerator) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a: float = float(i) / float(n) * TAU
		pts.append(c + Vector2.from_angle(a) * rad * rng.randf_range(0.65, 1.15))
	return pts
