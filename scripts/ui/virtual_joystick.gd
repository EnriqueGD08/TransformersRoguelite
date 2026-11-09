# virtual_joystick.gd
# Joystick virtual táctil "flotante": aparece donde pones el dedo dentro de su zona y se
# desplaza con él si te alejas más que su radio, así nunca hay que recentrarlo.
# SRP: convierte el arrastre de un dedo en un vector de -1 a 1. No sabe para qué se usa
#      (mover, apuntar...): avisa por la señal y quien lo use decide.

class_name VirtualJoystick
extends Control

## Vector actual (longitud 0..1, ya sin zona muerta). Cero al soltar.
signal vector_changed(vector: Vector2)

## Radio del joystick en píxeles de pantalla virtual.
@export_range(40.0, 200.0, 5.0) var radius: float = 90.0

## Fracción del radio por debajo de la cual se ignora el movimiento del dedo.
@export_range(0.0, 0.9, 0.05) var dead_zone: float = 0.2

## Color del joystick (cada uno tiene el suyo para distinguirlos).
@export var tint: Color = Color("4fb3ff")

## Dónde se dibuja, en reposo, la pista de dónde poner el dedo (fracción del tamaño de la zona).
@export var home_ratio: Vector2 = Vector2(0.5, 0.8)

const OUTLINE := Color("14161f")

var _finger: int = -1
var _origin: Vector2 = Vector2.ZERO
var _offset: Vector2 = Vector2.ZERO
var _vector: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _finger == -1:
			_finger = event.index
			_origin = event.position
			_move_to(event.position)
			accept_event()
		elif not event.pressed and event.index == _finger:
			_release()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _finger:
		_move_to(event.position)
		accept_event()


func _move_to(position_in_zone: Vector2) -> void:
	var offset: Vector2 = position_in_zone - _origin
	# Si el dedo se sale del radio, la base lo sigue.
	if offset.length() > radius:
		_origin += offset.normalized() * (offset.length() - radius)
		offset = position_in_zone - _origin
	_offset = offset
	var raw: Vector2 = offset / radius
	var strength: float = clampf((raw.length() - dead_zone) / (1.0 - dead_zone), 0.0, 1.0)
	_set_vector(raw.normalized() * strength if strength > 0.0 else Vector2.ZERO)
	queue_redraw()


func _release() -> void:
	_finger = -1
	_offset = Vector2.ZERO
	_set_vector(Vector2.ZERO)
	queue_redraw()


func _set_vector(value: Vector2) -> void:
	if value.is_equal_approx(_vector):
		return
	_vector = value
	vector_changed.emit(_vector)


## Al pausar (tienda, árbol) u ocultarse se suelta el joystick, para que no quede
## ninguna dirección "pegada".
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED, NOTIFICATION_VISIBILITY_CHANGED, NOTIFICATION_EXIT_TREE:
			if _finger != -1:
				_release()


func _draw() -> void:
	if _finger == -1:
		# Pista en reposo: un anillo tenue donde suele ponerse el dedo.
		var home: Vector2 = size * home_ratio
		draw_arc(home, radius, 0.0, TAU, 48, Color(tint, 0.35), 4.0, true)
		draw_circle(home, radius * 0.38, Color(tint, 0.18))
		return
	draw_circle(_origin, radius, Color(0.05, 0.06, 0.1, 0.35))
	draw_arc(_origin, radius, 0.0, TAU, 48, OUTLINE, 7.0, true)
	draw_arc(_origin, radius, 0.0, TAU, 48, Color(tint, 0.85), 4.0, true)
	var knob: Vector2 = _origin + _offset
	draw_circle(knob, radius * 0.42, OUTLINE)
	draw_circle(knob, radius * 0.36, Color(tint, 0.9))
	draw_circle(knob + Vector2(-5, -6), radius * 0.12, Color(1, 1, 1, 0.45))
