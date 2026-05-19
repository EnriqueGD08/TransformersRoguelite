# i_audio_emitter.gd
# Interfaz para reproducir efectos de sonido y música.
# ISP: separada de toda lógica de juego.
# DIP: los sistemas piden sonidos a esta interfaz, no al AudioManager directamente.

class_name IAudioEmitter


## Reproduce un efecto de sonido por su identificador.
## [param sfx_id] Identificador del sonido (ej: "shoot", "transform", "hit").
## [param volume_db] Volumen en decibelios. 0.0 = volumen original.
func play_sfx(sfx_id: String, volume_db: float = 0.0) -> void:
	push_error("play_sfx() no implementado en: " + get_script().resource_path)


## Detiene un efecto de sonido en curso.
## [param sfx_id] Identificador del sonido a detener.
func stop_sfx(sfx_id: String) -> void:
	push_error("stop_sfx() no implementado en: " + get_script().resource_path)


## Reproduce una pista de música por su identificador.
## [param track_id] Identificador de la pista (ej: "battle", "menu", "victory").
## [param loop] Si la pista debe repetirse en bucle.
func play_music(track_id: String, loop: bool = true) -> void:
	push_error("play_music() no implementado en: " + get_script().resource_path)


## Detiene la música en curso con un fade opcional.
## [param fade_duration] Duración del fade en segundos. 0.0 = corte inmediato.
func stop_music(fade_duration: float = 0.0) -> void:
	push_error("stop_music() no implementado en: " + get_script().resource_path)
