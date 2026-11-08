# transform_arcee.gd
# Componente de transformación de Arcee.
# Modo transformado: moto futurista.
# Efecto: velocidad extrema + dash instantáneo en la dirección de movimiento
#         que deja una estela cortante dañando a todos los enemigos atravesados.
# SRP: solo gestiona el estado y el dash de la transformación de Arcee.
# ISP: implementa ITransformable.

class_name TransformArcee
extends Node

var character: BaseCharacter = null

# ── Configuración ─────────────────────────────────────────────────────────────

## Distancia del dash en píxeles.
@export_range(100.0, 600.0, 20.0) var dash_distance: float = 280.0

## Duración del dash en segundos (determina velocidad percibida).
@export_range(0.05, 0.5, 0.05) var dash_duration: float = 0.12

## Ancho de la estela cortante del dash en píxeles.
@export_range(20.0, 100.0, 5.0) var slash_width: float = 40.0

## Multiplicador de daño de la estela sobre el daño base del personaje.
@export_range(0.5, 5.0, 0.25) var slash_damage_multiplier: float = 1.5

# ── Timers y estado ───────────────────────────────────────────────────────────

@onready var _duration_timer: Timer = $DurationTimer
@onready var _cooldown_timer: Timer = $CooldownTimer
@onready var _dash_timer: Timer = $DashTimer

var _transformed: bool = false
var _in_cooldown: bool = false
var _is_dashing: bool = false
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_start: Vector2 = Vector2.ZERO

## Enemigos ya cortados en este dash (cada uno recibe daño una sola vez).
var _dash_hit: Array = []

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_duration_timer.one_shot = true
	_cooldown_timer.one_shot = true
	_dash_timer.one_shot = true

	_duration_timer.timeout.connect(_on_duration_expired)
	_cooldown_timer.timeout.connect(_on_cooldown_expired)
	_dash_timer.timeout.connect(_on_dash_expired)

# ── ITransformable ────────────────────────────────────────────────────────────

func transform_activate() -> void:
	if _transformed or _in_cooldown or character == null:
		return

	_transformed = true

	_duration_timer.wait_time = character.stats.transform_duration
	_duration_timer.start()

	_execute_dash()

	character.notify_transform_activated()


func transform_deactivate() -> void:
	if not _transformed:
		return

	_duration_timer.stop()
	_dash_timer.stop()
	_transformed = false
	_is_dashing = false
	_in_cooldown = true

	_cooldown_timer.wait_time = character.stats.transform_cooldown
	_cooldown_timer.start()

	character.notify_transform_deactivated()


func is_transformed() -> bool:
	return _transformed


func on_cooldown() -> bool:
	return _in_cooldown


func get_cooldown_remaining() -> float:
	return _cooldown_timer.time_left


## Acorta el cooldown en curso (pasiva "kill_cdr").
func reduce_cooldown(seconds: float) -> void:
	if _in_cooldown:
		_cooldown_timer.start(maxf(_cooldown_timer.time_left - seconds, 0.05))


func get_cooldown_duration() -> float:
	return character.stats.transform_cooldown if character else 0.0

# ── Dash y estela ─────────────────────────────────────────────────────────────

func _execute_dash() -> void:
	# Dirección del dash: movimiento actual o derecha por defecto.
	_dash_direction = character.velocity.normalized()
	if _dash_direction == Vector2.ZERO:
		_dash_direction = Vector2.RIGHT if not character.is_facing_left() else Vector2.LEFT

	_dash_start = character.global_position
	_dash_hit.clear()
	_is_dashing = true

	_dash_timer.wait_time = dash_duration
	_dash_timer.start()

	EventBus.play_sfx.emit("arcee_dash")


func _physics_process(delta: float) -> void:
	if not _is_dashing or character == null:
		return

	# Mueve a Arcee a alta velocidad durante el dash.
	var dash_speed: float = dash_distance / dash_duration
	character.velocity = _dash_direction * dash_speed
	character.move_and_slide()

	# Daña a todos los enemigos en el ancho de la estela.
	_apply_slash_damage()


func _apply_slash_damage() -> void:
	var space_state := character.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = slash_width
	query.shape = shape
	query.transform = Transform2D(0.0, character.global_position)
	query.collision_mask = 2

	var slash_damage: float = character.get_damage() * slash_damage_multiplier
	for result in space_state.intersect_shape(query):
		var body: Node = result.collider
		if body.has_method("take_damage") and not body in _dash_hit:
			_dash_hit.append(body)
			body.take_damage(slash_damage)

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_dash_expired() -> void:
	_is_dashing = false


func _on_duration_expired() -> void:
	transform_deactivate()


func _on_cooldown_expired() -> void:
	_in_cooldown = false
	character.notify_transform_ready()
