# save_manager.gd
# Gestiona el guardado y carga del estado de la partida en disco.
# SRP: única responsabilidad es serializar y deserializar GameState a fichero.
#      No decide cuándo guardar — escucha EventBus.save_requested.
# ISP: implementa ISaveable a nivel de sistema global.
# DIP: lee y escribe GameState (autoload), no accede a nodos de la escena.
extends Node

# ── Configuración ─────────────────────────────────────────────────────────────

const SAVE_PATH: String = "user://savegame.cfg"
const SAVE_VERSION: int = 1

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.save_requested.connect(save_game)
	EventBus.load_requested.connect(load_game)

# ── ISaveable ─────────────────────────────────────────────────────────────────

## Serializa el estado actual de GameState y lo escribe en disco.
## Se llama automáticamente al recibir EventBus.save_requested.
func save_game() -> void:
	var data: Dictionary = _build_save_data()
	var config: ConfigFile = ConfigFile.new()

	config.set_value("meta", "version", SAVE_VERSION)
	config.set_value("meta", "timestamp", Time.get_unix_time_from_system())

	config.set_value("run", "character_id", data.character_id)
	config.set_value("run", "skin_id", data.skin_id)
	config.set_value("run", "current_wave", data.current_wave)
	config.set_value("run", "current_energon", data.current_energon)
	config.set_value("run", "available_skill_points", data.available_skill_points)
	config.set_value("run", "unlocked_skill_ids", data.unlocked_skill_ids)
	config.set_value("run", "run_active", data.run_active)

	config.set_value("stats", "enemies_killed", data.enemies_killed)
	config.set_value("stats", "damage_dealt", data.damage_dealt)
	config.set_value("stats", "damage_received", data.damage_received)
	config.set_value("stats", "times_transformed", data.times_transformed)

	var err: int = config.save(SAVE_PATH)
	if err != OK:
		push_error("SaveManager: error al guardar — código %d" % err)


## Carga el estado desde disco y lo restaura en GameState.
## Se llama automáticamente al recibir EventBus.load_requested.
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var config: ConfigFile = ConfigFile.new()
	var err: int = config.load(SAVE_PATH)
	if err != OK:
		push_error("SaveManager: error al cargar — código %d" % err)
		return

	var version: int = config.get_value("meta", "version", 0)
	if version != SAVE_VERSION:
		push_warning("SaveManager: versión de guardado incompatible (%d)" % version)
		return

	# Restaura el estado en GameState.
	GameState.selected_character_id = config.get_value("run", "character_id", "")
	GameState.selected_skin_id = config.get_value("run", "skin_id", "g1")
	GameState.current_wave = config.get_value("run", "current_wave", 0)
	GameState.restore_economy(
		config.get_value("run", "current_energon", 0),
		config.get_value("run", "available_skill_points", 0)
	)
	GameState.unlocked_skill_ids = config.get_value("run", "unlocked_skill_ids", [])
	GameState.run_active = config.get_value("run", "run_active", false)
	GameState.enemies_killed = config.get_value("stats", "enemies_killed", 0)
	GameState.damage_dealt = config.get_value("stats", "damage_dealt", 0.0)
	GameState.damage_received = config.get_value("stats", "damage_received", 0.0)
	GameState.times_transformed = config.get_value("stats", "times_transformed", 0)


## Elimina el archivo de guardado (al iniciar una nueva run desde cero).
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


## Devuelve true si existe un archivo de guardado con una run activa.
func has_active_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	return config.get_value("run", "run_active", false)

# ── Privados ──────────────────────────────────────────────────────────────────

func _build_save_data() -> Dictionary:
	return {
		"character_id": GameState.selected_character_id,
		"skin_id": GameState.selected_skin_id,
		"current_wave": GameState.current_wave,
		"current_energon": GameState.current_energon,
		"available_skill_points": GameState.available_skill_points,
		"unlocked_skill_ids": GameState.unlocked_skill_ids.duplicate(),
		"run_active": GameState.run_active,
		"enemies_killed": GameState.enemies_killed,
		"damage_dealt": GameState.damage_dealt,
		"damage_received": GameState.damage_received,
		"times_transformed": GameState.times_transformed,
	}
