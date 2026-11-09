# transform_megatron.gd
# Componente de transformación de Megatron.
# Modo transformado: tanque Walther P38 / tanque futurista.
# Efecto: carga un disparo único de altísimo daño y área que se libera
#         al desactivar la transformación o al expirar el tiempo.
# SRP: solo gestiona el estado y la carga del disparo transformado.
# ISP: implementa ITransformable.

class_name TransformMegatron
extends Node

var character: BaseCharacter = null

# ── Configuración ─────────────────────────────────────────────────────────────

## Multiplicador de daño sobre el daño base del personaje para el disparo cargado.
@export_range(2.0, 15.0, 0.5) var charged_shot_multiplier: float = 8.0

## Radio del área de explosión del disparo cargado en píxeles.
@export_range(80.0, 400.0, 10.0) var explosion_radius: float = 180.0

## Alcance máximo del proyectil cargado en píxeles.
@export_range(200.0, 2000.0, 50.0) var charged_projectile_range: float = 900.0

## Velocidad del proyectil cargado en píxeles/segundo.
@export_range(200.0, 1000.0, 50.0) var charged_projectile_speed: float = 600.0

## Posición de la boca del cañón respecto al personaje (mirando a la derecha).
@export var muzzle_offset: Vector2 = Vector2(32.0, 0.0)

## Escena del proyectil cargado (se instancia al disparar).
@export var charged_projectile_scene: PackedScene

# ── Timers y estado ───────────────────────────────────────────────────────────

@onready var _duration_timer: Timer = $DurationTimer
@onready var _cooldown_timer: Timer = $CooldownTimer

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

	_duration_timer.wait_time = character.stats.transform_duration
	_duration_timer.start()

	character.notify_transform_activated()


func transform_deactivate() -> void:
	if not _transformed:
		return

	_duration_timer.stop()
	_transformed = false
	_in_cooldown = true

	_fire_charged_shot()

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

# ── Disparo cargado ───────────────────────────────────────────────────────────

## Instancia el proyectil cargado apuntando hacia el ratón.
## El proyectil lleva datos de daño y radio de explosión.
func _fire_charged_shot() -> void:
	if charged_projectile_scene == null:
		push_error("TransformMegatron: charged_projectile_scene no asignado")
		return

	var projectile: Node = charged_projectile_scene.instantiate()
	ProjectileContainer.add(character, projectile)
	var offset: Vector2 = muzzle_offset
	if character.is_facing_left():
		offset.x *= -1.0
	projectile.global_position = character.global_position + offset
	projectile.reset_physics_interpolation()

	var direction: Vector2 = AimInput.get_aim_direction(character, projectile.global_position)

	var damage: float = character.get_damage() * charged_shot_multiplier

	if projectile.has_method("setup"):
		projectile.setup(direction, charged_projectile_speed, damage, charged_projectile_range, explosion_radius)

	EventBus.play_sfx.emit("megatron_charged_shot")

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_duration_expired() -> void:
	transform_deactivate()


func _on_cooldown_expired() -> void:
	_in_cooldown = false
	character.notify_transform_ready()
