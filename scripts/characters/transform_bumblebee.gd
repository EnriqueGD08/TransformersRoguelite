# transform_bumblebee.gd
# Componente de transformación de Bumblebee.
# Modo transformado: Camaro muscle car.
# Efecto: velocidad extrema + invulnerabilidad breve al activar +
#         estela de daño que hiere enemigos al paso.
# SRP: solo gestiona estado y efectos de la transformación de Bumblebee.
# ISP: implementa ITransformable.

class_name TransformBumblebee
extends Node

var character: BaseCharacter = null

# ── Configuración ─────────────────────────────────────────────────────────────

## Duración de la invulnerabilidad al activar (segundos).
@export_range(0.2, 3.0, 0.1) var invulnerability_duration: float = 0.8

## Daño de la estela por segundo a enemigos adyacentes.
@export_range(5.0, 100.0, 5.0) var trail_damage_per_second: float = 20.0

## Radio de la estela de daño en píxeles.
@export_range(20.0, 120.0, 5.0) var trail_radius: float = 48.0

# ── Timers y estado ───────────────────────────────────────────────────────────

@onready var _duration_timer: Timer = $DurationTimer
@onready var _cooldown_timer: Timer = $CooldownTimer
@onready var _invuln_timer: Timer = $InvulnTimer
@onready var _trail_timer: Timer = $TrailTimer

var _transformed: bool = false
var _in_cooldown: bool = false
var _invulnerable: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_duration_timer.one_shot = true
	_cooldown_timer.one_shot = true
	_invuln_timer.one_shot = true
	_trail_timer.wait_time = 0.25
	_trail_timer.autostart = false

	_duration_timer.timeout.connect(_on_duration_expired)
	_cooldown_timer.timeout.connect(_on_cooldown_expired)
	_invuln_timer.timeout.connect(_on_invuln_expired)
	_trail_timer.timeout.connect(_on_trail_tick)

# ── ITransformable ────────────────────────────────────────────────────────────

func transform_activate() -> void:
	if _transformed or _in_cooldown or character == null:
		return

	_transformed = true
	_invulnerable = true

	_duration_timer.wait_time = character.stats.transform_duration
	_duration_timer.start()

	_invuln_timer.wait_time = invulnerability_duration
	_invuln_timer.start()

	_trail_timer.start()

	character.notify_transform_activated()


func transform_deactivate() -> void:
	if not _transformed:
		return

	_duration_timer.stop()
	_invuln_timer.stop()
	_trail_timer.stop()

	_transformed = false
	_invulnerable = false
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


func get_cooldown_duration() -> float:
	return character.stats.transform_cooldown if character else 0.0

# ── Invulnerabilidad ──────────────────────────────────────────────────────────

## Bumblebee es invulnerable los primeros segundos de la transformación.
## BaseCharacter llama a take_damage(); sobreescribimos el comportamiento
## interceptando la señal desde fuera no es posible, así que el arma
## consulta este componente antes de aplicar daño.
## La lógica de invulnerabilidad real se implementa en bumblebee.gd
## sobreescribiendo take_damage() y consultando is_invulnerable().
func is_invulnerable() -> bool:
	return _invulnerable

# ── Estela de daño ────────────────────────────────────────────────────────────

func _on_trail_tick() -> void:
	if not _transformed or character == null:
		return

	var space_state := character.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = trail_radius
	query.shape = shape
	query.transform = Transform2D(0.0, character.global_position)
	query.collision_mask = 2  # capa de enemigos

	var results := space_state.intersect_shape(query)
	var tick_damage: float = trail_damage_per_second * _trail_timer.wait_time

	for result in results:
		var body: Node = result.collider
		if body.has_method("take_damage"):
			body.take_damage(tick_damage)

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_duration_expired() -> void:
	transform_deactivate()


func _on_cooldown_expired() -> void:
	_in_cooldown = false
	character.notify_transform_ready()


func _on_invuln_expired() -> void:
	_invulnerable = false
