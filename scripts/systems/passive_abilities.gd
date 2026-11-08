# passive_abilities.gd
# Implementa las habilidades PASIVAS del árbol (las que no son un simple número).
# SRP: escucha EventBus.passive_activated y aplica el comportamiento de cada pasiva.
# OCP: una pasiva nueva = un id nuevo en el match; el árbol (datos) no cambia.
#
# Pasivas disponibles:
#   "lifesteal" : cura un % del daño que hacen las armas.
#   "last_stand": revive una vez con la mitad de la vida.
#   "kill_cdr"  : cada baja acorta el cooldown de la transformación.

class_name PassiveAbilities
extends Node

## Fracción del daño infligido que se convierte en vida (lifesteal).
@export_range(0.01, 0.5, 0.01) var lifesteal_ratio: float = 0.08

## Segundos que cada baja resta al cooldown de la transformación (kill_cdr).
@export_range(0.1, 5.0, 0.1) var kill_cooldown_reduction: float = 1.5

var _character: BaseCharacter = null
var _active: Dictionary = {}


## Inyección del personaje activo. Llamar al empezar la partida.
func setup(character: BaseCharacter) -> void:
	_character = character
	EventBus.passive_activated.connect(_on_passive_activated)
	EventBus.enemy_died.connect(_on_enemy_died)


func is_active(passive_id: String) -> bool:
	return _active.get(passive_id, false)


func _on_passive_activated(passive_id: String) -> void:
	if _active.get(passive_id, false) or _character == null:
		return
	_active[passive_id] = true
	match passive_id:
		"lifesteal":
			for child in _character.get_children():
				if child is BaseWeapon:
					child.hit.connect(_on_weapon_hit)
		"last_stand":
			_character.add_revive_charge(1)
		"kill_cdr":
			pass  # Se resuelve en _on_enemy_died.
		_:
			push_warning("PassiveAbilities: pasiva desconocida '%s'" % passive_id)


func _on_weapon_hit(_target: Node, damage: float) -> void:
	if _character != null and _character.is_alive():
		_character.heal(damage * lifesteal_ratio)


func _on_enemy_died(_enemy: Node) -> void:
	if _active.get("kill_cdr", false) and _character != null:
		_character.reduce_transform_cooldown(kill_cooldown_reduction)
