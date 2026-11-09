# base_enemy.gd
# Clase base de todos los enemigos del juego.
# SRP: gestiona HP, muerte, drops y señales del enemigo.
#      El movimiento y ataque se delegan a enemy_ai.gd (composición).
# OCP: los tipos concretos extienden esta clase sobrescribiendo solo los hooks.
# LSP: cualquier subclase puede usarse donde se espere BaseEnemy.
# DIP: recibe EnemyStats como Resource; no hardcodea valores.

class_name BaseEnemy
extends CharacterBody2D

# ── Dependencias ──────────────────────────────────────────────────────────────

## Resource con los datos base del enemigo.
@export var stats: EnemyStats

# ── Señales ───────────────────────────────────────────────────────────────────

## Emitida cuando el enemigo recibe daño.
signal damaged(amount: float, current_hp: float)

## Emitida cuando el HP cambia.
signal hp_changed(current_hp: float, max_hp: float)

## Emitida cuando el enemigo muere.
## [param enemy] Referencia a este nodo, para que el spawner lo gestione.
signal died(enemy: BaseEnemy)

## Emitida cuando el enemigo alcanza al jugador y lo ataca.
signal attacked_player(damage: float)

# ── Estado interno ────────────────────────────────────────────────────────────

var _current_hp: float = 0.0
var _is_alive: bool = true

## Referencia al jugador, asignada por enemy_spawner al instanciar.
var _player: Node = null

## Efectos de estado activos. Clave: nombre. Valor: tiempo restante.
var _status_effects: Dictionary = {}

## Modificador de velocidad acumulado (por slow, etc.).
var _speed_modifier: float = 1.0

## Color base del sprite (el destello de daño vuelve a él; la furia/fase 2 lo cambian).
var _base_modulate: Color = Color.WHITE

## True mientras suena una animación puntual (ataque, rugido): no se alterna idle/walk.
var _anim_locked: bool = false

## Posición del fotograma anterior, para saber si el enemigo se está moviendo.
var _last_position: Vector2 = Vector2.ZERO

## Velocidad real (px/s) medida una vez por tick de física, y el tick de esa medida.
## El movimiento ocurre en física (60 por segundo) pero _process corre al ritmo de la pantalla
## (120 o 144 Hz en algunos monitores): comparar posiciones en cada imagen daría "no se mueve"
## en la mitad de ellas y la animación parpadearía entre caminar y reposo.
var _measured_speed: float = 0.0
var _last_physics_tick: int = 0

## Velocidad (px/s) por encima de la cual se considera que el enemigo camina.
const WALK_THRESHOLD: float = 15.0

## Punto del ciclo (0 a 1) en el que arranca cada animación de reposo o caminar. Distinto en
## cada enemigo, para que un grupo no camine al unísono como un desfile.
var _anim_phase: float = 0.0

## Diferencia mínima en X (px) para girar al enemigo hacia el jugador: evita que parpadee
## de un lado a otro cuando está justo encima.
const FACING_MARGIN: float = 4.0

@onready var _ai: Node = $EnemyAI
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _status_timer: Timer = $StatusTimer

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	assert(stats != null, "BaseEnemy: stats no asignado en " + name)
	_current_hp = stats.max_hp

	_status_timer.wait_time = 0.5
	_status_timer.autostart = true
	_status_timer.timeout.connect(_on_status_tick)

	if _ai:
		_ai.setup(self)

	_last_position = global_position
	_last_physics_tick = Engine.get_physics_frames()
	_anim_phase = randf()
	attacked_player.connect(_on_attacked_player_animation)
	_sprite.animation_finished.connect(_on_sprite_animation_finished)
	_on_enemy_ready()


func _on_enemy_ready() -> void:
	pass


## Animación automática: camina si se está moviendo y reposa si no.
## Al caminar, el ritmo de la animación sigue a la velocidad real (ver walk_cycle_speed).
func _process(_delta: float) -> void:
	if not _is_alive:
		return
	_measure_speed()
	var moved: bool = _measured_speed > WALK_THRESHOLD
	_face_player()
	if _anim_locked:
		return
	var target: StringName = &"walk" if moved and _sprite.sprite_frames.has_animation("walk") else &"idle"
	if _sprite.animation != target:
		_play_looped(target)
	_sprite.speed_scale = _walk_speed_scale(_measured_speed) if target == &"walk" else 1.0


## Actualiza la velocidad medida, solo cuando ha pasado algún tick de física.
func _measure_speed() -> void:
	var tick: int = Engine.get_physics_frames()
	if tick == _last_physics_tick:
		return
	var elapsed: float = (tick - _last_physics_tick) * get_physics_process_delta_time()
	_measured_speed = global_position.distance_to(_last_position) / elapsed
	_last_position = global_position
	_last_physics_tick = tick


## Mira siempre hacia el jugador, también cuando ya está a su lado y no lo persigue.
func _face_player() -> void:
	if not is_instance_valid(_player):
		return
	var dx: float = _player.global_position.x - global_position.x
	if absf(dx) > FACING_MARGIN:
		_sprite.flip_h = dx < 0.0


## Reproduce una animación en bucle empezando en el punto de ciclo propio de este enemigo.
func _play_looped(anim: StringName) -> void:
	_sprite.play(anim)
	var count: int = _sprite.sprite_frames.get_frame_count(anim)
	_sprite.set_frame_and_progress(int(_anim_phase * count) % count, 0.0)


## Factor de velocidad de la animación de caminar para una velocidad real [param speed] (px/s).
## Se suaviza y se limita para que un empujón o un frenazo no la descontrolen.
func _walk_speed_scale(speed: float) -> float:
	if stats.walk_cycle_speed <= 0.0:
		return 1.0
	var wanted: float = clampf(speed / stats.walk_cycle_speed, 0.3, 2.0)
	return lerpf(_sprite.speed_scale, wanted, 0.25)


func _on_attacked_player_animation(_damage: float) -> void:
	# El rugido de la segunda fase no se corta por un golpe: si no, apenas se vería.
	if _sprite.animation == &"phase2_intro" and _sprite.is_playing():
		return
	if _is_alive and _sprite.sprite_frames.has_animation("attack"):
		_anim_locked = true
		_sprite.speed_scale = 1.0
		_sprite.play(&"attack")


func _on_sprite_animation_finished() -> void:
	if not _is_alive:
		return
	# Tras una animación puntual (ataque, rugido) se vuelve al ciclo normal.
	_anim_locked = false
	_play_looped(&"idle")


## Destello rojo breve al recibir daño; luego vuelve al color base del enemigo.
func _flash_hit(duration: float = 0.1) -> void:
	_sprite.modulate = Color.RED
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self) and _is_alive:
		_sprite.modulate = _base_modulate


func _physics_process(delta: float) -> void:
	if not _is_alive:
		return
	if _has_status("stun"):
		return
	if _ai:
		_ai.process_ai(delta)

# ── Dificultad ────────────────────────────────────────────────────────────────

## Aplica los multiplicadores de dificultad de la oleada.
## Duplica los stats (para no tocar el .tres compartido) y recalcula el HP actual.
## WaveManager lo llama justo tras el spawn.
func apply_difficulty(hp_mult: float, damage_mult: float, speed_mult: float) -> void:
	stats = stats.duplicate()
	stats.max_hp *= hp_mult
	stats.attack_damage *= damage_mult
	stats.move_speed *= speed_mult
	_current_hp = stats.max_hp

# ── Setup ─────────────────────────────────────────────────────────────────────

## Llamado por enemy_spawner tras instanciar el enemigo.
## [param player] Referencia al nodo del jugador actual.
func setup(player: Node) -> void:
	_player = player

# ── IDamageable ───────────────────────────────────────────────────────────────

func take_damage(amount: float) -> void:
	if not _is_alive:
		return

	_current_hp = maxf(_current_hp - amount, 0.0)
	damaged.emit(amount, _current_hp)
	hp_changed.emit(_current_hp, stats.max_hp)

	_on_damaged(amount)

	if _current_hp <= 0.0:
		_die()


func is_alive() -> bool:
	return _is_alive


func get_current_hp() -> float:
	return _current_hp

# ── IMovable ──────────────────────────────────────────────────────────────────

func get_speed() -> float:
	# El estado "slow" (ej: rayo nulificador) reduce la velocidad a la mitad.
	var slow_factor: float = 0.5 if _has_status("slow") else 1.0
	return stats.move_speed * _speed_modifier * slow_factor


func get_direction() -> Vector2:
	if _player == null:
		return Vector2.ZERO
	return ((_player.global_position - global_position).normalized())


func apply_speed_modifier(multiplier: float, duration: float) -> void:
	_speed_modifier = minf(_speed_modifier, multiplier)
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
		_speed_modifier = 1.0

# ── IAttackable ───────────────────────────────────────────────────────────────

func get_damage() -> float:
	return stats.attack_damage


func get_attack_range() -> float:
	return stats.attack_range

# ── Knockback ─────────────────────────────────────────────────────────────────

## Aplica una fuerza de empuje al enemigo.
## [param force] Vector2 con dirección y magnitud del empuje.
func apply_knockback(force: Vector2) -> void:
	if not _is_alive:
		return
	velocity = force * (1.0 - stats.knockback_resistance)
	move_and_slide()

# ── Efectos de estado ─────────────────────────────────────────────────────────

## Aplica un efecto de estado durante [param duration] segundos.
## Efectos soportados: "stun", "slow", "burn", "bleed".
func apply_status(effect: String, duration: float) -> void:
	_status_effects[effect] = duration
	_on_status_applied(effect)


func _has_status(effect: String) -> bool:
	return _status_effects.has(effect) and _status_effects[effect] > 0.0


## Tick de efectos de estado: reduce timers y aplica daño de burn/bleed.
func _on_status_tick() -> void:
	if not _is_alive:
		return

	var tick: float = _status_timer.wait_time
	var to_remove: Array = []

	for effect in _status_effects.keys():
		_status_effects[effect] -= tick

		if effect == "burn":
			take_damage(stats.max_hp * 0.02)
		elif effect == "bleed":
			take_damage(stats.max_hp * 0.01)

		if _status_effects[effect] <= 0.0:
			to_remove.append(effect)

	for effect in to_remove:
		_status_effects.erase(effect)
		_on_status_expired(effect)

# ── Muerte ────────────────────────────────────────────────────────────────────

func _die() -> void:
	_is_alive = false
	set_physics_process(false)
	_drop_rewards()
	died.emit(self)
	EventBus.enemy_died.emit(self)
	_on_died()


func _drop_rewards() -> void:
	EventBus.energon_dropped.emit(global_position, stats.energon_reward)
	EventBus.xp_earned.emit(stats.xp_reward)

# ── Hooks para subclases ──────────────────────────────────────────────────────

func _on_damaged(_amount: float) -> void:
	_flash_hit()

func _on_died() -> void:
	_sprite.speed_scale = 1.0
	_sprite.play("death")
	await _sprite.animation_finished
	queue_free()

func _on_status_applied(_effect: String) -> void:
	pass

func _on_status_expired(_effect: String) -> void:
	pass
