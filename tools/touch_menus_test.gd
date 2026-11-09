# touch_menus_test.gd
# Herramienta de desarrollo: prueba del árbol de habilidades y la tienda en modo táctil.
# Con toques simulados comprueba que tocar selecciona, que arrastrar desplaza el contenido
# sin seleccionar ni comprar nada, y que los botones tienen el tamaño táctil. Imprime los
# resultados. Necesita ventana (no funciona con --headless):
#   godot --path . --resolution 1280x720 --fixed-fps 30 --write-movie /tmp/tm/f.png \
#         -s tools/touch_menus_test.gd -- --touch-controls
extends SceneTree


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


## Un toque: pulsar y soltar con un par de imágenes de por medio (Godot reparte los eventos por
## tandas). Si el ratón real del ordenador se cuela y anula el toque, se reintenta (en un móvil
## no hay ratón: solo afecta a la prueba). 'check' dice si el toque surtió efecto.
func _tap(pos: Vector2, check: Callable = Callable()) -> void:
	for attempt in 4:
		_touch(0, pos, true)
		await process_frame
		await process_frame
		_touch(0, pos, false)
		await process_frame
		await process_frame
		if not check.is_valid() or check.call():
			return


## Arrastra un dedo desde 'from' hasta 'to' en varios pasos y lo suelta.
func _swipe(from: Vector2, to: Vector2) -> void:
	_touch(0, from, true)
	await process_frame
	await process_frame
	var last := from
	for step in range(1, 13):
		var p: Vector2 = from.lerp(to, float(step) / 12.0)
		_drag(0, p, last)
		last = p
		await process_frame
	_touch(0, to, false)
	await process_frame
	await process_frame


func _init() -> void:
	await process_frame
	var state = root.get_node("GameState")
	var bus = root.get_node("EventBus")
	state.selected_character_scene = load("res://scenes/player_optimus.tscn")
	change_scene_to_file("res://scenes/game.tscn")
	await create_timer(0.5).timeout
	var game: Node = current_scene
	# Las pruebas con ventana arrancan sin foco: sin esto la pausa automática se abriría sola.
	game.get_node("PauseMenu").pause_on_focus_loss = false
	game.get_node("PauseMenu")._close()
	state.add_skill_points(5)
	state.add_energon(600)

	# ── Árbol de habilidades ─────────────────────────────────────────────────
	var tree_ui = game.get_node("SkillTree")
	bus.skill_tree_opened.emit()
	await create_timer(0.5).timeout
	var node_button: Button = null
	for id in tree_ui._buttons:
		node_button = tree_ui._buttons[id]
		break
	var area: Vector2 = tree_ui._scroll.size
	var content: Vector2 = tree_ui._tree_area.size
	print("1) árbol: nodo de %.0f px (esperado 86) ; zona visible %.0fx%.0f ; contenido %.0fx%.0f ; se puede desplazar=%s (esperado true)" % [
		node_button.size.x, area.x, area.y, content.x, content.y, content.x > area.x + 1.0 or content.y > area.y + 1.0])
	print("   botón de la ficha: desbloquear %.0f px, continuar %.0f px de alto (esperado 68)" % [tree_ui._unlock_button.custom_minimum_size.y, tree_ui._continue_button.custom_minimum_size.y])

	# Tocar un nodo concreto lo selecciona
	var target_id := ""
	for id in tree_ui._buttons:
		if id != tree_ui._selected_id:
			var b: Button = tree_ui._buttons[id]
			if tree_ui._scroll.get_global_rect().encloses(b.get_global_rect()):
				target_id = id
				break
	var target: Button = tree_ui._buttons[target_id]
	await _tap(target.get_global_rect().get_center(), func() -> bool: return tree_ui._selected_id == target_id)
	print("2) tocar el nodo '%s': seleccionado=%s (esperado true)" % [target_id, tree_ui._selected_id == target_id])

	# Arrastrar DESDE un nodo desplaza y no cambia la selección
	var before_sel: String = tree_ui._selected_id
	var before_scroll := Vector2(tree_ui._scroll.scroll_horizontal, tree_ui._scroll.scroll_vertical)
	var points_before: int = state.available_skill_points
	var start: Vector2 = target.get_global_rect().get_center()
	await _swipe(start, start + Vector2(-120, -150))
	var after_scroll := Vector2(tree_ui._scroll.scroll_horizontal, tree_ui._scroll.scroll_vertical)
	print("3) arrastrar desde un nodo: el árbol se desplazó %s ; selección sin cambiar=%s ; puntos sin gastar=%s (esperado desplazamiento > 0, true, true)" % [
		after_scroll - before_scroll, tree_ui._selected_id == before_sel, state.available_skill_points == points_before])

	# Arrastrar desde un hueco también desplaza
	var empty: Vector2 = tree_ui._scroll.get_global_rect().position + Vector2(8, 8)
	var s2 := Vector2(tree_ui._scroll.scroll_horizontal, tree_ui._scroll.scroll_vertical)
	await _swipe(empty + Vector2(200, 200), empty + Vector2(100, 120))
	var e2 := Vector2(tree_ui._scroll.scroll_horizontal, tree_ui._scroll.scroll_vertical)
	print("   arrastrar desde un hueco: se desplazó %s (esperado distinto de 0)" % [e2 - s2])
	tree_ui._close()
	await process_frame

	# ── Tienda ────────────────────────────────────────────────────────────────
	var shop_ui = game.get_node("Shop")
	bus.shop_opened.emit()
	await create_timer(0.5).timeout
	var card: Button = shop_ui._cards.values()[0]
	print("4) tienda: tarjeta de %.0fx%.0f px (esperado %.0fx%.0f) ; botón de comprar %.0f px de alto (esperado 68)" % [
		card.size.x, card.size.y, 150.0 * 1.3, 116.0 * 1.3, shop_ui._buy_button.custom_minimum_size.y])
	var visible_cards := 0
	for c in shop_ui._cards.values():
		if shop_ui._scroll.get_global_rect().encloses(c.get_global_rect()):
			visible_cards += 1
	print("   tarjetas completamente visibles: %d de %d ; contenido %.0f px de alto en una zona de %.0f (se desplaza si es mayor)" % [
		visible_cards, shop_ui._cards.size(), shop_ui._grid.size.y, shop_ui._scroll.size.y])
	var second_id: String = shop_ui._items[1].id
	await _tap(shop_ui._cards[second_id].get_global_rect().get_center(), func() -> bool: return shop_ui._selected_id == second_id)
	print("5) tocar una tarjeta: seleccionada=%s (esperado true)" % (shop_ui._selected_id == second_id))
	var energon_before: int = state.current_energon
	var sel_before: String = shop_ui._selected_id
	var c0: Vector2 = shop_ui._cards[shop_ui._items[0].id].get_global_rect().get_center()
	var scroll_before: int = shop_ui._scroll.scroll_vertical
	await _swipe(c0, c0 + Vector2(0, -160))
	print("6) arrastrar desde una tarjeta: scroll %d -> %d ; selección sin cambiar=%s ; energon sin gastar=%s (esperado scroll mayor si hay contenido de sobra, true, true)" % [
		scroll_before, shop_ui._scroll.scroll_vertical, shop_ui._selected_id == sel_before, state.current_energon == energon_before])
	quit()
