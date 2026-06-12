# enemy_spawner.gd
# Gestiona la instanciación y eliminación de enemigos en el mundo.
# SRP: única responsabilidad es hacer spawn y despawn de enemigos.
#      No decide cuántos ni cuándo — eso es wave_manager.gd.
# ISP: implementa ISpawnable a nivel de sistema (no por enemigo individual).
# DIP: recibe PackedScene y posición; no conoce tipos concretos de enemigo.

class_name EnemySpawner
extends Node

# ── Señales ───────────────────────────────────────────────────────────────────

## Emitida cuando se instancia un enemigo.
signal enemy_spawned(enemy: BaseEnemy)

## Emitida cuando un enemigo es eliminado del mundo.
signal enemy_despawned(enemy: BaseEnemy)

# ── Estado ────────────────────────────────────────────────────────────────────

## Lista de todos los enemigos actualmente vivos en la escena.
var _active_enemies: Array[BaseEnemy] = []

## Referencia al jugador activo. Se asigna desde game.tscn.
var _player: Node = null

## Nodo padre donde se instancian los enemigos (normalmente el nivel).
var _spawn_parent: Node = null

# ── Setup ─────────────────────────────────────────────────────────────────────

## Inicializa el spawner con el jugador y el nodo contenedor.
## Llamar desde game.tscn antes de la primera oleada.
func setup(player: Node, spawn_parent: Node) -> void:
	assert(player != null, "EnemySpawner: player no puede ser null")
	assert(spawn_parent != null, "EnemySpawner: spawn_parent no puede ser null")
	_player = player
	_spawn_parent = spawn_parent

# ── ISpawnable (a nivel de sistema) ──────────────────────────────────────────

## Instancia un enemigo desde [param scene] en [param spawn_position].
## Lo conecta al jugador y registra sus señales.
## Devuelve la referencia al enemigo instanciado.
func spawn(scene: PackedScene, spawn_position: Vector2) -> BaseEnemy:
	assert(scene != null, "EnemySpawner: scene no puede ser null")
	assert(_player != null, "EnemySpawner: llamar a setup() antes de spawn()")

	var enemy: BaseEnemy = scene.instantiate()
	_spawn_parent.add_child(enemy)
	enemy.global_position = spawn_position
	enemy.setup(_player)
	enemy.died.connect(_on_enemy_died)

	_active_enemies.append(enemy)
	enemy_spawned.emit(enemy)
	return enemy


## Elimina un enemigo activo del mundo de forma limpia.
## [param enemy] Referencia al enemigo a eliminar.
func despawn(enemy: BaseEnemy) -> void:
	if not is_instance_valid(enemy):
		return
	_active_enemies.erase(enemy)
	enemy_despawned.emit(enemy)
	enemy.queue_free()


## Elimina todos los enemigos activos (al terminar una oleada o game over).
func despawn_all() -> void:
	for enemy in _active_enemies.duplicate():
		despawn(enemy)
	_active_enemies.clear()

# ── Consultas ─────────────────────────────────────────────────────────────────

## Devuelve true si no hay enemigos vivos en la escena.
func all_enemies_dead() -> bool:
	return _active_enemies.is_empty()


## Devuelve el número de enemigos activos.
func get_active_count() -> int:
	return _active_enemies.size()


## Devuelve la lista de enemigos activos (copia para evitar modificaciones externas).
func get_active_enemies() -> Array[BaseEnemy]:
	return _active_enemies.duplicate()

# ── Posiciones de spawn ───────────────────────────────────────────────────────

## Genera una posición de spawn aleatoria fuera del viewport del jugador.
## [param min_distance] Distancia mínima al jugador en píxeles.
## [param max_distance] Distancia máxima al jugador en píxeles.
func get_random_spawn_position(min_distance: float = 300.0, max_distance: float = 500.0) -> Vector2:
	if _player == null:
		return Vector2.ZERO
	var angle: float = randf() * TAU
	var distance: float = randf_range(min_distance, max_distance)
	return _player.global_position + Vector2(cos(angle), sin(angle)) * distance

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_enemy_died(enemy: BaseEnemy) -> void:
	_active_enemies.erase(enemy)
	enemy_despawned.emit(enemy)

	if all_enemies_dead():
		EventBus.all_enemies_dead.emit()
