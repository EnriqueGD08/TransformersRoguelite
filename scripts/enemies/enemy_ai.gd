# enemy_ai.gd
# Máquina de estados finita (FSM) para el comportamiento de los enemigos.
# SRP: única responsabilidad es decidir qué hace el enemigo cada frame.
#      No gestiona HP, drops ni señales — eso es responsabilidad de BaseEnemy.
# OCP: añadir un nuevo estado no requiere modificar los existentes.
# DIP: recibe BaseEnemy por referencia; no conoce tipos concretos de enemigo.

class_name EnemyAI
extends Node

# ── Estados ───────────────────────────────────────────────────────────────────

enum State {
	IDLE,      # Sin jugador en rango. El enemigo patrulla o espera.
	CHASE,     # Jugador detectado. Se mueve hacia él.
	ATTACK,    # En rango de ataque. Ejecuta el ataque.
	STUNNED,   # Efecto de stun activo. No hace nada.
	DEAD       # Muerto. Detiene la FSM.
}

# ── Referencias ───────────────────────────────────────────────────────────────

## Asignado por base_enemy.gd en _ready() mediante setup().
var _enemy: BaseEnemy = null

var _current_state: State = State.IDLE
var _attack_cooldown_remaining: float = 0.0

## Margen extra de alcance al caer el golpe: si el jugador se ha apartado más allá de
## attack_range × este valor durante la preparación, el golpe falla (se puede esquivar).
@export_range(1.0, 2.0, 0.05) var strike_tolerance: float = 1.25

# ── Patrulla ──────────────────────────────────────────────────────────────────

## Posición objetivo durante el estado IDLE (patrulla aleatoria).
var _patrol_target: Vector2 = Vector2.ZERO
var _patrol_timer: float = 0.0
const PATROL_INTERVAL: float = 2.5
const PATROL_RADIUS: float = 80.0

# ── Setup ─────────────────────────────────────────────────────────────────────

func setup(enemy: BaseEnemy) -> void:
	_enemy = enemy
	_enemy.died.connect(_on_enemy_died)
	_set_state(State.IDLE)

# ── Proceso principal (llamado por base_enemy._physics_process) ───────────────

func process_ai(delta: float) -> void:
	if _enemy == null or _current_state == State.DEAD:
		return

	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)

	match _current_state:
		State.IDLE:
			_process_idle(delta)
		State.CHASE:
			_process_chase()
		State.ATTACK:
			_process_attack()
		State.STUNNED:
			pass  # base_enemy ya bloquea el proceso si hay stun

# ── Estados ───────────────────────────────────────────────────────────────────

func _process_idle(delta: float) -> void:
	if _player_in_range(_enemy.stats.detection_range):
		_set_state(State.CHASE)
		return

	_patrol_timer -= delta
	if _patrol_timer <= 0.0:
		_patrol_timer = PATROL_INTERVAL
		_patrol_target = _enemy.global_position + Vector2(
			randf_range(-PATROL_RADIUS, PATROL_RADIUS),
			randf_range(-PATROL_RADIUS, PATROL_RADIUS)
		)

	_move_towards(_patrol_target, _enemy.get_speed() * 0.4)


func _process_chase() -> void:
	if not _player_in_range(_enemy.stats.detection_range * 1.2):
		_set_state(State.IDLE)
		return

	if _player_in_range(_enemy.stats.attack_range):
		_set_state(State.ATTACK)
		return

	if _enemy._player:
		_move_towards(_enemy._player.global_position, _enemy.get_speed())
		_face_player()


func _process_attack() -> void:
	if not _player_in_range(_enemy.stats.attack_range):
		_set_state(State.CHASE)
		return

	if _attack_cooldown_remaining > 0.0:
		return

	_execute_attack()
	_attack_cooldown_remaining = _enemy.stats.attack_cooldown

# ── Movimiento ────────────────────────────────────────────────────────────────

func _move_towards(target: Vector2, speed: float) -> void:
	var direction: Vector2 = (_enemy.global_position.direction_to(target))
	_enemy.velocity = direction * speed
	_enemy.move_and_slide()


func _face_player() -> void:
	if _enemy._player == null:
		return
	var sprite: AnimatedSprite2D = _enemy.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.flip_h = _enemy._player.global_position.x < _enemy.global_position.x

# ── Ataque ────────────────────────────────────────────────────────────────────

func _execute_attack() -> void:
	match _enemy.stats.ai_type:
		"melee_chaser", "tank_charger":
			_melee_attack()
		"ranged_shooter", "flying_shooter":
			_ranged_attack()


## Ataque cuerpo a cuerpo: la animación empieza ya, pero el daño cae cuando el arma baja.
func _melee_attack() -> void:
	if _enemy._player == null:
		return
	_enemy.attacked_player.emit(_enemy.get_damage())
	EventBus.play_sfx.emit(_enemy.stats.enemy_id + "_attack")
	_after_windup(_land_melee_hit)


func _land_melee_hit() -> void:
	if not _can_still_strike():
		return
	if _player_in_range(_enemy.stats.attack_range * strike_tolerance):
		_enemy._player.take_damage(_enemy.get_damage())


## Ataque a distancia: el proyectil sale con el fogonazo, no al empezar la animación.
func _ranged_attack() -> void:
	if _enemy.stats.projectile_scene == null or _enemy._player == null:
		return
	_enemy.attacked_player.emit(_enemy.get_damage())
	EventBus.play_sfx.emit(_enemy.stats.enemy_id + "_attack")
	_after_windup(_release_projectile)


func _release_projectile() -> void:
	if not _can_still_strike():
		return
	var projectile: Projectile = _enemy.stats.projectile_scene.instantiate()
	ProjectileContainer.add(_enemy, projectile)
	projectile.global_position = _enemy.global_position
	projectile.reset_physics_interpolation()

	var direction: Vector2 = _enemy.global_position.direction_to(
		_enemy._player.global_position
	)
	projectile.setup(
		direction,
		200.0,
		_enemy.get_damage(),
		_enemy.stats.detection_range
	)
	# Cambia la capa de colisión para que el proyectil golpee al jugador (capa 1)
	# y no a otros enemigos (capa 2).
	projectile.collision_mask = 1


## Ejecuta [param action] cuando acaba la preparación del ataque (attack_windup).
## Se usa la señal del temporizador y no un await: si el enemigo desaparece entretanto,
## la conexión se cancela sola y no queda código a medias.
func _after_windup(action: Callable) -> void:
	var seconds: float = _enemy.stats.attack_windup
	if seconds <= 0.0:
		action.call()
		return
	get_tree().create_timer(seconds, false).timeout.connect(action)


## False si el enemigo ha muerto, está aturdido o ya no hay jugador cuando cae el golpe.
func _can_still_strike() -> bool:
	return is_instance_valid(_enemy) and _enemy.is_alive() and _current_state != State.DEAD \
		and not _enemy._has_status("stun") and is_instance_valid(_enemy._player)

# ── Utilidades ────────────────────────────────────────────────────────────────

func _player_in_range(range_px: float) -> bool:
	if _enemy._player == null:
		return false
	return _enemy.global_position.distance_to(
		_enemy._player.global_position
	) <= range_px


func _set_state(new_state: State) -> void:
	_current_state = new_state

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_enemy_died(_dead_enemy: BaseEnemy) -> void:
	_set_state(State.DEAD)
