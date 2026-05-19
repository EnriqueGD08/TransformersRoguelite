# i_hud_updatable.gd
# Interfaz para actualizar los elementos visuales del HUD.
# ISP: el HUD solo recibe datos ya calculados; no accede a la lógica de juego.
# DIP: hud_controller.gd implementa esta interfaz; los sistemas la llaman
# sin conocer la implementación concreta del HUD.

class_name IHudUpdatable


## Actualiza la barra y valor de HP del jugador.
## [param current] HP actual.
## [param maximum] HP máximo.
func update_hp(current: float, maximum: float) -> void:
	push_error("update_hp() no implementado en: " + get_script().resource_path)


## Actualiza el indicador de cooldown de la transformación.
## [param remaining] Tiempo restante en segundos.
## [param total] Duración total del cooldown en segundos.
func update_cooldown(remaining: float, total: float) -> void:
	push_error("update_cooldown() no implementado en: " + get_script().resource_path)


## Actualiza el contador de energon del jugador.
## [param amount] Cantidad actual de energon.
func update_energon(amount: int) -> void:
	push_error("update_energon() no implementado en: " + get_script().resource_path)


## Actualiza el indicador de número de oleada.
## [param wave_number] Oleada actual.
## [param total_waves] Total de oleadas de la run.
func update_wave(wave_number: int, total_waves: int) -> void:
	push_error("update_wave() no implementado en: " + get_script().resource_path)


## Muestra u oculta el icono de modo transformado activo.
## [param is_active] true si la transformación está activa.
func update_transform_indicator(is_active: bool) -> void:
	push_error("update_transform_indicator() no implementado en: " + get_script().resource_path)
