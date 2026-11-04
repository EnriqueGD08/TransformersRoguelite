# painter.gd
# Herramienta de desarrollo: pintor de pixel art procedural.
# SRP: solo dibuja (formas, sombreado por partes, contorno y efectos sobre un Image).
#      No conoce personajes: eso vive en optimus_art.gd, vehicon_art.gd, etc.
#
# Flujo de dibujo por partes:
#   begin()  -> m_rect / m_ellipse / m_poly / m_line  (construyen la máscara de la parte)
#   end(color) -> pinta la parte con luz desde arriba-izquierda (luz, medio, sombra)
# Después se añaden detalles directos (px, rect, line_px...) y al final outline().

extends RefCounted

const OUTLINE_COL := Color("12101c")

var W: int
var H: int
var img: Image

# Máscara de la parte actual (1 = pertenece a la parte).
var _mask := PackedByteArray()
var _bx0 := 0
var _by0 := 0
var _bx1 := -1
var _by1 := -1

## Cantidad de "grano" metálico (0 = liso). Lo fija cada skin.
var grain: float = 0.0
## Semilla para que el grano sea determinista.
var seed_val: int = 0


## Traslación global: permite dibujar con coordenadas "de personaje" (80x80)
## sobre un lienzo más grande, con margen para armas y efectos.
var tx: int = 0
var ty: int = 0


func _init(w: int, h: int, p_tx: int = 0, p_ty: int = 0) -> void:
	W = w
	H = h
	tx = p_tx
	ty = p_ty
	img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_mask.resize(w * h)

# ── Máscara de la parte ───────────────────────────────────────────────────────

func begin() -> void:
	_mask.fill(0)
	_bx0 = W
	_by0 = H
	_bx1 = -1
	_by1 = -1


func _put(x: int, y: int) -> void:
	x += tx
	y += ty
	if x < 0 or y < 0 or x >= W or y >= H:
		return
	_mask[y * W + x] = 1
	_bx0 = mini(_bx0, x)
	_by0 = mini(_by0, y)
	_bx1 = maxi(_bx1, x)
	_by1 = maxi(_by1, y)


func _mk(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= W or y >= H:
		return false
	return _mask[y * W + x] == 1


func m_rect(x: int, y: int, w: int, h: int) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_put(xx, yy)


func m_ellipse(cx: float, cy: float, rx: float, ry: float) -> void:
	for yy in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for xx in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (xx + 0.5 - cx) / rx
			var dy := (yy + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_put(xx, yy)


## Polígono relleno (regla par-impar). [param pts] = Array de Vector2.
func m_poly(pts: Array) -> void:
	var minx := 9999.0
	var maxx := -9999.0
	var miny := 9999.0
	var maxy := -9999.0
	for p in pts:
		minx = minf(minx, p.x)
		maxx = maxf(maxx, p.x)
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var n := pts.size()
	for yy in range(int(floor(miny)), int(ceil(maxy)) + 1):
		var cy := yy + 0.5
		var xs: Array = []
		for i in n:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % n]
			if (a.y <= cy and b.y > cy) or (b.y <= cy and a.y > cy):
				xs.append(a.x + (cy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		for k in range(0, xs.size() - 1, 2):
			for xx in range(int(round(xs[k])), int(round(xs[k + 1]))):
				_put(xx, yy)


## Línea gruesa con pincel cuadrado de [param t] píxeles.
func m_line(a: Vector2, b: Vector2, t: int = 1) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in steps + 1:
		var f := float(i) / float(maxi(steps, 1))
		var x := int(round(lerpf(a.x, b.x, f))) - t / 2
		var y := int(round(lerpf(a.y, b.y, f))) - t / 2
		for yy in t:
			for xx in t:
				_put(x + xx, y + yy)


## Copia la máscara actual dilatada [param r] píxeles (para brillos/halos).
func mask_dilated(r: int) -> Array:
	var out: Array = []
	for y in range(_by0 - r, _by1 + r + 1):
		for x in range(_bx0 - r, _bx1 + r + 1):
			var hit := false
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if dx * dx + dy * dy <= r * r and _mk(x + dx, y + dy):
						hit = true
						break
				if hit:
					break
			if hit and x >= 0 and y >= 0 and x < W and y < H:
				out.append(Vector2i(x, y))
	return out

# ── Pintado de la parte con sombreado ─────────────────────────────────────────

func _hash(x: int, y: int) -> float:
	var h := (x * 73856093) ^ (y * 19349663) ^ (seed_val * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return float(abs(h) % 1000) / 1000.0


## Pinta la máscara actual con [param base]. Luz desde arriba-izquierda:
## borde superior = luz fuerte, izquierdo = luz suave, inferior/derecho = sombra.
## Si la parte se solapa con algo ya pintado, su borde se oscurece (separa piezas).
func end(base: Color, shade: bool = true) -> void:
	var hi := base.lightened(0.38)
	var hi2 := base.lightened(0.18)
	var mid_lo := base.darkened(0.16)
	var lo := base.darkened(0.34)
	var deep := base.darkened(0.58)
	for y in range(_by0, _by1 + 1):
		for x in range(_bx0, _bx1 + 1):
			if not _mk(x, y):
				continue
			var up := not _mk(x, y - 1)
			var left := not _mk(x - 1, y)
			var down := not _mk(x, y + 1)
			var right := not _mk(x + 1, y)
			var c := base
			if shade:
				if up:
					c = hi
				elif left:
					c = hi2
				elif down or right:
					c = lo
				elif not _mk(x, y + 2) or not _mk(x + 2, y):
					c = mid_lo
				elif not _mk(x, y - 2) and ((x + y) & 1) == 0:
					c = hi2
				elif not _mk(x - 2, y) and ((x + y) & 1) == 1:
					c = hi2
			if grain > 0.0:
				var r := _hash(x, y)
				if r < grain * 0.5:
					c = c.darkened(0.14)
				elif r > 1.0 - grain * 0.35:
					c = c.lightened(0.12)
			# Separación entre piezas: borde oscuro donde ya había algo pintado.
			if (up or left or down or right) and img.get_pixel(x, y).a > 0.9:
				c = deep if (down or right) else base.darkened(0.5)
			img.set_pixel(x, y, c)

# ── Dibujo directo sobre el lienzo ────────────────────────────────────────────

func px(x: int, y: int, c: Color) -> void:
	x += tx
	y += ty
	if x < 0 or y < 0 or x >= W or y >= H:
		return
	if c.a >= 0.999:
		img.set_pixel(x, y, c)
	else:
		var d := img.get_pixel(x, y)
		img.set_pixel(x, y, Color(
			lerpf(d.r, c.r, c.a), lerpf(d.g, c.g, c.a), lerpf(d.b, c.b, c.a),
			maxf(d.a, c.a)))


func rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			px(xx, yy, c)


func line_px(a: Vector2, b: Vector2, c: Color) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	for i in steps + 1:
		var f := float(i) / float(maxi(steps, 1))
		px(int(round(lerpf(a.x, b.x, f))), int(round(lerpf(a.y, b.y, f))), c)


func ellipse_px(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for yy in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for xx in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (xx + 0.5 - cx) / rx
			var dy := (yy + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				px(xx, yy, c)


func ring_px(cx: float, cy: float, rx: float, ry: float, c: Color, thick: float = 0.18) -> void:
	for yy in range(int(cy - ry) - 2, int(cy + ry) + 3):
		for xx in range(int(cx - rx) - 2, int(cx + rx) + 3):
			var dx := (xx + 0.5 - cx) / rx
			var dy := (yy + 0.5 - cy) / ry
			var d := dx * dx + dy * dy
			if d <= 1.0 and d >= (1.0 - thick) * (1.0 - thick):
				px(xx, yy, c)


func poly_px(pts: Array, c: Color) -> void:
	var minx := 9999.0
	var maxx := -9999.0
	var miny := 9999.0
	var maxy := -9999.0
	for p in pts:
		minx = minf(minx, p.x)
		maxx = maxf(maxx, p.x)
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	var n := pts.size()
	for yy in range(int(floor(miny)), int(ceil(maxy)) + 1):
		var cy := yy + 0.5
		var xs: Array = []
		for i in n:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % n]
			if (a.y <= cy and b.y > cy) or (b.y <= cy and a.y > cy):
				xs.append(a.x + (cy - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		for k in range(0, xs.size() - 1, 2):
			for xx in range(int(round(xs[k])), int(round(xs[k + 1]))):
				px(xx, yy, c)

# ── Pasadas finales ───────────────────────────────────────────────────────────

## Contorno oscuro de 1 px alrededor de todo lo opaco.
func outline(col: Color = OUTLINE_COL) -> void:
	var src := img.duplicate()
	for y in H:
		for x in W:
			if src.get_pixel(x, y).a > 0.5:
				continue
			var near := false
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + o.x
				var ny: int = y + o.y
				if nx >= 0 and ny >= 0 and nx < W and ny < H and src.get_pixel(nx, ny).a > 0.9:
					near = true
					break
			if near:
				img.set_pixel(x, y, col)


## Mezcla todo lo opaco hacia [param col] (destello blanco, daño...).
func tint(col: Color, amount: float) -> void:
	for y in H:
		for x in W:
			var c := img.get_pixel(x, y)
			if c.a > 0.05:
				img.set_pixel(x, y, Color(
					lerpf(c.r, col.r, amount), lerpf(c.g, col.g, amount),
					lerpf(c.b, col.b, amount), c.a))


func desaturate(amount: float) -> void:
	for y in H:
		for x in W:
			var c := img.get_pixel(x, y)
			if c.a > 0.05:
				var g := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
				img.set_pixel(x, y, Color(
					lerpf(c.r, g, amount), lerpf(c.g, g, amount), lerpf(c.b, g, amount), c.a))


func fade(alpha: float) -> void:
	for y in H:
		for x in W:
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				img.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * alpha))


## Halo suave alrededor de los píxeles [param cells] (solo sobre píxeles vacíos).
func glow(cells: Array, col: Color) -> void:
	for v in cells:
		if img.get_pixel(v.x, v.y).a < 0.05:
			img.set_pixel(v.x, v.y, col)

# ── Transformaciones de imagen completa ───────────────────────────────────────

## Escala/rota [param src] alrededor de ([param pivot]) con vecino más cercano.
## [param dest_shift] desplaza el resultado. Devuelve un Image nuevo.
static func xform(src: Image, sx: float, sy: float, pivot: Vector2, rot_deg: float = 0.0, dest_shift: Vector2 = Vector2.ZERO) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var a := deg_to_rad(rot_deg)
	var ca := cos(a)
	var sa := sin(a)
	for y in h:
		for x in w:
			# Inversa: de destino a origen.
			var dx := x + 0.5 - pivot.x - dest_shift.x
			var dy := y + 0.5 - pivot.y - dest_shift.y
			var rx := (dx * ca + dy * sa) / sx
			var ry := (-dx * sa + dy * ca) / sy
			var ux := int(floor(rx + pivot.x))
			var uy := int(floor(ry + pivot.y))
			if ux >= 0 and uy >= 0 and ux < w and uy < h:
				var c := src.get_pixel(ux, uy)
				if c.a > 0.0:
					out.set_pixel(x, y, c)
	return out


## Desplaza la imagen para que su píxel opaco más bajo quede en [param ground_y]
## y su centro horizontal en [param center_x].
static func ground(src: Image, ground_y: int, center_x: int) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var maxy := -1
	var minx := w
	var maxx := -1
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				maxy = maxi(maxy, y)
				minx = mini(minx, x)
				maxx = maxi(maxx, x)
	if maxy < 0:
		return src
	var sh := Vector2i(center_x - (minx + maxx) / 2, ground_y - maxy)
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a > 0.0:
				var nx := x + sh.x
				var ny := y + sh.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h:
					out.set_pixel(nx, ny, c)
	return out
