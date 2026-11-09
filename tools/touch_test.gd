# touch_test.gd
# Herramienta de desarrollo: prueba de los controles táctiles con toques simulados.
# Mueve, apunta y ataca con los dos joysticks, transforma con el botón, usa dos dedos a la vez
# y comprueba que al pausar (tienda) se sueltan los joysticks. Imprime los resultados.
# Necesita ventana (no funciona con --headless: sin pantalla Godot no reparte los toques).
# Uso: godot --path . --resolution 1280x720 --fixed-fps 30 --write-movie /tmp/touch/f.png -s tools/touch_test.gd -- --touch-controls
extends SceneTree

var _frames_waited := 0


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


func _drag(index: int, pos: Vector2, from: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	e.relative = pos - from
	Input.parse_input_event(e)


func _wait(frames: int) -> void:
	for i in frames:
		await process_frame


func _init() -> void:
	await process_frame
	var state = root.get_node("GameState")
	state.selected_character_scene = load("res://scenes/player_megatron.tscn")
	change_scene_to_file("res://scenes/game.tscn")
	await create_timer(0.4).timeout
	var player: Node2D = null
	for c in current_scene.get_node("World").get_children():
		if c.has_method("request_transform"):
			player = c
	player.add_stat_modifier("max_hp", 50000.0)
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	var aim = root.get_node("AimInput")
	var controls: Node = current_scene.get_node("TouchControls")
	print("controles visibles: %s (esperado true con --touch-controls); botón de cambio de arma visible: %s (esperado false)" % [controls.visible, controls.get_node("%SwapButton").visible])

	# 1) Mover con el joystick izquierdo
	var x0: float = player.global_position.x
	_touch(0, Vector2(200, 500), true)
	await _wait(2)
	_drag(0, Vector2(320, 500), Vector2(200, 500))
	await _wait(25)
	print("1) mover: move_right=%s, jugador avanzó %.0f px (esperado >0)" % [Input.is_action_pressed("move_right"), player.global_position.x - x0])
	_touch(0, Vector2(320, 500), false)
	await _wait(3)
	print("   al soltar: move_right=%s (esperado false)" % Input.is_action_pressed("move_right"))

	# 2) Apuntar hacia arriba con el joystick derecho
	_touch(1, Vector2(1000, 500), true)
	await _wait(2)
	_drag(1, Vector2(1000, 380), Vector2(1000, 500))
	await _wait(30)
	var dir: Vector2 = aim.get_aim_direction(player, player.global_position)
	print("2) apuntar: attack=%s, touch_mode=%s, dirección %s (esperado ~(0,-1))" % [Input.is_action_pressed("attack"), aim.touch_mode, dir.snapped(Vector2(0.01, 0.01))])
	var box = get_first_node_in_group("projectiles")
	var best := 0.0
	for p in box.get_children():
		if "_direction" in p:
			best = maxf(best, -p._direction.y)
	print("   proyectiles en el aire: %d ; el que va más hacia arriba tiene componente y = -%.2f (esperado ~1)" % [box.get_child_count(), best])
	_touch(1, Vector2(1000, 380), false)
	await _wait(3)
	print("   al soltar: attack=%s (esperado false)" % Input.is_action_pressed("attack"))

	# 3) Botón de transformar
	_touch(2, Vector2(1165, 375), true)
	_touch(2, Vector2(1165, 375), false)
	await _wait(5)
	print("3) botón transformar: transformado=%s (esperado true)" % player.is_transformed())

	# 4) Dos dedos a la vez: mover y apuntar
	_touch(0, Vector2(200, 500), true)
	_touch(1, Vector2(1000, 500), true)
	await _wait(2)
	_drag(0, Vector2(200, 600), Vector2(200, 500))
	_drag(1, Vector2(1100, 500), Vector2(1000, 500))
	await _wait(10)
	print("4) dos dedos: move_down=%s attack=%s dirección %s (esperado true, true, ~(1,0))" % [Input.is_action_pressed("move_down"), Input.is_action_pressed("attack"), aim.get_aim_direction(player, player.global_position).snapped(Vector2(0.01, 0.01))])

	# 5) Se abre la tienda: el juego se pausa y los joysticks se sueltan
	root.get_node("EventBus").shop_opened.emit()
	await _wait(3)
	print("5) tienda abierta: pausado=%s move_down=%s attack=%s (esperado true, false, false)" % [paused, Input.is_action_pressed("move_down"), Input.is_action_pressed("attack")])
	quit()
