# interpolation_test.gd
# Herramienta de desarrollo: mueve al jugador a la derecha para comprobar la interpolación
# de física. Con el juego a más fotogramas que la física (120 FPS frente a 60 ticks) y
# grabando imágenes, se mide con tools/measure_scroll.py cuánto se desplaza el suelo en
# cada fotograma: sin interpolación avanza a saltos; con ella, de forma pareja.
# Necesita ventana:
#   godot --path . --resolution 1280x720 --fixed-fps 120 --write-movie /tmp/i/f.png \
#         -s tools/interpolation_test.gd
#   python3 tools/measure_scroll.py /tmp/i
extends SceneTree


func _init() -> void:
	await process_frame
	root.get_node("GameState").selected_character_scene = load("res://scenes/player_optimus.tscn")
	change_scene_to_file("res://scenes/game.tscn")
	await create_timer(0.5).timeout
	var game: Node = current_scene
	game.get_node("PauseMenu").pause_on_focus_loss = false
	game.get_node("PauseMenu")._close()
	print("interpolación activada: ", ProjectSettings.get_setting("physics/common/physics_interpolation", false))
	Input.action_press("move_right")
	await create_timer(1.2).timeout
	quit()
