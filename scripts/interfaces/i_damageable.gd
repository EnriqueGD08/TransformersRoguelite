# i_damageable.gd
# Interfaz para cualquier entidad que pueda recibir daño.
# SRP: solo responsabilidad de recibir daño y reportar estado vital.
# ISP: separada de movimiento, ataque y transformación.
 
class_name IDamageable
 
 
## Aplica una cantidad de daño a la entidad.
## [param amount] Cantidad de daño a recibir. Debe ser >= 0.
func take_damage(amount: float) -> void:
	push_error("take_damage() no implementado en: " + get_script().resource_path)
 
 
## Devuelve true si la entidad sigue con vida (HP > 0).
func is_alive() -> bool:
	push_error("is_alive() no implementado en: " + get_script().resource_path)
	return false
 
 
## Devuelve el HP actual de la entidad.
func get_current_hp() -> float:
	push_error("get_current_hp() no implementado en: " + get_script().resource_path)
	return 0.0
 
 
## Devuelve el HP máximo de la entidad.
func get_max_hp() -> float:
	push_error("get_max_hp() no implementado en: " + get_script().resource_path)
	return 0.0
