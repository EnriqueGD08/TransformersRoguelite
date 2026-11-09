# aim_input.gd
# Autoload: de dónde sale la puntería (ratón o segundo joystick táctil).
# SRP: solo responde "¿hacia dónde apunta el jugador?". No dispara ni mueve nada.
# DIP: armas y personajes preguntan aquí en lugar de leer el ratón directamente, así
#      funcionan igual con ratón que con pantalla táctil.
# El modo táctil se activa solo al tocar la pantalla y se desactiva al mover un ratón de
# verdad (el ratón que emula el táctil no cuenta), así un portátil con pantalla táctil
# sigue apuntando con el ratón.

extends Node

## Distancia a la que se coloca el punto de mira cuando se apunta con el joystick.
const TOUCH_AIM_DISTANCE := 320.0

## True mientras el jugador usa la pantalla táctil.
var touch_mode: bool = false

## Última dirección apuntada con el joystick (la mantiene al soltarlo).
var _direction: Vector2 = Vector2.RIGHT


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		touch_mode = true
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		touch_mode = false


## Cambia la dirección de apuntado (la llama el joystick de la derecha).
func set_direction(direction: Vector2) -> void:
	if direction.length() > 0.01:
		_direction = direction.normalized()


## Punto del mundo al que apunta el jugador, visto desde [param from_node].
func get_aim_point(from_node: CanvasItem) -> Vector2:
	if touch_mode:
		return from_node.global_position + _direction * TOUCH_AIM_DISTANCE
	return from_node.get_global_mouse_position()


## Dirección (unitaria) desde [param origin] hacia donde apunta el jugador.
func get_aim_direction(from_node: CanvasItem, origin: Vector2) -> Vector2:
	if touch_mode:
		return _direction
	return (from_node.get_global_mouse_position() - origin).normalized()
