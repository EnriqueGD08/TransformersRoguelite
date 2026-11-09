# save_manager.gd
# Autoload: guarda y lee en disco la partida en curso (una sola).
# SRP: solo escribe, lee y borra el archivo de guardado. NO sabe qué contiene la partida
#      (eso lo reúne RunPersistence) ni cuándo guardar (eso lo decide el flujo de oleadas).
# La partida es de una sola vida: al morir o ganar se borra.
# En la versión web, "user://" se guarda en el navegador (IndexedDB) y se conserva entre visitas.

extends Node

const SAVE_PATH: String = "user://run_save.cfg"

## Cambia si cambia el formato del guardado: los guardados de otra versión se ignoran.
const SAVE_VERSION: int = 2


func _ready() -> void:
	# Run terminada (derrota o victoria): ya no hay nada que continuar.
	EventBus.game_over.connect(delete_run)
	EventBus.all_waves_completed.connect(delete_run)


## Escribe la partida. [param snapshot] es un Dictionary con tipos simples (números, textos,
## listas y diccionarios). Devuelve false si no se pudo escribir.
func write_run(snapshot: Dictionary) -> bool:
	var config := ConfigFile.new()
	config.set_value("meta", "version", SAVE_VERSION)
	config.set_value("run", "snapshot", snapshot)
	var err: int = config.save(SAVE_PATH)
	if err != OK:
		push_error("SaveManager: no se pudo guardar la partida (código %d)" % err)
	return err == OK


## Devuelve la partida guardada, o un Dictionary vacío si no hay ninguna válida.
func read_run() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		push_warning("SaveManager: el guardado está dañado y se ignora")
		return {}
	if int(config.get_value("meta", "version", 0)) != SAVE_VERSION:
		push_warning("SaveManager: el guardado es de otra versión y se ignora")
		return {}
	var snapshot: Variant = config.get_value("run", "snapshot", {})
	return snapshot if snapshot is Dictionary else {}


func has_run() -> bool:
	return not read_run().is_empty()


func delete_run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
