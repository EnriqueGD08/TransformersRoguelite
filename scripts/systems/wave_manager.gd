# wave_manager.gd
# Orquesta la secuencia de oleadas de la run actual.
# SRP: decide cuándo empieza y termina cada oleada, y cuándo spawnear enemigos.
#      No instancia enemigos directamente — delega en EnemySpawner.
#      No calcula daño ni gestiona HP — eso es de otros sistemas.
# DIP: depende de EnemySpawner (por referencia) y WaveData (Resource).
# OCP: añadir nuevos tipos de oleada solo requiere crear nuevos WaveData .tres.

class_name WaveManager
extends Node

# ── Dependencias ──────────────────────────────────────────────────────────────

## Lista ordenada de Resources WaveData (wave_01.tres … wave_20.tres).
## Se asigna desde el Inspector en game.tscn.
@export var waves: Array[WaveData] = []

## Referencia al EnemySpawner de la escena. Se inyecta con setup().
var spawner: EnemySpawner

# ── Estado de la run ──────────────────────────────────────────────────────────

var _current_wave_index: int = -1
var _wave_active: bool = false
var _wave_timer: float = 0.0
var _between_waves: bool = false

# ── Timers de spawn por grupo ─────────────────────────────────────────────────

## Para cada SpawnGroup activo: cuántos enemigos quedan por spawnear
## y cuánto tiempo hasta el siguiente spawn.
var _spawn_group_states: Array[Dictionary] = []

# ── Lifecycle ─────────────────────────────────────────────────────────────────

## Inyección de dependencias: GameController le pasa el spawner.
## (Se hace por código y no por NodePath en la escena para que sea explícito.)
func setup(p_spawner: EnemySpawner) -> void:
	assert(p_spawner != null, "WaveManager: spawner no puede ser null")
	assert(waves.size() > 0, "WaveManager: waves está vacío")
	spawner = p_spawner

	EventBus.all_enemies_dead.connect(_on_all_enemies_dead)
	EventBus.skill_tree_closed.connect(_on_skill_tree_closed)
	EventBus.shop_closed.connect(_on_shop_closed)
	EventBus.character_died.connect(_on_player_died)


func _process(delta: float) -> void:
	if not _wave_active or _between_waves:
		return

	_wave_timer -= delta
	_process_spawn_groups(delta)

	var wave: WaveData = _get_current_wave()
	if wave == null:
		return

	# Tiempo agotado: si no hay que matar a todos, termina la oleada.
	if _wave_timer <= 0.0 and not wave.must_kill_all:
		_complete_wave()

# ── API pública ───────────────────────────────────────────────────────────────

## Inicia la run desde la primera oleada.
## Llamar desde game.tscn una vez el jugador esté listo.
func start_run() -> void:
	_current_wave_index = -1
	_advance_to_next_wave()


## Devuelve el número de oleada actual (1-based).
func get_current_wave_number() -> int:
	return _current_wave_index + 1


## Devuelve el total de oleadas de la run.
func get_total_waves() -> int:
	return waves.size()

# ── Gestión de oleadas ────────────────────────────────────────────────────────

func _advance_to_next_wave() -> void:
	_current_wave_index += 1

	if _current_wave_index >= waves.size():
		_finish_run()
		return

	var wave: WaveData = _get_current_wave()
	_wave_timer = wave.duration
	_wave_active = true
	_between_waves = false

	_setup_spawn_groups(wave)

	EventBus.wave_started.emit(get_current_wave_number(), get_total_waves())
	EventBus.play_music.emit("battle_wave_%d" % get_current_wave_number())


func _complete_wave() -> void:
	if not _wave_active:
		return

	_wave_active = false
	_between_waves = true
	_spawn_group_states.clear()
	spawner.despawn_all()

	var wave: WaveData = _get_current_wave()
	EventBus.wave_completed.emit(get_current_wave_number())
	EventBus.save_requested.emit()

	# Concede recompensas de fin de oleada.
	if wave.bonus_skill_points > 0:
		GameState.add_skill_points(wave.bonus_skill_points)
	if wave.bonus_energon > 0:
		EventBus.energon_collected.emit(wave.bonus_energon, 0)

	# Entre oleadas se abre primero el árbol de habilidades y después la tienda.
	EventBus.skill_tree_opened.emit()


func _finish_run() -> void:
	_wave_active = false
	EventBus.all_waves_completed.emit()
	EventBus.play_music.emit("victory")

# ── Spawn groups ──────────────────────────────────────────────────────────────

func _setup_spawn_groups(wave: WaveData) -> void:
	_spawn_group_states.clear()
	for group in wave.spawn_groups:
		_spawn_group_states.append({
			"group": group,
			"remaining": group.count,
			"timer": group.initial_delay,
			"done": false,
		})


func _process_spawn_groups(delta: float) -> void:
	var wave: WaveData = _get_current_wave()
	if wave == null:
		return

	for state in _spawn_group_states:
		if state.done:
			continue

		state.timer -= delta
		if state.timer > 0.0:
			continue

		_spawn_enemy_from_group(state, wave)
		state.remaining -= 1
		state.timer = state.group.spawn_interval

		if state.remaining <= 0:
			state.done = true
			# Si era el grupo del jefe, lo spawnea ahora.
			if wave.has_boss and wave.boss_scene and _all_groups_done():
				_spawn_boss(wave)


func _spawn_enemy_from_group(state: Dictionary, wave: WaveData) -> void:
	var group: SpawnGroup = state.group
	var position: Vector2

	if group.use_fixed_positions and group.spawn_positions.size() > 0:
		var idx: int = (group.count - state.remaining) % group.spawn_positions.size()
		position = group.spawn_positions[idx]
	else:
		position = spawner.get_random_spawn_position()

	var enemy: BaseEnemy = spawner.spawn(group.enemy_scene, position)

	# Aplica multiplicadores de dificultad de la oleada al enemigo.
	if enemy:
		enemy.apply_difficulty(
			wave.enemy_hp_multiplier,
			wave.enemy_damage_multiplier,
			wave.enemy_speed_multiplier
		)


func _spawn_boss(wave: WaveData) -> void:
	var position: Vector2 = spawner.get_random_spawn_position(400.0, 500.0)
	spawner.spawn(wave.boss_scene, position)


func _all_groups_done() -> bool:
	for state in _spawn_group_states:
		if not state.done:
			return false
	return true

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_all_enemies_dead() -> void:
	# Solo termina la oleada si ya aparecieron todos los grupos; si no, el
	# último enemigo vivo moriría y cortaría la oleada antes de tiempo.
	if _wave_active and _all_groups_done():
		_complete_wave()


## Tras el árbol de habilidades se abre la tienda (salvo después de la última oleada,
## donde ya no hay nada que comprar: la run termina).
func _on_skill_tree_closed() -> void:
	if _current_wave_index + 1 >= waves.size():
		_on_shop_closed()
		return
	EventBus.shop_opened.emit()


func _on_shop_closed() -> void:
	_between_waves = false
	_advance_to_next_wave()


func _on_player_died(_character: Node) -> void:
	_wave_active = false
	_spawn_group_states.clear()
	spawner.despawn_all()
	EventBus.game_over.emit()
	EventBus.play_music.emit("game_over")


func _get_current_wave() -> WaveData:
	if _current_wave_index < 0 or _current_wave_index >= waves.size():
		return null
	return waves[_current_wave_index]
