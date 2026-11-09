# audio_test.gd
# Herramienta de desarrollo: prueba del audio. Comprueba que existen todos los sonidos que
# pide el juego, que el gestor reacciona a las señales (golpe al jugador, clic de botón...),
# que limita las repeticiones, que la música hace bucle (salvo victoria y derrota) y que
# sigue sonando con el juego pausado. Imprime los resultados.
# Uso: godot --headless --path . -s tools/audio_test.gd
extends SceneTree


func _playing_streams(manager: Node) -> Array:
	var out: Array = []
	for child in manager.get_children():
		if child is AudioStreamPlayer and child.playing and child.stream != null:
			out.append(child)
	return out


func _init() -> void:
	await process_frame
	var audio: Node = root.get_node("AudioManager")
	var bus: Node = root.get_node("EventBus")

	# 1) Todos los sonidos que el juego pide por identificador
	var ids: Array = []
	for path in _gd_files("res://scripts") + _gd_files("res://autoloads"):
		var text: String = FileAccess.get_file_as_string(path)
		var rx := RegEx.create_from_string("play_sfx\\.emit\\(\"([a-z_0-9]+)\"")
		for m in rx.search_all(text):
			ids.append(m.get_string(1))
	for w in ["axe_optimus", "fusion_cannon", "null_ray", "photon_pistols", "shockwave_cannon", "stingers_bee", "twin_blades"]:
		ids.append(w + "_fire")
	for e in ["boss_brawl", "boss_devastator", "boss_galvatron", "boss_soundwave", "constructicon", "seeker", "vehicon"]:
		ids.append(e + "_attack")
	for extra in ["enemy_hit", "player_hit", "ui_click", "skill_unlock", "wave_start", "wave_complete"]:
		ids.append(extra)
	var missing: Array = []
	for id in ids:
		if audio._load_stream(audio.SFX_BASE_PATH + id) == null and not missing.has(id):
			missing.append(id)
	print("1) sonidos pedidos por el juego: %d ; sin archivo: %s (esperado [])" % [ids.size(), missing])
	var tracks_missing: Array = []
	for t in ["menu", "battle_1", "battle_2", "battle_3", "battle_4", "battle_boss", "victory", "game_over"]:
		if audio._load_stream(audio.MUSIC_BASE_PATH + t) == null:
			tracks_missing.append(t)
	print("   pistas de música sin archivo: %s (esperado [])" % [tracks_missing])

	# 2) Un sonido suena y la repetición inmediata se limita
	audio.play_sfx("shop_buy")
	var first: int = _playing_streams(audio).size()
	audio.play_sfx("shop_buy")
	print("2) shop_buy: suena=%s ; segunda llamada inmediata ignorada=%s (esperado true, true)" % [first == 1, _playing_streams(audio).size() == 1])

	# 3) Señales: daño al jugador y clic de botón
	await create_timer(0.1).timeout
	bus.player_hp_changed.emit(100.0, 100.0)
	bus.player_hp_changed.emit(80.0, 100.0)
	var hit_stream: AudioStream = audio._load_stream(audio.SFX_BASE_PATH + "player_hit")
	var heard := false
	for p in _playing_streams(audio):
		if p.stream == hit_stream:
			heard = true
	print("3) bajar la vida del jugador suena player_hit: %s (esperado true)" % heard)
	var button := Button.new()
	root.add_child(button)
	button.pressed.emit()
	var click_stream: AudioStream = audio._load_stream(audio.SFX_BASE_PATH + "ui_click")
	heard = false
	for p in _playing_streams(audio):
		if p.stream == click_stream:
			heard = true
	print("   pulsar un botón suena ui_click: %s (esperado true)" % heard)
	bus.wave_started.emit(3, 20)
	var wave_stream: AudioStream = audio._load_stream(audio.SFX_BASE_PATH + "wave_start")
	heard = false
	for p in _playing_streams(audio):
		if p.stream == wave_stream:
			heard = true
	print("   empezar oleada suena wave_start: %s (esperado true)" % heard)

	# 4) Música: bucle, no bucle y pausa
	audio.play_music("battle_1")
	var music: AudioStream = audio._load_stream(audio.MUSIC_BASE_PATH + "battle_1")
	print("4) battle_1: bucle=%s, fin del bucle=%d muestras = %.1f s (esperado FORWARD y ~30,5 s)" % [music.loop_mode == AudioStreamWAV.LOOP_FORWARD, music.loop_end, music.loop_end / float(music.mix_rate)])
	audio.play_music("victory")
	var victory: AudioStream = audio._load_stream(audio.MUSIC_BASE_PATH + "victory")
	print("   victory: bucle desactivado=%s (esperado true)" % [victory.loop_mode == AudioStreamWAV.LOOP_DISABLED])
	paused = true
	audio.play_sfx("revive")
	await create_timer(0.1, true).timeout
	var revive: AudioStream = audio._load_stream(audio.SFX_BASE_PATH + "revive")
	heard = false
	for p in _playing_streams(audio):
		if p.stream == revive:
			heard = true
	print("   con el juego pausado sigue sonando: %s (esperado true)" % heard)
	quit()


func _gd_files(path: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(path)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(path + "/" + f)
	for sub in d.get_directories():
		out.append_array(_gd_files(path + "/" + sub))
	return out
