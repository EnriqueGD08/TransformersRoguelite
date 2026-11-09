# touch_action_button.gd
# Botón táctil redondo que pulsa una acción del juego (transformar, cambiar de arma).
# SRP: dibuja el botón y, al tocarlo, lanza la acción como si fuera una tecla. No sabe
#      qué hace la acción: el personaje la recibe igual que desde el teclado.
# Muestra la recarga (set_cooldown) como un sector oscuro con los segundos restantes.

class_name TouchActionButton
extends Control

## Acción de InputMap que pulsa (transform, swap_weapon...).
@export var action: StringName = &"transform"

## Dibujo del centro: "transform" (flecha circular) o "swap" (dos flechas).
@export_enum("transform", "swap") var glyph: String = "transform"

@export var tint: Color = Color("ffc83d")

const OUTLINE := Color("14161f")

var _pressed: bool = false
var _remaining: float = 0.0
var _total: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_pressed = true
		_send_action()
		queue_redraw()
		accept_event()
	elif event is InputEventScreenTouch and not event.pressed:
		_pressed = false
		queue_redraw()
		accept_event()


## Pulsación y suelta seguidas: el personaje reacciona con is_action_pressed.
func _send_action() -> void:
	for pressed in [true, false]:
		var press := InputEventAction.new()
		press.action = action
		press.pressed = pressed
		Input.parse_input_event(press)


## Recarga restante en segundos (0 = lista). La envía el EventBus vía TouchControls.
func set_cooldown(remaining: float, total: float) -> void:
	_remaining = remaining
	_total = maxf(total, 0.001)
	queue_redraw()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5 - 4.0
	var ready: bool = _remaining <= 0.0
	var col: Color = tint if ready else tint.darkened(0.5)
	draw_circle(c, r, OUTLINE)
	draw_circle(c, r - 4.0, Color(0.1, 0.12, 0.18, 0.92) if not _pressed else Color(0.22, 0.25, 0.34, 0.95))
	draw_arc(c, r - 3.0, 0.0, TAU, 40, col, 4.0, true)
	if glyph == "transform":
		_draw_transform_glyph(c, r * 0.5, Color.WHITE if ready else Color(0.6, 0.62, 0.7))
	else:
		_draw_swap_glyph(c, r * 0.5, Color.WHITE if ready else Color(0.6, 0.62, 0.7))
	if not ready:
		# Sector oscuro que se va vaciando y los segundos que faltan.
		var frac: float = clampf(_remaining / _total, 0.0, 1.0)
		var pts := PackedVector2Array([c])
		for i in 25:
			pts.append(c + Vector2.from_angle(-PI / 2.0 + TAU * frac * float(i) / 24.0) * (r - 5.0))
		draw_colored_polygon(pts, Color(0, 0, 0, 0.5))
		var font: Font = ThemeDB.fallback_font
		var text: String = "%.0f" % ceilf(_remaining)
		draw_string_outline(font, c + Vector2(-10, 8), text, HORIZONTAL_ALIGNMENT_LEFT, 20, 22, 5, OUTLINE)
		draw_string(font, c + Vector2(-10, 8), text, HORIZONTAL_ALIGNMENT_LEFT, 20, 22, Color.WHITE)


## Flecha circular (↻).
func _draw_transform_glyph(c: Vector2, r: float, col: Color) -> void:
	var start: float = deg_to_rad(-60.0)
	var end: float = deg_to_rad(230.0)
	draw_arc(c, r, start, end, 24, OUTLINE, 9.0, true)
	draw_arc(c, r, start, end, 24, col, 5.0, true)
	var tip: Vector2 = c + Vector2.from_angle(end) * r
	var dir: Vector2 = Vector2.from_angle(end + PI / 2.0)
	var head := PackedVector2Array([tip + dir * 9.0, tip - dir * 6.0 + Vector2.from_angle(end) * 8.0, tip - dir * 6.0 - Vector2.from_angle(end) * 8.0])
	draw_colored_polygon(head, col)
	draw_polyline(PackedVector2Array([head[0], head[1], head[2], head[0]]), OUTLINE, 2.0, true)


## Dos flechas en sentidos opuestos (⇄).
func _draw_swap_glyph(c: Vector2, r: float, col: Color) -> void:
	for sign in [1.0, -1.0]:
		var y: float = -9.0 * sign
		var a := Vector2(-r * sign, y) + c
		var b := Vector2(r * sign, y) + c
		draw_line(a, b, OUTLINE, 9.0, true)
		draw_line(a, b, col, 5.0, true)
		var head := PackedVector2Array([b + Vector2(8.0 * sign, 0), b + Vector2(-4.0 * sign, -9), b + Vector2(-4.0 * sign, 9)])
		draw_colored_polygon(head, col)
		draw_polyline(PackedVector2Array([head[0], head[1], head[2], head[0]]), OUTLINE, 2.0, true)
