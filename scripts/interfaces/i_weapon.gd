# i_weapon.gd
# Interfaz para todas las armas del juego (melee y a distancia).
# OCP: nuevas armas se añaden implementando esta interfaz,
# sin modificar ningún sistema existente.

class_name IWeapon


## Ejecuta el disparo o golpe del arma.
func fire() -> void:
	push_error("fire() no implementado en: " + get_script().resource_path)


## Devuelve true si el arma puede disparar ahora mismo.
func can_fire() -> bool:
	push_error("can_fire() no implementado en: " + get_script().resource_path)
	return false


## Devuelve el Resource con las estadísticas del arma.
func get_stats() -> Resource:
	push_error("get_stats() no implementado en: " + get_script().resource_path)
	return null


## Aplica una mejora al arma (por árbol de habilidades o buff).
## [param stat_name] Nombre del stat a modificar (ej: "damage", "fire_rate").
## [param value] Nuevo valor o delta a aplicar.
func upgrade_stat(stat_name: String, value: float) -> void:
	push_error("upgrade_stat() no implementado en: " + get_script().resource_path)
