# i_attackable.gd
# Interfaz para cualquier entidad capaz de realizar ataques.
# ISP: separada de movimiento y recepción de daño.

class_name IAttackable


## Ejecuta el ataque principal de la entidad.
func attack() -> void:
	push_error("attack() no implementado en: " + get_script().resource_path)


## Devuelve el daño base del ataque actual.
func get_damage() -> float:
	push_error("get_damage() no implementado en: " + get_script().resource_path)
	return 0.0


## Devuelve true si la entidad puede atacar ahora mismo.
## (no está en cooldown de ataque, tiene munición, etc.)
func can_attack() -> bool:
	push_error("can_attack() no implementado en: " + get_script().resource_path)
	return false


## Devuelve el rango de ataque efectivo en píxeles.
func get_attack_range() -> float:
	push_error("get_attack_range() no implementado en: " + get_script().resource_path)
	return 0.0
