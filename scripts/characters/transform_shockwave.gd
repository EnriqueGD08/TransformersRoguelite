# transform_shockwave.gd
# Componente de transformación de Shockwave.
# Modo transformado: cañón láser autónomo.
# Efecto: dispara un rayo continuo que perfora todas las filas de enemigos
#         en línea recta hacia el ratón, aplicando daño por segundo y slow.
#         Shockwave no puede moverse durante el rayo (es el cañón).
# SRP: solo gestiona el estado y el rayo de la transformación de Shockwave.
# ISP: implementa ITransformable.

class_name TransformShockwave
extends Node

var character: BaseCharacter = null

# ── Configuración ─────────────────────────────────────────────────────────────

## Longitud del rayo en píxeles.
@export_range(200.0, 1200.0, 50.0) var beam_length: float = 600.0

## Ancho del rayo (radio del área de intersección) en píxeles.
@export_range(10.0, 80.0, 5.0) var beam_width: float = 24.0

## Daño por segundo del rayo sobre cada enemigo alcanzado.
@export_range(10.0, 300.0, 10.0) var beam_dps: float = 80.0

## Factor de ralentización aplicado a enemigos en el rayo (0.5 = 50% velocidad).
@export_range(0.1, 0.9, 0.05) var slow_factor: float = 0.5

## Tick de daño del rayo en segundos (cada cuánto aplica daño).
@export_range(0.05, 0.5, 0.05) var beam_tick: float = 0.1

# ── Timers y estado ───────────────────────────────────────────────────────────

@onready var _duration_timer: Timer = $DurationTimer
@onready var _cooldown_timer: Timer = $CooldownTimer
@onready var _beam_timer: Timer = $BeamTimer

var _transformed: bool = false
var _in_cooldown: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_duration_timer.one_shot = true
	_cooldown_timer.one_shot = true
	_beam_timer.wait_time = beam_tick
	_beam_timer.autostart = false

	_duration_timer.timeout.connect(_on_duration_expired)
	_cooldown_timer.timeout.connect(_on_cooldown_expired)
	_beam_timer.timeout.connect(_on_beam_tick)

# ── ITransformable ────────────────────────────────────────────────────────────

func transform_activate() -> void:
	if _transformed or _in_cooldown or character == null:
		return

	_transformed = true

	_duration_timer.wait_time = character.stats.transform_duration
	_duration_timer.start()
	_beam_timer.start()

	# Shockwave se inmoviliza durante el rayo.
	character.set_physics_process(false)

	character.notify_transform_activated()


func transform_deactivate() -> void:
	if not _transformed:
		return

	_duration_timer.stop()
	_beam_timer.stop()
	_transformed = false
	_in_cooldown = true

	# Restaura el movimiento.
	character.set_physics_process(true)

	_cooldown_timer.wait_time = character.stats.transform_cooldown
	_cooldown_timer.start()

	character.notify_transform_deactivated()


func is_transformed() -> bool:
	return _transformed


func on_cooldown() -> bool:
	return _in_cooldown


func get_cooldown_remaining() -> float:
	return _cooldown_timer.time_left


func get_cooldown_duration() -> float:
	return character.stats.transform_cooldown if character else 0.0

# ── Rayo continuo ─────────────────────────────────────────────────────────────

func _on_beam_tick() -> void:
	if not _transformed or character == null:
		return

	var origin: Vector2 = character.global_position
	var target: Vector2 = character.get_global_mouse_position()
	var direction: Vector2 = (target - origin).normalized()

	# Raycast a lo largo del rayo para detectar todos los enemigos en la línea.
	var space_state := character.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		origin,
		origin + direction * beam_length,
		2  # capa de enemigos
	)
	# El rayo de Godot solo detecta el primer impacto; usamos shape cast
	# para detectar múltiples enemigos (piercing total).
	var shape_query := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(beam_length, beam_width * 2.0)
	shape_query.shape = shape

	var angle: float = direction.angle()
	var center: Vector2 = origin + direction * (beam_length / 2.0)
	shape_query.transform = Transform2D(angle, center)
	shape_query.collision_mask = 2

	var tick_damage: float = beam_dps * beam_tick
	var results := space_state.intersect_shape(shape_query)

	for result in results:
		var body: Node = result.collider
		if body.has_method("take_damage"):
			body.take_damage(tick_damage)
		if body.has_method("apply_speed_modifier"):
			# Aplica slow durante el doble del tick para asegurar solapamiento.
			body.apply_speed_modifier(slow_factor, beam_tick * 2.0)

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_duration_expired() -> void:
	transform_deactivate()


func _on_cooldown_expired() -> void:
	_in_cooldown = false
	character.notify_transform_ready()
