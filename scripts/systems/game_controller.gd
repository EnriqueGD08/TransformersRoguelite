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

@onready var _world: Node2D = $World
@onready var _enemies: Node2D = $World/Enemies
@onready var _spawner: EnemySpawner = $Systems/EnemySpawner
@onready var _wave_manager: WaveManager = $Systems/WaveManager
@onready var _energon_manager: EnergonManager = $Systems/EnergonManager


func _ready() -> void:
	GameState.begin_run()

	var scene: PackedScene = GameState.selected_character_scene \
		if GameState.selected_character_scene != null else default_player_scene
	var player: Node2D = scene.instantiate()
	_world.add_child(player)
	# Skin elegida en la selección (si no hay ninguna, la del personaje).
	if GameState.selected_skin_id != "" and player.has_method("set_skin"):
		player.set_skin(GameState.selected_skin_id)

	_spawner.setup(player, _enemies)
	_energon_manager.setup(player)
	_wave_manager.setup(_spawner)
	_wave_manager.start_run()
