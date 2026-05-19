# i_skin_provider.gd
# Interfaz para gestionar las skins visuales de un personaje.
# ISP: separada de toda lógica de juego. Cambiar skin no afecta stats.

class_name ISkinProvider


## Aplica la skin indicada al sprite del personaje.
## [param skin_id] Identificador de skin: "g1", "prime" o "bay".
func set_skin(skin_id: String) -> void:
	push_error("set_skin() no implementado en: " + get_script().resource_path)


## Devuelve el ID de la skin actualmente activa.
func get_current_skin() -> String:
	push_error("get_current_skin() no implementado en: " + get_script().resource_path)
	return ""


## Devuelve la lista de IDs de skins disponibles para este personaje.
func get_available_skins() -> Array:
	push_error("get_available_skins() no implementado en: " + get_script().resource_path)
	return []
