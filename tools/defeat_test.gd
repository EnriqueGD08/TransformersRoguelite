# defeat_test.gd
# Herramienta de desarrollo: prueba de la pantalla de derrota. Juega unos segundos, mata al
# jugador y comprueba que la pantalla aparece (tras su retardo) con el juego en pausa, que
# el resumen tiene 10 filas y que "Reintentar" reinicia y despausa. Imprime los resultados.
# Para verla (necesita ventana):
#   godot --path . --resolution 1280x720 --fixed-fps 30 --write-movie /tmp/d/f.png -s tools/defeat_test.gd
extends SceneTree


func _init() -> void:
	await process_frame
	var state = root.get_node("GameState")
	state.selected_character_scene = load("res://scenes/player_%s.tscn" % _who())
	state.selected_skin_id = "prime"
	change_scene_to_file("res://scenes/game.tscn")
	await create_timer(0.4).timeout
	var game: Node = current_scene
	game.get_node("PauseMenu").pause_on_focus_loss = false
	game.get_node("PauseMenu")._close()
	var player: Node = null
	for c in game.get_node("World").get_children():
		if c.has_method("request_transform"):
			player = c
	for i in 90:
		Input.action_press("attack")
		await process_frame
	Input.action_release("attack")
	state.enemies_killed = 312
	state.damage_dealt = 48210.0
	state.damage_received = 3920.0
	state.times_transformed = 9
	state.energon_earned = 840
	state.shop_purchases = 4
	state.run_time = 412.0
	state.current_wave = 6
	state.total_waves = 12
	var defeat: Node = game.get_node("DefeatScreen")
	player.take_damage(999999.0)
	await create_timer(0.5).timeout
	print("a los 0,5 s: pantalla visible=%s (esperado false, aún cae)" % defeat._root.visible)
	await create_timer(1.5).timeout
	print("pantalla visible=%s ; pausado=%s (esperado true, true)" % [defeat._root.visible, paused])
	await create_timer(4.0).timeout
	print("título='%s' ; subtítulo='%s' ; personaje='%s' ; filas=%d (esperado 10)" % [
		defeat._title.text, defeat._subtitle.text, defeat._character_label.text, defeat._stats_list.get_child_count()])
	var row: Node = defeat._stats_list.get_child(2)
	print("fila enemigos: %s = %s (esperado 312)" % [row.get_child(0).text, row.get_child(1).text])
	if "--no-retry" in OS.get_cmdline_user_args():
		quit()
		return
	defeat._retry_button.pressed.emit()
	await create_timer(0.6).timeout
	print("tras Reintentar: pausado=%s ; enemigos reiniciados=%s ; pantalla oculta=%s (esperado false, true, true)" % [
		paused, state.enemies_killed < 100, not current_scene.get_node("DefeatScreen")._root.visible])
	quit()


func _who() -> String:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			return a
	return "optimus"
