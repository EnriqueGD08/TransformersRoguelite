# victory_test.gd
# Herramienta de desarrollo: prueba de la pantalla de victoria. Juega unos segundos de la
# primera oleada (para tener estadísticas reales), salta a la última oleada y la completa;
# comprueba que se gana directamente (sin árbol ni tienda), que la pantalla aparece con el
# juego en pausa y que "Jugar de nuevo" reinicia y despausa. Imprime los resultados.
# Para verla: añade --write-movie (necesita ventana):
#   godot --path . --resolution 1280x720 --fixed-fps 30 --write-movie /tmp/v/f.png -s tools/victory_test.gd
extends SceneTree


func _init() -> void:
	await process_frame
	var state = root.get_node("GameState")
	var bus = root.get_node("EventBus")
	state.selected_character_scene = load("res://scenes/player_%s.tscn" % _who())
	state.selected_skin_id = "prime"
	change_scene_to_file("res://scenes/game.tscn")
	await create_timer(0.4).timeout
	var game: Node = current_scene
	# Las pruebas con ventana arrancan sin foco: sin esto la pausa automática se abriría sola.
	game.get_node("PauseMenu").pause_on_focus_loss = false
	game.get_node("PauseMenu")._close()
	var player: Node = null
	for c in game.get_node("World").get_children():
		if c.has_method("request_transform"):
			player = c
	player.add_stat_modifier("max_hp", 50000.0)
	# Un rato de juego real: ataca, se transforma, cobra daño y recoge energon.
	for i in 150:
		Input.action_press("attack")
		await process_frame
	player.request_transform()
	player.take_damage(25.0)
	await create_timer(0.5).timeout
	Input.action_release("attack")
	print("estadísticas reales: enemigos=%d daño causado=%.0f daño recibido=%.0f transformaciones=%d tiempo=%.1f s" % [
		state.enemies_killed, state.damage_dealt, state.damage_received, state.times_transformed, state.run_time])
	# Cifras de una partida larga, para que la pantalla se vea como al final de verdad.
	state.enemies_killed = 1840
	state.damage_dealt = 412650.0
	state.damage_received = 9830.0
	state.times_transformed = 47
	state.energon_earned = 5210
	state.shop_purchases = 23
	state.bosses_defeated = 4
	state.last_boss_name = "Galvatron"
	state.run_time = 1523.0
	state.unlocked_skill_ids.assign(["a", "b", "c", "d", "e", "f", "g", "h", "i"])

	# Última oleada: se gana directamente
	var wm: Node = game.get_node("Systems/WaveManager")
	var tree_ui: Node = game.get_node("SkillTree")
	var shop_ui: Node = game.get_node("Shop")
	var victory: Node = game.get_node("VictoryScreen")
	wm._current_wave_index = wm.waves.size() - 1
	state.total_waves = wm.waves.size()
	state.current_wave = wm.waves.size()
	wm._wave_active = true
	wm._complete_wave()
	await create_timer(0.3).timeout
	print("victoria visible=%s ; árbol visible=%s ; tienda visible=%s ; pausado=%s (esperado true, false, false, true)" % [
		victory._root.visible, tree_ui._root.visible, shop_ui._root.visible, paused])
	await create_timer(5.2).timeout
	print("título: '%s' ; subtítulo: '%s' ; personaje: '%s' ; filas del resumen: %d (esperado 10)" % [
		victory._title.text, victory._subtitle.text, victory._character_label.text, victory._stats_list.get_child_count()])
	var first_row: Node = victory._stats_list.get_child(2)
	print("fila 'enemigos' tras contar: %s = %s (esperado 1.840)" % [first_row.get_child(0).text, first_row.get_child(1).text])
	if "--no-retry" in OS.get_cmdline_user_args():
		quit()
		return
	# Jugar de nuevo
	victory._retry_button.pressed.emit()
	await create_timer(0.6).timeout
	print("tras 'Jugar de nuevo': pausado=%s ; enemigos derrotados reiniciados=%s ; victoria oculta=%s (esperado false, true, true)" % [
		paused, state.enemies_killed < 100, not current_scene.get_node("VictoryScreen")._root.visible])
	quit()


func _who() -> String:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			return a
	return "bumblebee"
