# victory_screen.gd
# Pantalla de victoria: aparece al derrotar la última oleada.
# SRP: muestra al personaje ganador, el resumen de la partida y los botones de salida.
#      No calcula estadísticas (las lleva GameState) ni gestiona oleadas.
# DIP: escucha EventBus.all_waves_completed; el personaje se le inyecta con setup().
# Mientras está abierta el juego se pausa; la pantalla sigue animándose (PROCESS_MODE_ALWAYS).

class_name VictoryScreen
extends CanvasLayer

const CHARACTER_SELECT_SCENE := "res://scenes/char_select.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"

## Segundos entre una fila del resumen y la siguiente.
@export_range(0.05, 1.0, 0.05) var row_delay: float = 0.3

## Segundos que tarda en contar cada cifra desde 0.
@export_range(0.2, 3.0, 0.1) var count_duration: float = 1.0

## Segundos después de la fanfarria en que empieza la música tranquila del menú.
@export_range(1.0, 20.0, 0.5) var calm_music_delay: float = 7.0

## Cada cuántos segundos el ganador hace su ataque de celebración.
@export_range(1.0, 10.0, 0.5) var celebrate_every: float = 3.0

@onready var _root: Control = $Root
@onready var _winner_area: Control = %WinnerArea
@onready var _sunburst: Sunburst = %Sunburst
@onready var _winner: AnimatedSprite2D = %Winner
@onready var _burst: CPUParticles2D = %Burst
@onready var _confetti: CPUParticles2D = %Confetti
@onready var _character_label: Label = %CharacterName
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _stats_list: VBoxContainer = %StatsList
@onready var _retry_button: Button = %RetryButton
@onready var _select_button: Button = %SelectButton
@onready var _menu_button: Button = %MenuButton
@onready var _celebrate_timer: Timer = %CelebrateTimer
@onready var _calm_music_timer: Timer = %CalmMusicTimer

var _frames: SpriteFrames = null
var _character_name: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.hide()
	EventBus.all_waves_completed.connect(_show)
	_retry_button.pressed.connect(_on_retry_pressed)
	_select_button.pressed.connect(_on_select_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_celebrate_timer.timeout.connect(_celebrate)
	_calm_music_timer.timeout.connect(func() -> void: EventBus.play_music.emit("menu"))
	_winner.animation_finished.connect(_on_winner_animation_finished)
	_winner_area.resized.connect(_place_winner)


## Inyección del personaje jugado: de él salen las imágenes del ganador.
func setup(player: BaseCharacter) -> void:
	_frames = player.get_skin_frames()
	_character_name = player.stats.character_name if player.stats != null else ""

# ── Mostrar ───────────────────────────────────────────────────────────────────

func _show() -> void:
	get_tree().paused = true
	_root.show()
	_fill_texts()
	_prepare_winner()
	await get_tree().process_frame
	_place_winner()
	_prepare_particles()
	_animate_title()
	_animate_stats()
	_celebrate_timer.start(celebrate_every)
	_calm_music_timer.start(calm_music_delay)
	_burst.restart()
	_retry_button.grab_focus()


func _fill_texts() -> void:
	_character_label.text = _character_name.to_upper()
	_title.text = "¡VICTORIA!"
	if GameState.last_boss_name != "":
		_subtitle.text = "Has derrotado a %s" % GameState.last_boss_name
	else:
		_subtitle.text = "¡Has sobrevivido a todas las oleadas!"


func _prepare_winner() -> void:
	if _frames == null:
		return
	_winner.sprite_frames = _frames
	CharacterInfo.fit_preview(_winner, _frames, 3.2)
	_winner.flip_h = false
	_winner.play(&"idle")


## Centra el sol, el ganador y el estallido en el hueco de la izquierda.
func _place_winner() -> void:
	var center: Vector2 = _winner_area.global_position + _winner_area.size * Vector2(0.5, 0.46)
	_sunburst.global_position = center
	_winner.global_position = center + Vector2(0, 20)
	_burst.global_position = center


func _prepare_particles() -> void:
	var width: float = _root.size.x
	_confetti.position = Vector2(width * 0.5, -20.0)
	_confetti.emission_rect_extents = Vector2(width * 0.5, 2.0)
	_confetti.restart()

# ── Animaciones ───────────────────────────────────────────────────────────────

func _animate_title() -> void:
	_title.pivot_offset = _title.size * 0.5
	_title.scale = Vector2(0.4, 0.4)
	_title.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_title, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_title, "modulate:a", 1.0, 0.3)


## Filas del resumen: salen una tras otra y las cifras cuentan desde 0 (cada fila tiene su
## propia animación, así el conteo de una no hace esperar a la siguiente).
func _animate_stats() -> void:
	for child in _stats_list.get_children():
		child.queue_free()
	var rows: Array = _rows()
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
		_stats_list.add_child(line)

		var tween: Tween = create_tween()
		tween.tween_interval(0.6 + float(i) * row_delay)
		tween.tween_property(line, "modulate:a", 1.0, 0.15)
		if row[2] != "text":
			var kind: String = row[2]
			tween.parallel().tween_method(func(v: float) -> void: value_label.text = _format(kind, v), 0.0, float(row[1]), count_duration)


## [nombre, valor final, tipo de formato].
func _rows() -> Array:
	return [
		["Oleadas superadas", "%d / %d" % [GameState.current_wave, GameState.total_waves], "text"],
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


## Cada pocos segundos el ganador hace su ataque; después vuelve a su reposo.
func _celebrate() -> void:
	if _frames != null and _frames.has_animation("attack"):
		_winner.play(&"attack")


func _on_winner_animation_finished() -> void:
	if _winner.animation != &"idle":
		_winner.play(&"idle")

# ── Botones ───────────────────────────────────────────────────────────────────

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_select_pressed() -> void:
	get_tree().paused = false
	GameState.reset()
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE)


func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameState.reset()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
