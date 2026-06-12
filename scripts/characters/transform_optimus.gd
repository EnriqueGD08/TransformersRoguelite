# transform_optimus.gd
# Componente de transformación de Optimus Prime.
# Modo transformado: camión Peterbilt.
# Efecto: superarmadura (defensa máxima) + embestida que empuja y daña enemigos en área.
# SRP: única responsabilidad es gestionar el estado y efectos de la transformación.
# ISP: implementa ITransformable.
# OCP: añadir efectos nuevos no requiere modificar BaseCharacter.

class_name TransformOptimus
extends Node

# ── Referencia al personaje ───────────────────────────────────────────────────

## Asignado por optimus_prime.gd en _on_ready().
## DIP: tipado como BaseCharacter, no como OptimusPrime.
var character: BaseCharacter = null

# ── Configuración de la embestida ─────────────────────────────────────────────

## Radio del área de embestida en píxeles.
@export_range(60.0, 300.0, 10.0) var charge_radius: float = 120.0

## Fuerza de empuje aplicada a los enemigos (píxeles/segundo).
@export_range(100.0, 800.0, 50.0) var knockback_force: float = 400.0

## Daño de la embestida al activarse (independiente del arma).
@export_range(10.0, 200.0, 5.0) var charge_damage: float = 60.0

# ── Timers ────────────────────────────────────────────────────────────────────

@onready var _duration_timer: Timer = $DurationTimer
@onready var _cooldown_timer: Timer = $CooldownTimer

# ── Estado ────────────────────────────────────────────────────────────────────

var _transformed: bool = false
var _in_cooldown: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_duration_timer.one_shot = true
	_cooldown_timer.one_shot = true
	_duration_timer.timeout.connect(_on_duration_expired)
	_cooldown_timer.timeout.connect(_on_cooldown_expired)

# ── ITransformable ────────────────────────────────────────────────────────────

func transform_activate() -> void:
	if _transformed or _in_cooldown or character == null:
		return

	_transformed = true
	_in_cooldown = false

	_duration_timer.wait_time = character.stats.transform_duration
	_duration_timer.start()

	_apply_superarmor()
	_perform_charge()

	character.notify_transform_activated()


func transform_deactivate() -> void:
	if not _transformed:
		return

	_duration_timer.stop()
	_transformed = false
	_in_cooldown = true

	_remove_superarmor()

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

# ── Efectos de Optimus ────────────────────────────────────────────────────────

## Aplica superarmadura: reducción de daño máxima durante la transformación.
## Usa el sistema de modificadores de BaseCharacter para no tocar stats base.
func _apply_superarmor() -> void:
	# Lleva damage_reduction al 90% (máximo permitido por IDamageable).
	var current_reduction: float = character.stats.damage_reduction
	var delta: float = 0.9 - current_reduction
	if delta > 0.0:
		character.add_stat_modifier("damage_reduction", delta)


func _remove_superarmor() -> void:
	var current_reduction: float = character.stats.damage_reduction
	var delta: float = 0.9 - current_reduction
	if delta > 0.0:
		character.remove_stat_modifier("damage_reduction", delta)


## Embestida: daña y empuja todos los enemigos en el radio al transformarse.
func _perform_charge() -> void:
	var space_state := character.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = charge_radius
	query.shape = shape
	query.transform = Transform2D(0.0, character.global_position)
	query.collision_mask = 2  # capa de enemigos

	var results := space_state.intersect_shape(query)
	for result in results:
		var body: Node = result.collider
		if body.has_method("take_damage"):
			body.take_damage(charge_damage)
		if body.has_method("apply_knockback"):
			var direction: Vector2 = (body.global_position - character.global_position).normalized()
			body.apply_knockback(direction * knockback_force)

# ── Callbacks de timers ───────────────────────────────────────────────────────

func _on_duration_expired() -> void:
	transform_deactivate()


func _on_cooldown_expired() -> void:
	_in_cooldown = false
	character.notify_transform_ready()
