# i_wave_observer.gd
# Interfaz para cualquier sistema que necesite reaccionar
# al inicio y fin de una oleada (patrón Observer).
# DIP: el WaveManager emite eventos; los observadores implementan esta interfaz
# sin conocerse entre sí.

class_name IWaveObserver


## Llamado por el WaveManager cuando comienza una nueva oleada.
## [param wave_number] Número de la oleada que empieza (1-based).
func on_wave_start(wave_number: int) -> void:
	push_error("on_wave_start() no implementado en: " + get_script().resource_path)


## Llamado por el WaveManager cuando se completa una oleada.
## [param wave_number] Número de la oleada completada.
## [param energon_earned] Energon ganado durante esa oleada.
func on_wave_end(wave_number: int, energon_earned: int) -> void:
	push_error("on_wave_end() no implementado en: " + get_script().resource_path)
