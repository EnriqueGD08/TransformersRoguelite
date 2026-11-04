# skill_tree_manager.gd
# Gestiona el estado del árbol de habilidades del personaje activo.
# SRP: única responsabilidad es rastrear qué nodos están desbloqueados,
#      y aplicar efectos al personaje. Los PUNTOS viven en GameState
#      (única fuente de verdad); aquí solo se consultan y se gastan.
# DIP: trabaja con ISkillNode (SkillNodeData), no con tipos concretos.
# OCP: añadir nuevos nodos solo requiere crear .tres; no tocar este sistema.

class_name SkillTreeManager
extends Node

# ── Señales ───────────────────────────────────────────────────────────────────

signal node_unlocked(node_id: String)
signal points_changed(available: int, total_spent: int)

# ── Estado ────────────────────────────────────────────────────────────────────

## Nodos disponibles en el árbol del personaje actual.
## Se asigna desde game.tscn cargando el .tres del personaje seleccionado.
var _tree_nodes: Array[SkillNodeData] = []

## IDs de los nodos ya desbloqueados en esta run.
var _unlocked_ids: Array[String] = []

## Total de puntos gastados en esta run.
var _spent_points: int = 0

## Referencia al personaje activo. Se asigna desde game.tscn.
var _character: Node = null

# ── Setup ─────────────────────────────────────────────────────────────────────

## Inicializa el árbol con los nodos del personaje y los puntos iniciales.
## [param nodes] Array de SkillNodeData del personaje seleccionado.
## [param character] Referencia al nodo del personaje jugable.
## Los puntos iniciales los fija GameState.begin_run().
func setup(nodes: Array[SkillNodeData], character: Node) -> void:
	_tree_nodes = nodes
	_character = character
	_unlocked_ids.clear()
	_spent_points = 0

	EventBus.xp_earned.connect(_on_xp_earned)
	EventBus.skill_points_changed.connect(_on_skill_points_changed)

	points_changed.emit(GameState.available_skill_points, _spent_points)

# ── API pública ───────────────────────────────────────────────────────────────

## Intenta desbloquear el nodo con [param node_id].
## Devuelve true si el desbloqueo fue exitoso.
func unlock_node(node_id: String) -> bool:
	var node: SkillNodeData = _find_node(node_id)
	if node == null:
		push_error("SkillTreeManager: nodo '%s' no encontrado" % node_id)
		return false

	if _unlocked_ids.has(node_id):
		return false

	if not node.can_unlock(_unlocked_ids, GameState.available_skill_points):
		return false

	if not GameState.spend_skill_points(node.get_cost()):
		return false
	_unlocked_ids.append(node_id)
	_spent_points += node.get_cost()

	node.apply(_character)

	node_unlocked.emit(node_id)
	EventBus.skill_unlocked.emit(node_id)
	return true


## Devuelve true si el nodo está desbloqueado.
func is_unlocked(node_id: String) -> bool:
	return _unlocked_ids.has(node_id)


## Devuelve true si el nodo puede desbloquearse ahora.
func can_unlock(node_id: String) -> bool:
	var node: SkillNodeData = _find_node(node_id)
	if node == null:
		return false
	return node.can_unlock(_unlocked_ids, GameState.available_skill_points)


## Devuelve los puntos de habilidad disponibles.
func get_available_points() -> int:
	return GameState.available_skill_points


## Devuelve todos los nodos del árbol (para que la UI los renderice).
func get_all_nodes() -> Array[SkillNodeData]:
	return _tree_nodes


## Devuelve los IDs de los nodos desbloqueados (para guardado).
func get_unlocked_ids() -> Array[String]:
	return _unlocked_ids.duplicate()


## Restaura el árbol desde datos guardados.
## [param unlocked_ids] IDs a marcar como desbloqueados.
## Los puntos disponibles los restaura GameState.restore_economy().
func restore_from_save(unlocked_ids: Array[String]) -> void:
	for id in unlocked_ids:
		var node: SkillNodeData = _find_node(id)
		if node:
			_unlocked_ids.append(id)
			node.apply(_character)
	points_changed.emit(GameState.available_skill_points, _spent_points)

# ── Privados ──────────────────────────────────────────────────────────────────

func _find_node(node_id: String) -> SkillNodeData:
	for node in _tree_nodes:
		if node.get_id() == node_id:
			return node
	return null

# ── Callbacks ─────────────────────────────────────────────────────────────────

## Por cada unidad de XP ganada se convierte en un punto de habilidad.
## Ajusta la tasa según el balance deseado.
func _on_xp_earned(amount: int) -> void:
	GameState.add_skill_points(amount)


## Reenvía a la UI local los cambios de puntos que anuncia GameState.
func _on_skill_points_changed(available: int) -> void:
	points_changed.emit(available, _spent_points)
