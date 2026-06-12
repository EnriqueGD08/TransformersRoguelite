# i_spawnable.gd
# Interfaz para cualquier entidad que pueda ser instanciada
# y eliminada por el sistema de oleadas.
# ISP: separada de daño, movimiento y ataque.

class_name ISpawnable


## Instancia y coloca la entidad en el mundo.
## [param spawn_position] Posición global donde aparece.
func spawn(spawn_position: Vector2) -> void:
	push_error("spawn() no implementado en: " + get_script().resource_path)


## Elimina la entidad del mundo de forma limpia
## (animación de muerte, drop de energon, etc.).
func despawn() -> void:
	push_error("despawn() no implementado en: " + get_script().resource_path)


## Devuelve true si la entidad está actualmente activa en el mundo.
func is_active() -> bool:
	push_error("is_active() no implementado en: " + get_script().resource_path)
	return false
