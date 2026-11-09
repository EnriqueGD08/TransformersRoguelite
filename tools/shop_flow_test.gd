# shop_flow_test.gd
# Herramienta de desarrollo: prueba del flujo de la tienda. Termina la oleada 1, pasa por el
# árbol de habilidades y la tienda, compra (con y sin saldo, hasta agotar un objeto) y comprueba
# que empieza la oleada 2. Imprime los resultados: no hay "OK" automático, se leen en la salida.
# Uso: godot --headless --path . -s tools/shop_flow_test.gd
extends SceneTree


func _init():
	await process_frame
	var bus = root.get_node("EventBus")
	var gs = root.get_node("GameState")
	gs.selected_character_scene = load("res://scenes/player_optimus.tscn")
	change_scene_to_file("res://scenes/game.tscn")
	await create_timer(0.4).timeout
	var game = current_scene
	var player
	for c in game.get_node("World").get_children():
		if c.has_method("request_transform"): player = c
	var wm = game.get_node("Systems/WaveManager")
	var shop = game.get_node("Systems/ShopManager")
	var shop_ui = game.get_node("Shop")
	var tree_ui = game.get_node("SkillTree")
	var started := [0]
	bus.wave_started.connect(func(n, _t): started[0] = n)
	print("catálogo: %d objetos" % shop.get_items().size())
	# 1) Se acaba la oleada 1 -> árbol -> tienda -> oleada 2
	wm._complete_wave()
	await process_frame
	print("1) árbol visible=%s tienda visible=%s pausado=%s" % [tree_ui._root.visible, shop_ui._root.visible, paused])
	tree_ui._close()
	await process_frame
	print("2) árbol visible=%s tienda visible=%s pausado=%s" % [tree_ui._root.visible, shop_ui._root.visible, paused])
	# 3) Compras
	var hp0: float = player.get_max_hp()
	var e0: int = gs.current_energon
	print("3) sin saldo: comprar hp -> %s (esperado false); energon %d" % [shop.buy("hp"), gs.current_energon])
	gs.add_energon(500)
	var item = shop.get_items()[0]
	print("   precio hp: %d, luego %d" % [shop.get_price(item), (func(): shop.buy("hp"); return shop.get_price(item)).call()])
	print("   vida máx %d -> %d (esperado +30)" % [hp0, player.get_max_hp()])
	print("   energon tras 1ª compra: %d (500+%d-40)" % [gs.current_energon, e0])
	print("   comprar lifesteal -> %s ; otra vez -> %s (esperado true, false)" % [shop.buy("lifesteal"), shop.buy("lifesteal")])
	print("   lifesteal agotado=%s" % shop.is_sold_out(shop.get_items()[8]))
	# 4) Agotar un objeto de stats
	var n := 0
	gs.add_energon(5000)
	while shop.buy("speed"): n += 1
	print("   speed comprado %d veces (máx 6)" % n)
	# 5) Continuar -> siguiente oleada
	shop_ui._close()
	await create_timer(0.3).timeout
	print("4) tienda visible=%s pausado=%s oleada actual=%d (esperado 2)" % [shop_ui._root.visible, paused, started[0]])
	quit()
