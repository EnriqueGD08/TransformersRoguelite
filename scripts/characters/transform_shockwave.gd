# transform_shockwave.gd
# Componente de transformación de Shockwave.
# Modo transformado: cañón láser autónomo.
# Efecto: dispara un rayo continuo que perfora todas las filas de enemigos
#         en línea recta hacia el ratón, aplicando daño por segundo y slow.
#         Shockwave no puede moverse durante el rayo (es el cañón), pero sigue apuntando.
# SRP: solo gestiona el estado y el daño del rayo (el dibujo vive en LaserBeam).
# ISP: implementa ITransformable.

class_name TransformShockwave
extends Node

var character: BaseCharacter = null

# ── Configuración del rayo ────────────────────────────────────────────────────

## Longitud del rayo en píxeles.
@export_range(200.0, 1200.0, 50.0) var beam_length: float = 600.0

## Semiancho del rayo (el rayo mide el doble) en píxeles.
@export_range(10.0, 80.0, 5.0) var beam_width: float = 20.0

## Daño por segundo del rayo sobre cada enemigo alcanzado.
@export_range(10.0, 300.0, 10.0) var beam_dps: float = 80.0

## Tick de daño del rayo en segundos (cada cuánto aplica daño).
@export_range(0.05, 0.5, 0.05) var beam_tick: float = 0.1

## Posición de la boca del cañón respecto al personaje (sprite mirando a la derecha).
@export var muzzle_offset: Vector2 = Vector2(50.0, 15.0)

## Escena del efecto visual del rayo (LaserBeam).
@export var beam_scene: PackedScene

# ── Timers y estado ───────────────────────────────────────────────────────────

@onready var _duration_timer: Timer = $DurationTimer
@onready var _cooldown_timer: Timer = $CooldownTimer
@onready var _beam_timer: Timer = $BeamTimer

var _transformed: bool = false
var _in_cooldown: bool = false
var _beam_visual: Node2D = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_duration_timer.one_shot = true
	_cooldown_timer.one_shot = true
	_beam_timer.wait_time = beam_tick
	_beam_timer.autostart = false
	_duration_timer.timeout.connect(_on_duration_expired)
	_cooldown_timer.timeout.connect(_on_cooldown_expired)
	_beam_timer.timeout.connect(_on_beam_tick)


func _physics_process(_delta: float) -> void:
	# El haz visual sigue la boca del cañón y el ratón cada fotograma.
	if _transformed and _beam_visual != null and character != null:
		var line: Dictionary = _beam_line()
		_beam_visual.global_position = line.origin
		_beam_visual.rotation = line.direction.angle()

# ── ITransformable ────────────────────────────────────────────────────────────

func transform_activate() -> void:
	if _transformed or _in_cooldown or character == null:
		return

	_transformed = true
	_duration_timer.wait_time = character.stats.transform_duration
	_duration_timer.start()
	_beam_timer.start()

	# Shockwave se inmoviliza durante el rayo (sigue vivo y apuntando).
	character.set_movement_locked(true)
	if not character.died.is_connected(_on_character_died):
		character.died.connect(_on_character_died)
	_start_beam_visual()

	character.notify_transform_activated()


func transform_deactivate() -> void:
	if not _transformed:
		return

	_duration_timer.stop()
	_beam_timer.stop()
	_transformed = false
	_in_cooldown = true
	_stop_beam_visual()

	character.set_movement_locked(false)

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

# ── Rayo continuo ─────────────────────────────────────────────────────────────

## Origen (boca del cañón) y dirección (hacia el ratón) del rayo.
func _beam_line() -> Dictionary:
	var to_mouse: Vector2 = character.get_global_mouse_position() - character.global_position
	var direction: Vector2 = to_mouse.normalized() if to_mouse.length() > 1.0 else Vector2.RIGHT
	var offset: Vector2 = muzzle_offset
	if character.is_facing_left():
		offset.x *= -1.0
	# La boca gira con el sprite cuando el cañón apunta al ratón.
	var origin: Vector2 = character.global_position + offset.rotated(character.get_visual_rotation())
	return {"origin": origin, "direction": direction}


func _on_beam_tick() -> void:
	if not _transformed or character == null:
		return

	var line: Dictionary = _beam_line()
	var origin: Vector2 = line.origin
	var direction: Vector2 = line.direction

	# Un rectángulo a lo largo del rayo detecta todos los enemigos en línea (perfora todo).
	var space_state := character.get_world_2d().direct_space_state
	var shape_query := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(beam_length, beam_width * 2.0)
	shape_query.shape = shape
	shape_query.transform = Transform2D(direction.angle(), origin + direction * (beam_length / 2.0))
	shape_query.collision_mask = 2  # capa de enemigos

	var tick_damage: float = beam_dps * beam_tick
	for result in space_state.intersect_shape(shape_query):
		var body: Node = result.collider
		if body.has_method("take_damage"):
			body.take_damage(tick_damage)
		if body.has_method("apply_status"):
			# El estado "slow" se renueva en cada tick; un poco más largo que el tick
			# para que no parpadee entre uno y otro.
			body.apply_status("slow", beam_tick * 3.0)

# ── Efecto visual ─────────────────────────────────────────────────────────────

func _start_beam_visual() -> void:
	if beam_scene == null:
		return
	_beam_visual = beam_scene.instantiate()
	ProjectileContainer.add(character, _beam_visual)
	if _beam_visual.has_method("configure"):
		_beam_visual.configure(beam_length, beam_width)
	var line: Dictionary = _beam_line()
	_beam_visual.global_position = line.origin
	_beam_visual.rotation = line.direction.angle()


func _stop_beam_visual() -> void:
	if is_instance_valid(_beam_visual):
		_beam_visual.queue_free()
	_beam_visual = null

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_duration_expired() -> void:
	transform_deactivate()


func _on_cooldown_expired() -> void:
	_in_cooldown = false
	character.notify_transform_ready()


## Si muere mientras dispara, el rayo se apaga (no debe quedar flotando).
func _on_character_died() -> void:
	_beam_timer.stop()
	_duration_timer.stop()
	_stop_beam_visual()
	_transformed = false
