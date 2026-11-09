# game_controller.gd
# Raíz de la escena de partida: instancia al jugador y conecta los sistemas.
# SRP: solo "cablea" la run (jugador + spawner + oleadas + energon).
#      La lógica de cada sistema vive en su propio script.
# DIP: el personaje viene de GameState (lo elige el menú); si no hay ninguno
#      seleccionado usa Optimus Prime para poder probar la escena directamente.

class_name GameController
extends Node2D

## Personaje por defecto si no se pasó por la selección de personaje.
@export var default_player_scene: PackedScene

## Árbol de habilidades del personaje por defecto.
@export var default_skill_tree: SkillTreeData

@onready var _world: Node2D = $World
@onready var _enemies: Node2D = $World/Enemies
@onready var _spawner: EnemySpawner = $Systems/EnemySpawner
@onready var _wave_manager: WaveManager = $Systems/WaveManager
@onready var _energon_manager: EnergonManager = $Systems/EnergonManager
@onready var _skill_tree_manager: SkillTreeManager = $Systems/SkillTreeManager
@onready var _passives: PassiveAbilities = $Systems/PassiveAbilities
@onready var _skill_tree_ui: SkillTreeUI = $SkillTree
@onready var _shop_manager: ShopManager = $Systems/ShopManager
@onready var _shop_ui: ShopUI = $Shop


func _ready() -> void:
	GameState.begin_run()

	var scene: PackedScene = GameState.selected_character_scene \
		if GameState.selected_character_scene != null else default_player_scene
	var player: Node2D = scene.instantiate()
	# Skin elegida en la selección: se indica antes de añadirlo para no cargar otra de más.
	player.set("initial_skin", GameState.selected_skin_id)
	_world.add_child(player)

	_spawner.setup(player, _enemies)
	_energon_manager.setup(player)

	# Árbol de habilidades del personaje elegido (o el de por defecto).
	var tree_nodes: Array[SkillNodeData] = []
	tree_nodes.assign(GameState.selected_skill_tree)
	if tree_nodes.is_empty() and default_skill_tree != null:
		tree_nodes.assign(default_skill_tree.nodes)
	_skill_tree_manager.setup(tree_nodes, player)
	_skill_tree_ui.setup(_skill_tree_manager)
	_passives.setup(player)
	_shop_manager.setup(player, _passives)
	_shop_ui.setup(_shop_manager)
	_wave_manager.setup(_spawner)
	_wave_manager.start_run()
