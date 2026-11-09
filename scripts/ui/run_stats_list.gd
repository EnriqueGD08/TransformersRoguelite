# run_stats_list.gd
# Lista animada con el resumen de la partida (victoria y derrota la comparten).
# SRP: construir las filas del resumen, mostrarlas una tras otra y contar las cifras desde 0.
#      No decide cuándo se muestra ni qué pantalla la contiene.
# DIP: lee los datos de GameState; no conoce VictoryScreen ni DefeatScreen.

class_name RunStatsList
extends VBoxContainer


## Hace salir las filas una tras otra. Cada fila tiene su propia animación, así el conteo
## de una no hace esperar a la siguiente.
## wave_label: texto de la primera fila ("Oleadas superadas" / "Oleada alcanzada").
func play(wave_label: String, row_delay: float, count_duration: float) -> void:
	for child in get_children():
		child.queue_free()
	var rows: Array = _rows(wave_label)
	for i in rows.size():
		var row: Array = rows[i]
		var line := HBoxContainer.new()
		line.modulate.a = 0.0
		var name_label := Label.new()
		name_label.text = row[0]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(name_label)
		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_color_override("font_color", Color("ffe9a0"))
		value_label.text = _format(row[2], 0.0 if row[2] != "text" else row[1])
		line.add_child(value_label)
		add_child(line)

		var tween: Tween = create_tween()
		tween.tween_interval(0.6 + float(i) * row_delay)
		tween.tween_property(line, "modulate:a", 1.0, 0.15)
		if row[2] != "text":
			var kind: String = row[2]
			tween.parallel().tween_method(func(v: float) -> void: value_label.text = _format(kind, v), 0.0, float(row[1]), count_duration)


## [nombre, valor final, tipo de formato].
func _rows(wave_label: String) -> Array:
	return [
		[wave_label, "%d / %d" % [GameState.current_wave, GameState.total_waves], "text"],
		["Tiempo", GameState.run_time, "time"],
		["Enemigos derrotados", GameState.enemies_killed, "int"],
		["Jefes derrotados", GameState.bosses_defeated, "int"],
		["Daño causado", GameState.damage_dealt, "int"],
		["Daño recibido", GameState.damage_received, "int"],
		["Transformaciones", GameState.times_transformed, "int"],
		["Energon obtenido", GameState.energon_earned, "int"],
		["Mejoras compradas", GameState.shop_purchases, "int"],
		["Habilidades desbloqueadas", GameState.unlocked_skill_ids.size(), "int"],
	]


func _format(kind: String, value: Variant) -> String:
	match kind:
		"time":
			var total: int = int(value)
			return "%d:%02d" % [total / 60, total % 60]
		"int":
			return _thousands(int(round(float(value))))
	return str(value)


## 1234567 -> "1.234.567" (separador español).
func _thousands(number: int) -> String:
	var digits: String = str(number)
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += "."
		out += digits[i]
	return out
