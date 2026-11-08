# energon_pickup.gd
# Cubo de energon que sueltan los enemigos al morir.
# SRP: solo su comportamiento en el mundo: salir despedido, flotar, ser atraído por el
#      personaje y avisar al recogerlo. No toca el saldo: eso lo hace EnergonManager.
# DIP: el objetivo es cualquier Node2D; si tiene get_pickup_radius() lo usa como radio.
# Es un Node2D (no un Area2D) a propósito: la recogida se decide por distancia, y así se
# puede crear sin problemas durante los callbacks de física en los que mueren los enemigos.

class_name EnergonPickup
extends Node2D

## Emitida al recogerlo. [param amount] Energon que contiene.
signal collected(amount: int)

const GROUP := &"energon_pickups"

# ── Configuración ─────────────────────────────────────────────────────────────

## Efecto visual al recogerlo (OneShotEffect).
@export var collect_effect_scene: PackedScene

## Segundos que dura el impulso inicial antes de poder ser atraído.
@export_range(0.0, 1.0, 0.05) var pop_duration: float = 0.3

## Velocidad del impulso inicial en píxeles/segundo.
@export_range(0.0, 400.0, 10.0) var pop_speed: float = 170.0

## Velocidad inicial y aceleración al ser atraído hacia el personaje.
@export_range(50.0, 600.0, 10.0) var attract_speed: float = 180.0
@export_range(100.0, 3000.0, 50.0) var attract_acceleration: float = 1100.0

## Distancia a la que se considera recogido.
@export_range(4.0, 60.0, 1.0) var collect_distance: float = 24.0

## Radio de atracción si el objetivo no define get_pickup_radius().
@export_range(20.0, 300.0, 5.0) var fallback_radius: float = 90.0

## A partir de qué cantidad el cubo se ve mediano o grande.
@export var medium_amount: int = 10
@export var large_amount: int = 20

## El centro del cuerpo de los personajes queda algo por debajo del origen del nodo.
const TARGET_OFFSET := Vector2(0.0, 10.0)

# ── Estado ────────────────────────────────────────────────────────────────────

var _amount: int = 0
var _target: Node2D = null
var _velocity: Vector2 = Vector2.ZERO
var _speed: float = 0.0
var _age: float = 0.0
var _attracting: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

# ── API pública ───────────────────────────────────────────────────────────────

## Inicializa el cubo. Llamar justo después de añadirlo al árbol.
func setup(amount: int, target: Node2D) -> void:
	_amount = amount
	_target = target
	_speed = attract_speed
	_velocity = Vector2.RIGHT.rotated(randf() * TAU) * pop_speed * randf_range(0.5, 1.0)
	scale = Vector2.ONE * _scale_for(amount)
	# Cada cubo empieza en un fotograma distinto para que no latan todos a la vez.
	_sprite.frame = randi() % _sprite.sprite_frames.get_frame_count(_sprite.animation)


## Hace que vuele hacia el personaje sea cual sea la distancia (fin de oleada).
func attract() -> void:
	_attracting = true


func get_amount() -> int:
	return _amount

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	_age += delta
	_sprite.position.y = -5.0 + sin(_age * 4.0) * 2.0

	if not is_instance_valid(_target):
		return
	# Con el personaje muerto los cubos se quedan donde están.
	if _target.has_method("is_alive") and not _target.is_alive():
		return

	var to_target: Vector2 = _target.global_position + TARGET_OFFSET - global_position
	var distance: float = to_target.length()

	if _attracting or (_age >= pop_duration and distance <= _get_radius()):
		_attracting = true
		_speed += attract_acceleration * delta
		var step: float = _speed * delta
		if distance <= collect_distance or step >= distance:
			_collect()
			return
		global_position += to_target / distance * step
	else:
		global_position += _velocity * delta
		_velocity = _velocity.move_toward(Vector2.ZERO, pop_speed * 3.0 * delta)


## Sombra en el suelo: refuerza la sensación de que flota.
func _draw() -> void:
	draw_set_transform(Vector2(0.0, 11.0), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 9.0, Color(0.0, 0.0, 0.0, 0.3))

# ── Privados ──────────────────────────────────────────────────────────────────

func _get_radius() -> float:
	if _target.has_method("get_pickup_radius"):
		return _target.get_pickup_radius()
	return fallback_radius


func _scale_for(amount: int) -> float:
	if amount >= large_amount:
		return 1.25
	if amount >= medium_amount:
		return 1.0
	return 0.75


func _collect() -> void:
	if collect_effect_scene != null:
		var effect: Node2D = collect_effect_scene.instantiate()
		get_parent().add_child(effect)
		effect.global_position = global_position
	EventBus.play_sfx.emit("energon_pickup")
	collected.emit(_amount)
	queue_free()
