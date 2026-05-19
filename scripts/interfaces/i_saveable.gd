# i_saveable.gd
# Interfaz para cualquier sistema cuyo estado deba persistirse.
# SRP: la lógica de serialización vive aquí, separada de la lógica de juego.
# DIP: save_manager.gd depende de esta interfaz, no de clases concretas.

class_name ISaveable


## Serializa el estado actual del sistema en un Dictionary.
## El Dictionary debe contener solo tipos primitivos (int, float, String, Array, Dictionary)
## para ser compatible con el sistema de guardado de Godot.
func save_data() -> Dictionary:
	push_error("save_data() no implementado en: " + get_script().resource_path)
	return {}


## Restaura el estado del sistema a partir de un Dictionary guardado.
## [param data] Dictionary con los datos previamente guardados por save_data().
func load_data(data: Dictionary) -> void:
	push_error("load_data() no implementado en: " + get_script().resource_path)
