# run_persistence.gd
# Reúne el estado de la partida para guardarlo y lo vuelve a poner al continuar.
# SRP: sabe QUÉ forma la partida guardada (estadísticas, economía, habilidades, compras,
#      vida del personaje y oleada) y a qué sistema devolver cada parte. El disco lo gestiona
#      SaveManager y cuándo guardar lo decide WaveManager (señal checkpoint_reached).
# DIP: recibe los sistemas por setup(); no los busca en la escena.

class_name RunPersistence
extends Node

var _player: BaseCharacter = null
var _wave_manager: WaveManager = null
var _skill_tree: SkillTreeManager = null
var _shop: ShopManager = null


func setup(player: BaseCharacter, wave_manager: WaveManager, skill_tree: SkillTreeManager, shop: ShopManager) -> void:
	_player = player
	_wave_manager = wave_manager
	_skill_tree = skill_tree
	_shop = shop
	EventBus.checkpoint_reached.connect(_on_checkpoint)


## Guarda la partida justo antes de empezar la oleada [param next_wave_index] (empezando en 0).
func _on_checkpoint(next_wave_index: int) -> void:
	var snapshot: Dictionary = GameState.to_snapshot()
	snapshot["next_wave_index"] = next_wave_index
	# El primer guardado ocurre antes de que GameState sepa el total de oleadas.
	snapshot["total_waves"] = _wave_manager.get_total_waves()
	snapshot["shop_purchases"] = _shop.get_purchases_snapshot()
	snapshot["player"] = _player.get_save_state()
	SaveManager.write_run(snapshot)


## Pone la partida guardada en los sistemas. Llamar antes de que empiece la primera oleada.
## El orden importa: primero se reaplican las mejoras al personaje (suben su vida máxima) y
## solo al final se ajustan su vida y las estadísticas, para que nada de eso cuente como daño.
func restore(snapshot: Dictionary) -> void:
	var unlocked: Array[String] = []
	unlocked.assign(snapshot.get("unlocked_skill_ids", []))
	_skill_tree.restore_from_save(unlocked)
	_shop.restore_purchases(snapshot.get("shop_purchases", {}))
	_player.restore_save_state(snapshot.get("player", {}))
	GameState.restore_snapshot(snapshot)
	_wave_manager.resume_at(int(snapshot.get("next_wave_index", 0)))
