# transform_starscream.gd
# Componente de transformación de Starscream.
# Modo transformado: jet F-22 Raptor.
# Efecto: velocidad aérea máxima + bomba en picado al activarse
#         que daña en área grande. Durante el vuelo ignora colisiones
#         con enemigos (pasa a través de ellos).
# SRP: solo gestiona estado y efectos de la transformación de Starscream.
# ISP: implementa ITransformable.

class_name TransformStarscream
extends Node

var character: BaseCharacter = null

# ── Configuración ─────────────────────────────────────────────────────────────

## Radio de la bomba en picado en píxeles.
@export_range(100.0, 500.0, 10.0) var bomb_radius: float = 220.0

## Multiplicador de daño de la bomba sobre el daño base del personaje.
@export_range(1.0, 10.0, 0.5) var bomb_damage_multiplier: float = 4.0

## Escena del efecto visual de explosión (instanciada en el punto de impacto).
@export var explosion_effect_scene: PackedScene

# ── Timers y estado ───────────────────────────────────────────────────────────

@onready var _duration_timer: Timer = $DurationTimer
@onready var _cooldown_timer: Timer = $CooldownTimer

var _transformed: bool = false
var _in_cooldown: bool = false

## Máscara de colisión original del personaje (se restaura al aterrizar).
var _saved_collision_mask: int = 0

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

	_duration_timer.wait_time = character.stats.transform_duration
	_duration_timer.start()

	_drop_bomb()
	_enable_flight_collision()

	character.notify_transform_activated()


func transform_deactivate() -> void:
	if not _transformed:
		return

	_duration_timer.stop()
	_transformed = false
	_in_cooldown = true

	_disable_flight_collision()

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

# ── Efectos de Starscream ─────────────────────────────────────────────────────

## Lanza la bomba en picado al activar la transformación.
func _drop_bomb() -> void:
	var bomb_position: Vector2 = character.global_position
	var bomb_damage: float = character.get_damage() * bomb_damage_multiplier

	var space_state := character.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = bomb_radius
	query.shape = shape
	query.transform = Transform2D(0.0, bomb_position)
	query.collision_mask = 2  # capa de enemigos

	var results := space_state.intersect_shape(query)
	for result in results:
		var body: Node = result.collider
		if body.has_method("take_damage"):
			body.take_damage(bomb_damage)

	if explosion_effect_scene:
		var effect: Node2D = explosion_effect_scene.instantiate()
		ProjectileContainer.add(character, effect)
		effect.global_position = bomb_position
		if effect.has_method("fit_diameter"):
			effect.fit_diameter(bomb_radius * 1.6)

	EventBus.play_sfx.emit("starscream_bomb")


## En modo jet, Starscream no colisiona con enemigos (los atraviesa).
## Cambiamos la máscara de colisión del CharacterBody2D.
func _enable_flight_collision() -> void:
	# Guardamos la máscara original y quitamos la capa de enemigos (capa 2).
	_saved_collision_mask = character.collision_mask
	character.set_collision_mask_value(2, false)


func _disable_flight_collision() -> void:
	# Restauramos exactamente la máscara que tenía antes de volar.
	character.collision_mask = _saved_collision_mask

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_duration_expired() -> void:
	transform_deactivate()


func _on_cooldown_expired() -> void:
	_in_cooldown = false
	character.notify_transform_ready()
