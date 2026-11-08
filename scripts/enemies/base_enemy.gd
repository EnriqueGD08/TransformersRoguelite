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
	attacked_player.connect(_on_attacked_player_animation)
	_sprite.animation_finished.connect(_on_sprite_animation_finished)
	_on_enemy_ready()


func _on_enemy_ready() -> void:
	pass


## Animación automática: camina si se está moviendo y reposa si no.
func _process(_delta: float) -> void:
	if not _is_alive:
		return
	var moved: bool = global_position.distance_to(_last_position) > 0.25
	_last_position = global_position
	if _anim_locked:
		return
	var target: StringName = &"walk" if moved and _sprite.sprite_frames.has_animation("walk") else &"idle"
	if _sprite.animation != target:
		_sprite.play(target)


func _on_attacked_player_animation(_damage: float) -> void:
	# El rugido de la segunda fase no se corta por un golpe: si no, apenas se vería.
	if _sprite.animation == &"phase2_intro" and _sprite.is_playing():
		return
	if _is_alive and _sprite.sprite_frames.has_animation("attack"):
		_anim_locked = true
		_sprite.play(&"attack")


func _on_sprite_animation_finished() -> void:
	if not _is_alive:
		return
	# Tras una animación puntual (ataque, rugido) se vuelve al ciclo normal.
	_anim_locked = false
	_sprite.play(&"idle")


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
	_sprite.play("death")
	await _sprite.animation_finished
	queue_free()

func _on_status_applied(_effect: String) -> void:
	pass

func _on_status_expired(_effect: String) -> void:
	pass
