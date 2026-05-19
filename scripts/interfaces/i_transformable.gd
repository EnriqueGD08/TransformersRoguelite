# i_transformable.gd
# Interfaz para personajes con habilidad de transformación activa.
# Cada personaje implementa su propia lógica de transformación
# sin modificar la clase base (OCP).

class_name ITransformable


## Activa el modo transformado si no está en cooldown.
## Cada implementación define sus propios efectos.
func transform_activate() -> void:
	push_error("transform_activate() no implementado en: " + get_script().resource_path)


## Desactiva el modo transformado y reinicia el cooldown.
func transform_deactivate() -> void:
	push_error("transform_deactivate() no implementado en: " + get_script().resource_path)


## Devuelve true si la transformación está actualmente activa.
func is_transformed() -> bool:
	push_error("is_transformed() no implementado en: " + get_script().resource_path)
	return false


## Devuelve true si la habilidad está en cooldown (no disponible).
func on_cooldown() -> bool:
	push_error("on_cooldown() no implementado en: " + get_script().resource_path)
	return false


## Devuelve el tiempo restante de cooldown en segundos.
func get_cooldown_remaining() -> float:
	push_error("get_cooldown_remaining() no implementado en: " + get_script().resource_path)
	return 0.0


## Devuelve la duración total del cooldown en segundos.
func get_cooldown_duration() -> float:
	push_error("get_cooldown_duration() no implementado en: " + get_script().resource_path)
	return 0.0
