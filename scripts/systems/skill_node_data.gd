# skill_node_data.gd
# Resource que define un nodo del árbol de habilidades.
# SRP: contiene los datos y la lógica de aplicación de una habilidad concreta.
# ISP: implementa ISkillNode.
# OCP: nuevas habilidades se crean como nuevos .tres sin modificar el árbol.
# DIP: SkillTreeManager trabaja con ISkillNode, no con esta clase directamente.

class_name SkillNodeData
extends Resource

# ── Identificación ────────────────────────────────────────────────────────────

## ID único del nodo. Debe ser único dentro del árbol del personaje.
## Ejemplo: "optimus_hp_1", "optimus_transform_duration_2".
@export var id: String = ""

## Nombre visible en la UI del árbol.
@export var display_name: String = ""

## Descripción del efecto que muestra la UI al hacer hover.
@export_multiline var description: String = ""

## Icono que representa la habilidad en el árbol.
@export var icon: Texture2D

# ── Posición en el árbol (para la UI) ────────────────────────────────────────

## Posición del nodo en el canvas del árbol de habilidades (en píxeles).
@export var tree_position: Vector2 = Vector2.ZERO

# ── Requisitos y coste ────────────────────────────────────────────────────────

## Coste en puntos de habilidad para desbloquear este nodo.
@export_range(1, 10, 1) var cost: int = 1

## IDs de los nodos que deben estar desbloqueados antes que este.
@export var required_ids: Array[String] = []

# ── Efecto del nodo ───────────────────────────────────────────────────────────

## Tipo de efecto que aplica al desbloquearse.
@export_enum(
	"stat_bonus",         # Suma un valor a un stat del personaje.
	"transform_upgrade",  # Mejora algún aspecto de la transformación.
	"weapon_upgrade",     # Mejora un stat del arma.
	"passive_ability"     # Activa una habilidad pasiva especial.
) var effect_type: String = "stat_bonus"

## Nombre del stat a modificar (para stat_bonus y weapon_upgrade).
## Debe coincidir con un campo de CharacterStats o WeaponStats.
@export var target_stat: String = ""

## Valor del modificador (delta a sumar, no multiplicador).
@export var effect_value: float = 0.0

## ID de la habilidad pasiva especial (solo para passive_ability).
## Ejemplos: "optimus_regen_aura", "bumblebee_afterimage".
@export var passive_id: String = ""

# ── ISkillNode ────────────────────────────────────────────────────────────────

## Aplica el efecto del nodo al personaje.
## [param character] El personaje sobre el que se aplica.
func apply(character: Node) -> void:
	match effect_type:
		"stat_bonus":
			_apply_stat_bonus(character)
		"transform_upgrade":
			_apply_transform_upgrade(character)
		"weapon_upgrade":
			_apply_weapon_upgrade(character)
		"passive_ability":
			_apply_passive_ability(character)


## Revierte el efecto del nodo (para sistemas de reset de árbol si se implementa).
func revert(character: Node) -> void:
	match effect_type:
		"stat_bonus":
			if character.has_method("remove_stat_modifier"):
				character.remove_stat_modifier(target_stat, effect_value)
		"weapon_upgrade":
			_revert_weapon_upgrade(character)
		_:
			pass


func can_unlock(unlocked_ids: Array, available_points: int) -> bool:
	if available_points < cost:
		return false
	for req_id in required_ids:
		if not unlocked_ids.has(req_id):
			return false
	return true


func get_cost() -> int:
	return cost


func get_id() -> String:
	return id


func get_required_ids() -> Array:
	return required_ids

# ── Aplicación de efectos ─────────────────────────────────────────────────────

func _apply_stat_bonus(character: Node) -> void:
	if target_stat.is_empty():
		push_error("SkillNodeData: target_stat vacío en nodo '%s'" % id)
		return
	if character.has_method("add_stat_modifier"):
		character.add_stat_modifier(target_stat, effect_value)


func _apply_transform_upgrade(character: Node) -> void:
	if target_stat.is_empty() or not character.has_node("stats"):
		return
	# Los upgrades de transformación modifican directamente el CharacterStats.
	# Se duplica el Resource para no afectar a otras instancias.
	if character.stats and target_stat in character.stats:
		character.stats.set(target_stat, character.stats.get(target_stat) + effect_value)


func _apply_weapon_upgrade(character: Node) -> void:
	# Busca el primer arma hija del personaje y aplica la mejora.
	for child in character.get_children():
		if child is BaseWeapon:
			child.upgrade_stat(target_stat, effect_value)
			break


func _revert_weapon_upgrade(character: Node) -> void:
	for child in character.get_children():
		if child is BaseWeapon:
			child.upgrade_stat(target_stat, -effect_value)
			break


func _apply_passive_ability(character: Node) -> void:
	if passive_id.is_empty():
		push_error("SkillNodeData: passive_id vacío en nodo '%s'" % id)
		return
	# Las habilidades pasivas se activan emitiendo una señal al EventBus.
	# Cada personaje escucha las señales de sus propias pasivas.
	EventBus.skill_unlocked.emit(passive_id)
