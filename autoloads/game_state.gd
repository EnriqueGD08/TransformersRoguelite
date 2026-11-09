# game_state.gd
# Estado global de la partida. Autoload registrado como "GameState".
# SRP: única responsabilidad es mantener los datos de la sesión actual
#      (personaje seleccionado, skin, oleada actual, si hay partida en curso)
#      y ser la ÚNICA fuente de verdad de la economía de la run
#      (energon y puntos de habilidad). No contiene lógica de juego ni UI.
# DIP: los sistemas leen GameState para saber el contexto actual
#      sin acoplarse entre sí.

extends Node

# ── Estado de selección ───────────────────────────────────────────────────────

## ID del personaje seleccionado en el menú.
## Valores válidos: "optimus_prime", "bumblebee", "megatron",
##                  "starscream", "arcee", "shockwave".
var selected_character_id: String = ""

## ID de la skin seleccionada para el personaje actual.
## Valores válidos: "g1", "prime", "bay".
var selected_skin_id: String = "g1"

## Escena del personaje seleccionado (cargada al confirmar selección).
var selected_character_scene: PackedScene = null

## Resource de stats del personaje seleccionado.
var selected_character_stats: CharacterStats = null

## Resource del árbol de habilidades del personaje seleccionado.
var selected_skill_tree: Array[SkillNodeData] = []

## Partida guardada que debe reanudar la escena de juego al cargarse (la deja el menú
## al pulsar "Continuar"). GameController la lee una vez y la vacía.
var pending_run: Dictionary = {}

# ── Estado de la run ──────────────────────────────────────────────────────────

## Número de la oleada actual (1-based). 0 = fuera de partida.
var current_wave: int = 0

## Energon acumulado en la run actual.
## Solo modificar mediante add_energon()/spend_energon().
var current_energon: int = 0

## Puntos de habilidad disponibles en la run actual.
## Solo modificar mediante add_skill_points()/spend_skill_points().
var available_skill_points: int = 0

## IDs de nodos del árbol de habilidades desbloqueados en esta run.
var unlocked_skill_ids: Array[String] = []

## True si hay una partida activa (para saber si mostrar "Continuar" en menú).
var run_active: bool = false

## True si la run fue completada con victoria.
var run_completed: bool = false

# ── Estadísticas de la run (para pantalla de resultados) ─────────────────────

var enemies_killed: int = 0
var damage_dealt: float = 0.0
var damage_received: float = 0.0
var times_transformed: int = 0

## Total de oleadas de la run (lo informa WaveManager al empezar cada oleada).
var total_waves: int = 0

## Segundos jugados en la run (no cuentan los menús: el juego está en pausa).
var run_time: float = 0.0

## Energon recogido en total (el saldo actual baja al comprar).
var energon_earned: int = 0

## Objetos comprados en la tienda.
var shop_purchases: int = 0

## Jefes derrotados y nombre del último.
var bosses_defeated: int = 0
var last_boss_name: String = ""

## Vida del jugador en la última señal, para contar el daño recibido.
var _last_player_hp: float = -1.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.energon_collected.connect(_on_energon_collected)
	EventBus.skill_unlocked.connect(_on_skill_unlocked)
	EventBus.transform_activated.connect(_on_transform_activated)
	EventBus.game_over.connect(_on_game_over)
	EventBus.all_waves_completed.connect(_on_all_waves_completed)
	EventBus.enemy_damaged.connect(func(amount: float) -> void: damage_dealt += amount)
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.shop_item_bought.connect(func(_id: String) -> void: shop_purchases += 1)

func _process(delta: float) -> void:
	if run_active:
		run_time += delta


# ── API pública ───────────────────────────────────────────────────────────────

## Prepara el estado para una nueva run con el personaje y skin actuales.
## Llamar desde game.tscn al iniciar la partida.
func begin_run() -> void:
	current_wave = 0
	current_energon = selected_character_stats.starting_energon \
		if selected_character_stats else 0
	available_skill_points = selected_character_stats.starting_skill_points \
		if selected_character_stats else 0
	unlocked_skill_ids.clear()
	_notify_energon()
	_notify_skill_points()
	run_active = true
	run_completed = false
	enemies_killed = 0
	damage_dealt = 0.0
	damage_received = 0.0
	times_transformed = 0
	run_time = 0.0
	energon_earned = 0
	shop_purchases = 0
	bosses_defeated = 0
	last_boss_name = ""
	_last_player_hp = -1.0


## Limpia el estado al volver al menú principal.
func reset() -> void:
	run_active = false
	run_completed = false
	current_wave = 0
	pending_run = {}

# ── Economía de la run (única fuente de verdad) ───────────────────────────────

## Suma energon y avisa a la UI.
func add_energon(amount: int) -> void:
	current_energon += amount
	_notify_energon()


## Gasta energon. Devuelve false (sin cambios) si no hay saldo suficiente.
func spend_energon(amount: int) -> bool:
	if current_energon < amount:
		return false
	current_energon -= amount
	_notify_energon()
	return true


## Suma puntos de habilidad y avisa a la UI.
func add_skill_points(amount: int) -> void:
	available_skill_points += amount
	_notify_skill_points()


## Gasta puntos de habilidad. Devuelve false si no hay suficientes.
func spend_skill_points(amount: int) -> bool:
	if available_skill_points < amount:
		return false
	available_skill_points -= amount
	_notify_skill_points()
	return true


## Devuelve el estado de la run como un Dictionary de tipos simples (para guardarlo).
func to_snapshot() -> Dictionary:
	return {
		"character_id": selected_character_id,
		"skin_id": selected_skin_id,
		"current_wave": current_wave,
		"total_waves": total_waves,
		"energon": current_energon,
		"skill_points": available_skill_points,
		"unlocked_skill_ids": unlocked_skill_ids.duplicate(),
		"stats": {
			"enemies_killed": enemies_killed,
			"damage_dealt": damage_dealt,
			"damage_received": damage_received,
			"times_transformed": times_transformed,
			"run_time": run_time,
			"energon_earned": energon_earned,
			"shop_purchases": shop_purchases,
			"bosses_defeated": bosses_defeated,
			"last_boss_name": last_boss_name,
		},
	}


## Pone el estado de la run desde un guardado (lo contrario de to_snapshot).
func restore_snapshot(snapshot: Dictionary) -> void:
	current_wave = int(snapshot.get("current_wave", 0))
	total_waves = int(snapshot.get("total_waves", 0))
	unlocked_skill_ids.assign(snapshot.get("unlocked_skill_ids", []))
	var stats: Dictionary = snapshot.get("stats", {})
	enemies_killed = int(stats.get("enemies_killed", 0))
	damage_dealt = float(stats.get("damage_dealt", 0.0))
	damage_received = float(stats.get("damage_received", 0.0))
	times_transformed = int(stats.get("times_transformed", 0))
	run_time = float(stats.get("run_time", 0.0))
	energon_earned = int(stats.get("energon_earned", 0))
	shop_purchases = int(stats.get("shop_purchases", 0))
	bosses_defeated = int(stats.get("bosses_defeated", 0))
	last_boss_name = str(stats.get("last_boss_name", ""))
	# El próximo cambio de vida que se reciba no debe contarse como daño.
	_last_player_hp = -1.0
	run_active = true
	restore_economy(int(snapshot.get("energon", 0)), int(snapshot.get("skill_points", 0)))


## Restaura la economía desde un guardado y avisa a la UI.
func restore_economy(energon: int, skill_points: int) -> void:
	current_energon = energon
	available_skill_points = skill_points
	_notify_energon()
	_notify_skill_points()


func _notify_energon() -> void:
	EventBus.player_energon_changed.emit(current_energon)


func _notify_skill_points() -> void:
	EventBus.skill_points_changed.emit(available_skill_points)

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_wave_started(wave_number: int, total: int) -> void:
	current_wave = wave_number
	total_waves = total


func _on_enemy_died(_enemy: Node) -> void:
	enemies_killed += 1


func _on_energon_collected(amount: int, _total: int) -> void:
	energon_earned += amount
	add_energon(amount)


func _on_player_hp_changed(current: float, _maximum: float) -> void:
	if _last_player_hp >= 0.0 and current < _last_player_hp:
		damage_received += _last_player_hp - current
	_last_player_hp = current


func _on_boss_defeated(boss: Node) -> void:
	bosses_defeated += 1
	if boss.get("stats") != null:
		last_boss_name = boss.stats.enemy_name


func _on_skill_unlocked(skill_id: String) -> void:
	if not unlocked_skill_ids.has(skill_id):
		unlocked_skill_ids.append(skill_id)


func _on_transform_activated(_character: Node) -> void:
	times_transformed += 1


func _on_game_over() -> void:
	run_active = false


func _on_all_waves_completed() -> void:
	run_active = false
	run_completed = true
