# settings.gd
# Autoload: preferencias del jugador que se conservan entre sesiones (volumen de música y efectos).
# SRP: solo guarda y aplica las preferencias. No reproduce audio (eso es AudioManager) ni
#      dibuja los controles (eso es el menú de pausa).
# Los volúmenes (0 a 1) se aplican a los canales "Music" y "SFX" del AudioServer, por encima
# del volumen base que fija AudioManager.

extends Node

const SETTINGS_PATH: String = "user://settings.cfg"

## Volumen de la música (0 = mudo, 1 = el de diseño).
var music_volume: float = 1.0

## Volumen de los efectos de sonido.
var sfx_volume: float = 1.0


func _ready() -> void:
	_load()
	_apply()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply()


## Guarda las preferencias en disco. Se llama al soltar un control, no en cada cambio.
func save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	var err: int = config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Settings: no se pudieron guardar las preferencias (código %d)" % err)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	music_volume = clampf(float(config.get_value("audio", "music_volume", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", 1.0)), 0.0, 1.0)


func _apply() -> void:
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(linear) if linear > 0.001 else -80.0)
