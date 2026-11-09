# smoke_test.gd
# Herramienta de desarrollo: prueba de humo. Cada personaje juega unos segundos de la
# primera oleada con el botón de ataque pulsado; si algo falla al cargar arte, escenas o
# armas, aparece como ERROR en la salida.
# Uso: godot --headless --path . -s tools/smoke_test.gd
extends SceneTree


func _init() -> void:
	await process_frame
	var state = root.get_node("GameState")
	for who in ["optimus", "bumblebee", "megatron", "starscream", "arcee", "shockwave"]:
		state.selected_character_scene = load("res://scenes/player_%s.tscn" % who)
		state.selected_skin_id = "prime"
		change_scene_to_file("res://scenes/game.tscn")
		await create_timer(0.3).timeout
		var player: Node = null
		for child in current_scene.get_node("World").get_children():
			if child.has_method("request_transform"):
				player = child
		player.add_stat_modifier("max_hp", 50000.0)
		for i in 120:
			Input.action_press("attack")
			await process_frame
		print(who, ": enemigos vivos=", get_nodes_in_group("enemies").size(), " anim=", player._sprite.animation)
	quit()
