# save_test.gd
# Herramienta de desarrollo: prueba del guardado entre partidas. Juega unos segundos (compra en
# la tienda, desbloquea una habilidad, recibe daño), guarda al empezar otra oleada, "sale" y
# continúa, y compara que todo vuelve igual. Comprueba también que morir o ganar borran el
# guardado y que el menú muestra "Continuar" solo cuando toca. Imprime los resultados.
# Uso: godot --headless --path . -s tools/save_test.gd
extends SceneTree


func _ok(value: bool) -> String:
	return "OK" if value else "FALLO"


func _find(parent: Node, name: String) -> Node:
	return parent.get_node(name)


func _init() -> void:
	await process_frame
	var state = root.get_node("GameState")
	var bus = root.get_node("EventBus")
	var saves = root.get_node("SaveManager")
	saves.delete_run()
	state.selected_character_scene = load("res://scenes/player_optimus.tscn")
	state.selected_character_id = "optimus_prime"
	state.selected_skin_id = "bay"

	# 1) Partida nueva: el primer punto de guardado ocurre al empezar la oleada 1
	change_scene_to_file("res://scenes/game.tscn")
	await create_timer(0.5).timeout
	var game: Node = current_scene
	var snapshot: Dictionary = saves.read_run()
	print("1) guardado al empezar la oleada 1: existe=%s next_wave_index=%s total_waves=%s (esperado true, 0, 20)" % [saves.has_run(), snapshot.get("next_wave_index"), snapshot.get("total_waves")])

	# 2) Se juega: compras, habilidad, daño y estadísticas
	var player = null
	for c in game.get_node("World").get_children():
		if c.has_method("request_transform"):
			player = c
	var shop = game.get_node("Systems/ShopManager")
	var tree = game.get_node("Systems/SkillTreeManager")
	var passives = game.get_node("Systems/PassiveAbilities")
	var wm = game.get_node("Systems/WaveManager")
	state.add_energon(900)
	state.add_skill_points(3)
	var unlocked_node := ""
	for node in tree.get_all_nodes():
		if tree.can_unlock(node.id):
			unlocked_node = node.id
			tree.unlock_node(node.id)
			break
	for id in ["hp", "hp", "dodge", "speed", "speed", "speed", "lifesteal"]:
		shop.buy(id)
	player.take_damage(40.0)
	state.enemies_killed = 77
	state.damage_dealt = 12345.0
	state.run_time = 321.0
	var before := {
		"max_hp": player.get_max_hp(), "hp": player.get_current_hp(), "speed": player.get_speed(),
		"energon": state.current_energon, "points": state.available_skill_points,
		"skills": state.unlocked_skill_ids.duplicate(), "purchases": shop.get_purchases_snapshot(),
		"lifesteal": passives.is_active("lifesteal"), "damage_received": state.damage_received,
	}
	print("2) antes de guardar: vida %.0f/%.0f, velocidad %.0f, energon %d, habilidad '%s', compras %s" % [
		before.hp, before.max_hp, before.speed, before.energon, unlocked_node, before.purchases])

	# 3) Empieza la oleada 4: se guarda
	wm._current_wave_index = 2
	wm._advance_to_next_wave()
	snapshot = saves.read_run()
	print("3) guardado al empezar la oleada 4: next_wave_index=%s (esperado 3), compras guardadas=%s" % [snapshot.get("next_wave_index"), snapshot.get("shop_purchases")])

	# 4) "Se cierra el juego" y se continúa: se carga la escena con la partida pendiente
	state.reset()
	state.selected_character_scene = load("res://scenes/player_optimus.tscn")
	state.selected_skin_id = "bay"
	state.pending_run = saves.read_run()
	change_scene_to_file("res://scenes/game.tscn")
	await create_timer(0.7).timeout
	game = current_scene
	for c in game.get_node("World").get_children():
		if c.has_method("request_transform"):
			player = c
	shop = game.get_node("Systems/ShopManager")
	passives = game.get_node("Systems/PassiveAbilities")
	wm = game.get_node("Systems/WaveManager")
	var checks := {
		"vida máxima": is_equal_approx(player.get_max_hp(), before.max_hp),
		"vida actual": is_equal_approx(player.get_current_hp(), before.hp),
		"velocidad": is_equal_approx(player.get_speed(), before.speed),
		"energon": state.current_energon == before.energon,
		"puntos de habilidad": state.available_skill_points == before.points,
		"habilidades": state.unlocked_skill_ids == before.skills,
		"compras": shop.get_purchases_snapshot() == before.purchases,
		"robo de energía activo": passives.is_active("lifesteal") == before.lifesteal,
		"enemigos derrotados": state.enemies_killed == 77,
		"daño causado": is_equal_approx(state.damage_dealt, 12345.0),
		"daño recibido (no debe aumentar al restaurar)": is_equal_approx(state.damage_received, before.damage_received),
		"oleada: empieza la 4": wm.get_current_wave_number() == 4,
		"partida pendiente consumida": state.pending_run.is_empty(),
	}
	print("4) tras continuar:")
	for k in checks:
		print("   %-48s %s" % [k, _ok(checks[k])])

	# 5) Morir o ganar borran el guardado
	print("5) antes de morir hay guardado: %s (esperado true)" % saves.has_run())
	bus.game_over.emit()
	print("   tras game_over: hay guardado=%s (esperado false)" % saves.has_run())
	saves.write_run({"character_id": "x"})
	bus.all_waves_completed.emit()
	print("   tras ganar: hay guardado=%s (esperado false)" % saves.has_run())

	# 6) Menú principal: "Continuar" solo con guardado válido
	var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	print("6) menú sin guardado: Continuar visible=%s, botón='%s' (esperado false, 'JUGAR')" % [menu._continue_button.visible, menu._play_button.text])
	saves.write_run({"character_id": "megatron", "skin_id": "prime", "next_wave_index": 6, "total_waves": 20})
	menu._refresh_continue()
	print("   con guardado: Continuar visible=%s, texto='%s', botón='%s' (esperado true, 'Megatron · oleada 7 / 20', 'NUEVA PARTIDA')" % [menu._continue_button.visible, menu._continue_info.text, menu._play_button.text])
	saves.write_run({"character_id": "no_existe", "next_wave_index": 1})
	menu._refresh_continue()
	print("   guardado de un personaje inexistente: Continuar visible=%s (esperado false)" % menu._continue_button.visible)
	saves.delete_run()
	quit()
