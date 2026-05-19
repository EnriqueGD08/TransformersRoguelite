# i_skill_node.gd
# Interfaz para cada nodo del árbol de habilidades.
# ISP: solo responsabilidad de desbloqueo y aplicación de efecto.
# OCP: nuevas habilidades se añaden como nuevas clases, sin tocar el árbol.

class_name ISkillNode


## Aplica el efecto de la habilidad al personaje indicado.
## [param character] El personaje sobre el que se aplica.
func apply(character: Node) -> void:
	push_error("apply() no implementado en: " + get_script().resource_path)


## Revierte el efecto de la habilidad (si el nodo se desbloquea en partida).
## [param character] El personaje sobre el que se revierte.
func revert(character: Node) -> void:
	push_error("revert() no implementado en: " + get_script().resource_path)


## Devuelve true si este nodo puede desbloquearse.
## Comprueba requisitos (nodos previos desbloqueados, puntos suficientes).
## [param unlocked_ids] Lista de IDs de nodos ya desbloqueados.
## [param available_points] Puntos de habilidad disponibles.
func can_unlock(unlocked_ids: Array, available_points: int) -> bool:
	push_error("can_unlock() no implementado en: " + get_script().resource_path)
	return false


## Devuelve el coste en puntos de habilidad para desbloquear este nodo.
func get_cost() -> int:
	push_error("get_cost() no implementado en: " + get_script().resource_path)
	return 0


## Devuelve el identificador único de este nodo.
func get_id() -> String:
	push_error("get_id() no implementado en: " + get_script().resource_path)
	return ""


## Devuelve los IDs de los nodos requeridos antes de desbloquear este.
func get_required_ids() -> Array:
	push_error("get_required_ids() no implementado en: " + get_script().resource_path)
	return []
