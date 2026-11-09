# touch_charselect_test.gd
# Herramienta de desarrollo: prueba la selección de personaje en modo táctil.
# Comprueba el tamaño táctil de los botones y que tocar cambia skin/personaje y comienza.
# Necesita ventana:
#   godot --path . --resolution 1280x720 --fixed-fps 30 --write-movie /tmp/cs/f.png \
#         -s tools/touch_charselect_test.gd -- --touch-controls
extends SceneTree


func _tap(pos: Vector2, check: Callable) -> void:
	for attempt in 4:
		for pressed in [true, false]:
			var e := InputEventScreenTouch.new()
			e.position = pos
			e.pressed = pressed
			Input.parse_input_event(e)
			await process_frame
			await process_frame
		if check.call():
			return


func _init() -> void:
	await process_frame
	change_scene_to_file("res://scenes/char_select.tscn")
	await create_timer(0.6).timeout
	var cs: Node = current_scene
	var ok := true
	for b in cs._skin_buttons.values() + [cs._transform_button, cs._back_button, cs._start_button]:
		var h: float = b.size.y
		print("alto ", b.text, " = ", h)
		ok = ok and h >= 60.0
	var center := func(c: Control) -> Vector2: return c.get_global_rect().get_center()
	await _tap(center.call(cs._skin_buttons["prime"]), func(): return cs._skin_id == "prime")
	print("skin tras tocar Prime: ", cs._skin_id)
	ok = ok and cs._skin_id == "prime"
	await _tap(center.call(cs._roster_buttons[2]), func(): return cs._index == 2)
	print("personaje tras tocar el 3.º: ", cs._index)
	ok = ok and cs._index == 2
	await create_timer(0.5).timeout
	await _tap(center.call(cs._start_button), func(): return current_scene != cs)
	await create_timer(0.5).timeout
	print("escena tras COMENZAR: ", current_scene.scene_file_path)
	ok = ok and current_scene.scene_file_path.ends_with("game.tscn")
	print("RESULTADO: ", "OK" if ok else "FALLO")
	quit()
