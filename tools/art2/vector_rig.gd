# vector_rig.gd
# Herramienta de desarrollo: construye dibujos vectoriales (SVG) por piezas articuladas
# y los convierte en imagen con el propio Godot.
# SRP: solo sabe de formas, degradados, articulaciones y rasterizado; no conoce personajes.

extends RefCounted

const OUTLINE := "#14161f"

var width: int
var height: int

## Margen superior extra del lienzo (para crestas y brazos en alto) sin mover el dibujo.
var top_margin: int = 0

## Margen izquierdo: el dibujo sigue en sus coordenadas, pero el lienzo empieza antes.
var left_margin: int = 0
var _defs: Dictionary = {}
var _body: PackedStringArray = []


func _init(w: int, h: int) -> void:
	width = w
	height = h


func add(fragment: String) -> void:
	_body.append(fragment)


## Degradado vertical de tres tonos a partir de un color: da volumen a las piezas.
func metal(col: Color, light: float = 0.32, dark: float = 0.38) -> String:
	var id := "m%s_%d_%d" % [col.to_html(false), int(light * 100), int(dark * 100)]
	if not _defs.has(id):
		_defs[id] = ('<linearGradient id="%s" x1="0" y1="0" x2="0.25" y2="1">'
			+ '<stop offset="0" stop-color="#%s"/><stop offset="0.45" stop-color="#%s"/>'
			+ '<stop offset="1" stop-color="#%s"/></linearGradient>') % [
			id, col.lightened(light).to_html(false), col.to_html(false), col.darkened(dark).to_html(false)]
	return "url(#%s)" % id


## Cromo: bandas alternas de claro y oscuro, como un metal pulido.
func chrome(col: Color, horizontal: bool = true) -> String:
	var id := "c%s_%d" % [col.to_html(false), int(horizontal)]
	if not _defs.has(id):
		var dir := 'x1="0" y1="0" x2="1" y2="0"' if horizontal else 'x1="0" y1="0" x2="0" y2="1"'
		_defs[id] = ('<linearGradient id="%s" %s><stop offset="0" stop-color="#%s"/>'
			+ '<stop offset="0.28" stop-color="#%s"/><stop offset="0.5" stop-color="#%s"/>'
			+ '<stop offset="0.72" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient>') % [
			id, dir, col.darkened(0.45).to_html(false), Color.WHITE.lerp(col, 0.25).to_html(false),
			col.darkened(0.12).to_html(false), col.lightened(0.35).to_html(false), col.darkened(0.55).to_html(false)]
	return "url(#%s)" % id


## Resplandor radial: del color al transparente.
func glow(col: Color) -> String:
	var id := "g%s" % col.to_html(false)
	if not _defs.has(id):
		_defs[id] = ('<radialGradient id="%s"><stop offset="0" stop-color="#ffffff"/>'
			+ '<stop offset="0.25" stop-color="#%s"/><stop offset="1" stop-color="#%s" stop-opacity="0"/></radialGradient>') % [
			id, col.to_html(false), col.to_html(false)]
	return "url(#%s)" % id


## Pieza con relleno y contorno.
static func shape(d: String, fill: String, stroke_w: float = 2.0, stroke: String = OUTLINE) -> String:
	return '<path d="%s" fill="%s" stroke="%s" stroke-width="%.2f" stroke-linejoin="round" stroke-linecap="round"/>' % [d, fill, stroke, stroke_w]


## Detalle sin contorno (brillos, paneles, sombras).
static func flat(d: String, col: String, opacity: float = 1.0) -> String:
	return '<path d="%s" fill="%s" fill-opacity="%.2f"/>' % [d, col, opacity]


## Línea de detalle (juntas de panel, reflejos).
static func line(d: String, col: String, w: float = 1.2, opacity: float = 1.0) -> String:
	return '<path d="%s" fill="none" stroke="%s" stroke-width="%.2f" stroke-opacity="%.2f" stroke-linecap="round" stroke-linejoin="round"/>' % [d, col, w, opacity]


static func circle(x: float, y: float, r: float, fill: String, stroke_w: float = 0.0, opacity: float = 1.0) -> String:
	var st := ' stroke="%s" stroke-width="%.2f"' % [OUTLINE, stroke_w] if stroke_w > 0.0 else ""
	return '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="%s" fill-opacity="%.2f"%s/>' % [x, y, r, fill, opacity, st]


static func ellipse(x: float, y: float, rx: float, ry: float, fill: String, opacity: float = 1.0) -> String:
	return '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" fill="%s" fill-opacity="%.2f"/>' % [x, y, rx, ry, fill, opacity]


## Articulación: agrupa piezas en una posición y ángulo (los hijos giran con el padre).
static func joint(pos: Vector2, deg: float, children: String) -> String:
	return '<g transform="translate(%.2f %.2f) rotate(%.2f)">%s</g>' % [pos.x, pos.y, deg, children]


## Cinemática inversa de dos huesos. Devuelve [ángulo1, ángulo2] en grados, medidos
## desde "hacia abajo" (+Y), para que los huesos se dibujen a lo largo de +Y.
## bend: -1 dobla la articulación hacia +X (rodilla adelante si mira a +X); +1 hacia -X.
static func ik(from: Vector2, to: Vector2, l1: float, l2: float, bend: float) -> Array:
	var v := to - from
	var d := clampf(v.length(), absf(l1 - l2) + 0.01, l1 + l2 - 0.01)
	var base := atan2(-v.x, v.y)
	var a := acos(clampf((l1 * l1 + d * d - l2 * l2) / (2.0 * l1 * d), -1.0, 1.0))
	var b := acos(clampf((l1 * l1 + l2 * l2 - d * d) / (2.0 * l1 * l2), -1.0, 1.0))
	var a1 := base + a * bend
	var a2 := -(PI - b) * bend
	return [rad_to_deg(a1), rad_to_deg(a2)]


## Escala un grupo alrededor de un punto.
static func scaled(center: Vector2, sx: float, sy: float, children: String) -> String:
	return '<g transform="translate(%.2f %.2f) scale(%.3f %.3f) translate(%.2f %.2f)">%s</g>' % [
		center.x, center.y, sx, sy, -center.x, -center.y, children]


## Gira un grupo alrededor de un punto.
static func rotated(center: Vector2, deg: float, children: String) -> String:
	return '<g transform="rotate(%.2f %.2f %.2f)">%s</g>' % [deg, center.x, center.y, children]


static func faded(opacity: float, children: String) -> String:
	return '<g opacity="%.3f">%s</g>' % [opacity, children]


func svg() -> String:
	var defs := ""
	for k in _defs:
		defs += _defs[k]
	return '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%d %d %d %d"><defs>%s</defs>%s</svg>' % [
		width, height + top_margin, -left_margin, -top_margin, width, height + top_margin, defs, "".join(_body)]


func render() -> Image:
	var img := Image.new()
	var err := img.load_svg_from_string(svg(), 1.0)
	if err != OK:
		push_error("vector_rig: SVG no válido (%s)" % error_string(err))
	return img


# ── Estilo "cel" (colores planos con sombra de corte duro) ────────────────────

## Convierte [x0,y0,x1,y1...] en puntos. mirror refleja en X (piezas simétricas).
static func v(flat_pts: Array, mirror: bool = false) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat_pts.size(), 2):
		out.append(Vector2(-flat_pts[i] if mirror else flat_pts[i], flat_pts[i + 1]))
	return out


static func path(pts: PackedVector2Array) -> String:
	var s := "M%.2f,%.2f" % [pts[0].x, pts[0].y]
	for i in range(1, pts.size()):
		s += " L%.2f,%.2f" % [pts[i].x, pts[i].y]
	return s + " Z"


static func hex(c: Color) -> String:
	return "#" + c.to_html(false)


## Pieza plana con sombra dura en diagonal (luz arriba a la izquierda) y contorno grueso.
static func cel(pts: PackedVector2Array, fill: Color, shade: Color, w: float = 3.0, amount: float = 0.42) -> String:
	var d := path(pts)
	var out := flat(d, hex(fill))
	var box := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		box = box.expand(p)
	var top_x: float = box.position.x + box.size.x * (1.0 - amount + 0.14)
	var bot_x: float = box.position.x + box.size.x * (1.0 - amount - 0.14)
	var quad := PackedVector2Array([Vector2(top_x, box.position.y - 2), Vector2(box.end.x + 2, box.position.y - 2),
		Vector2(box.end.x + 2, box.end.y + 2), Vector2(bot_x, box.end.y + 2)])
	for poly in Geometry2D.intersect_polygons(pts, quad):
		out += flat(path(poly), hex(shade))
	return out + '<path d="%s" fill="none" stroke="%s" stroke-width="%.2f" stroke-linejoin="miter" stroke-miterlimit="3"/>' % [d, OUTLINE, w]


## Línea de acento.
static func accent(pts: PackedVector2Array, col: Color, w: float = 2.2) -> String:
	var s := "M%.2f,%.2f" % [pts[0].x, pts[0].y]
	for i in range(1, pts.size()):
		s += " L%.2f,%.2f" % [pts[i].x, pts[i].y]
	return '<path d="%s" fill="none" stroke="%s" stroke-width="%.2f" stroke-linejoin="miter"/>' % [s, hex(col), w]


func render_scaled(k: float) -> Image:
	var img := Image.new()
	var err := img.load_svg_from_string(svg(), k)
	if err != OK:
		push_error("vector_rig: SVG no válido (%s)" % error_string(err))
	return img
