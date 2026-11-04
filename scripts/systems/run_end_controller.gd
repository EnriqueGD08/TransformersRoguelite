# run_end_controller.gd
# Pantalla provisional de final de run (derrota o victoria).
# SRP: mostrar el resultado y permitir reintentar.
# DIP: escucha EventBus.game_over y EventBus.all_waves_completed.

class_name RunEndController
extends CanvasLayer

@onready var _panel: Control = $Panel
@onready var _title: Label = $Panel/VBox/Title
@onready var _stats: Label = $Panel/VBox/Stats
@onready var _button: Button = $Panel/VBox/RetryButton
@onready var _menu_button: Button = $Panel/VBox/MenuButton


func _ready() -> void:
	_panel.hide()
	EventBus.game_over.connect(_show_result.bind("GAME OVER"))
	EventBus.all_waves_completed.connect(_show_result.bind("¡VICTORIA!"))
	_button.pressed.connect(_on_retry_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)


func _show_result(title: String) -> void:
	_title.text = title
	_stats.text = "Enemigos derrotados: %d\nTransformaciones: %d" % [
		GameState.enemies_killed, GameState.times_transformed
	]
	_panel.show()
	_button.grab_focus()


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
