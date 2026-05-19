# i_movable.gd
# Interfaz para cualquier entidad que pueda desplazarse por el mapa.
# ISP: separada de daño, ataque y transformación.

class_name IMovable


## Mueve la entidad según su lógica propia (input del jugador o IA).
## [param delta] Tiempo transcurrido desde el último frame.
func move(delta: float) -> void:
	push_error("move() no implementado en: " + get_script().resource_path)


## Devuelve la velocidad de movimiento actual (puede estar modificada por buffs).
func get_speed() -> float:
	push_error("get_speed() no implementado en: " + get_script().resource_path)
	return 0.0


## Devuelve la dirección de movimiento actual como Vector2 normalizado.
func get_direction() -> Vector2:
	push_error("get_direction() no implementado en: " + get_script().resource_path)
	return Vector2.ZERO


## Aplica un modificador temporal de velocidad (por buff/debuff).
## [param multiplier] Factor multiplicador. 1.0 = velocidad base.
## [param duration] Duración en segundos. 0.0 = permanente hasta cancelar.
func apply_speed_modifier(multiplier: float, duration: float) -> void:
	push_error("apply_speed_modifier() no implementado en: " + get_script().resource_path)
