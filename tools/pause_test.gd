# pause_test.gd
# Herramienta de desarrollo: prueba del menú de pausa. Comprueba que Esc/P y el botón la abren y
# cierran, que se ignora cuando otra pantalla ya pausa el juego (tienda) o no hay partida, que
# el volumen se aplica y se guarda, y que "Salir al menú" vuelve al menú despausado.
# Imprime los resultados. Uso: godot --headless --path . -s tools/pause_test.gd
extends SceneTree


func _press_pause() -> void:
	for pressed in [true, false]:
		var e := InputEventAction.new()
		e.action = "pause"
		e.pressed = pressed
		Input.parse_input_event(e)
	await process_frame
	await process_frame


func _init() -> void:
	await process_frame
	var state = root.get_node("GameState")
	var bus = root.get_node("EventBus")
	var settings = root.get_node("Settings")
	state.selected_character_scene = load("res://scenes/player_optimus.tscn")
	change_scene_to_file("res://scenes/game.tscn")
	await create_timer(0.5).timeout
	var game: Node = current_scene
	var menu = game.get_node("PauseMenu")
	print("1) la acción 'pause' existe=%s ; menú oculto al empezar=%s (esperado true, true)" % [InputMap.has_action("pause"), not menu._root.visible])

	await _press_pause()
	print("2) Esc abre: visible=%s pausado=%s texto='%s' (esperado true, true)" % [menu._root.visible, paused, menu._info.text])
	await _press_pause()
	print("   Esc otra vez cierra: visible=%s pausado=%s (esperado false, false)" % [menu._root.visible, paused])

	menu._pause_button.pressed.emit()
	print("3) el botón abre: visible=%s pausado=%s (esperado true, true)" % [menu._root.visible, paused])
	menu._continue_button.pressed.emit()
	print("   'Continuar' cierra: visible=%s pausado=%s (esperado false, false)" % [menu._root.visible, paused])

	# 4) Con la tienda abierta (ya pausa el juego) no se abre, y el botón queda inerte
	bus.shop_opened.emit()
	await process_frame
	await _press_pause()
	print("4) con la tienda abierta: pausa visible=%s (esperado false) ; botón de pausa inerte=%s (esperado true)" % [menu._root.visible, not menu._pause_button.can_process()])
	game.get_node("Shop")._close()
	await process_frame

	# 5) Sin partida en curso no se abre
	state.run_active = false
	await _press_pause()
	print("5) sin partida en curso: visible=%s (esperado false)" % menu._root.visible)
	state.run_active = true

	# 6) Volumen: se aplica a los canales y se guarda
	await _press_pause()
	menu._music_slider.value = 50.0
	menu._sfx_slider.value = 0.0
	var music_bus: int = AudioServer.get_bus_index("Music")
	var sfx_bus: int = AudioServer.get_bus_index("SFX")
	print("6) música al 50%%: volumen del canal=%.1f dB (esperado ~-6.0) ; efectos a 0%%: %.1f dB (esperado -80.0)" % [AudioServer.get_bus_volume_db(music_bus), AudioServer.get_bus_volume_db(sfx_bus)])
	settings.save()
	settings.music_volume = 1.0
	settings.sfx_volume = 1.0
	settings._load()
	print("   tras guardar y recargar: música=%.2f efectos=%.2f (esperado 0.50, 0.00)" % [settings.music_volume, settings.sfx_volume])

	# 7) Salir al menú
	menu._exit_to_menu()
	await create_timer(0.5).timeout
	print("7) tras 'Salir al menú': escena=%s pausado=%s (esperado MainMenu, false)" % [current_scene.name, paused])
	# Se dejan las preferencias como estaban.
	settings.set_music_volume(1.0)
	settings.set_sfx_volume(1.0)
	settings.save()
	quit()
