# char_select.gd
# Pantalla de selección de personaje y skin.
# SRP: muestra el roster y deja elegir personaje + skin; al comenzar guarda la elección
#      en GameState y cambia a la partida. No sabe nada de combate.
# DIP: toda la información sale de CharacterRoster/CharacterInfo (datos), no de clases concretas.
#
# Teclas: ← → cambian de personaje, ↑ ↓ cambian de skin, Enter comienza, Esc vuelve.

class_name CharacterSelect
extends Control

const GAME_SCENE := "res://scenes/game.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"

const SKIN_ORDER: Array[String] = ["g1", "prime", "bay"]
const SKIN_NAMES := {
	"g1": "Clásico (G1)",
	"prime": "Transformers Prime",
	"bay": "Película (Bay)",
}
const FACTION_COLORS := {
	"Autobot": Color("ff5a5a"),
	"Decepticon": Color("b681ff"),
}

@export var roster: CharacterRoster

# ── Nodos ─────────────────────────────────────────────────────────────────────

@onready var _stage: Control = %StageArea
@onready var _preview: AnimatedSprite2D = %PreviewSprite
@onready var _faction_label: Label = %FactionLabel
@onready var _name_label: Label = %NameLabel
@onready var _role_label: Label = %RoleLabel
@onready var _desc_label: Label = %DescLabel
@onready var _stats_grid: GridContainer = %StatsGrid
@onready var _weapon_title: Label = %WeaponTitle
@onready var _weapon_label: Label = %WeaponLabel
@onready var _transform_title: Label = %TransformTitle
@onready var _transform_label: Label = %TransformLabel
@onready var _skin_box: HBoxContainer = %SkinBox
@onready var _roster_row: HBoxContainer = %RosterRow
@onready var _transform_button: Button = %TransformButton
@onready var _back_button: Button = %BackButton
@onready var _start_button: Button = %StartButton
@onready var _demo_timer: Timer = $DemoTimer

# ── Estado ────────────────────────────────────────────────────────────────────

var _index: int = 0
var _skin_id: String = "g1"
var _show_transform: bool = false
var _roster_buttons: Array[Button] = []
var _skin_buttons: Dictionary = {}
var _stat_bars: Array[ProgressBar] = []
var _stat_values: Array[Label] = []
var _stat_max: Dictionary = {}

## Definición de las barras: [título, función que extrae el valor de CharacterStats].
const STAT_ROWS := [
	["Vida", "max_hp"],
	["Velocidad", "move_speed"],
	["Daño", "base_damage"],
	["Alcance", "attack_range"],
]

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	assert(roster != null and not roster.entries.is_empty(), "CharacterSelect: roster vacío")
	_compute_stat_maximums()
	_build_stat_rows()
	_build_roster_buttons()
	_build_skin_buttons()

	_back_button.pressed.connect(_go_back)
	_start_button.pressed.connect(_start_game)
	_transform_button.toggled.connect(_on_transform_toggled)
	_stage.resized.connect(_center_preview)
	_stage.draw.connect(_draw_stage)
	_preview.animation_finished.connect(_on_preview_animation_finished)
	_demo_timer.timeout.connect(_on_demo_timer)

	# Recupera la última elección si se vuelve a esta pantalla.
	var start_index: int = 0
	for i in roster.entries.size():
		if roster.entries[i].id == GameState.selected_character_id:
			start_index = i
	if GameState.selected_skin_id in SKIN_ORDER:
		_skin_id = GameState.selected_skin_id
	_select_character(start_index)
	_start_button.grab_focus()
	_center_preview.call_deferred()


func _input(event: InputEvent) -> void:
	# Se procesa antes que la navegación por foco de la interfaz.
	if event.is_action_pressed("ui_left"):
		_select_character(posmod(_index - 1, roster.entries.size()))
	elif event.is_action_pressed("ui_right"):
		_select_character(posmod(_index + 1, roster.entries.size()))
	elif event.is_action_pressed("ui_up"):
		_cycle_skin(-1)
	elif event.is_action_pressed("ui_down"):
		_cycle_skin(1)
	elif event.is_action_pressed("ui_cancel"):
		_go_back()
	else:
		return
	get_viewport().set_input_as_handled()

# ── Construcción de la interfaz ───────────────────────────────────────────────

func _compute_stat_maximums() -> void:
	for row in STAT_ROWS:
		var best: float = 1.0
		for info in roster.entries:
			best = maxf(best, float(info.stats.get(row[1])))
		_stat_max[row[1]] = best


func _build_stat_rows() -> void:
	for row in STAT_ROWS:
		var title := Label.new()
		title.text = row[0]
		title.custom_minimum_size = Vector2(100, 0)
		_stats_grid.add_child(title)

		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(240, 16)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.max_value = _stat_max[row[1]]
		_stats_grid.add_child(bar)
		_stat_bars.append(bar)

		var value := Label.new()
		value.custom_minimum_size = Vector2(56, 0)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_stats_grid.add_child(value)
		_stat_values.append(value)


func _build_roster_buttons() -> void:
	var group := ButtonGroup.new()
	for i in roster.entries.size():
		var info: CharacterInfo = roster.entries[i]
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(160, 138)
		button.text = info.display_name
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.add_theme_color_override("font_color", FACTION_COLORS[info.faction].lightened(0.2))
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		button.icon = _make_icon(info)
		button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if button.icon != null and button.icon.get_height() > 96 else CanvasItem.TEXTURE_FILTER_NEAREST
		button.pressed.connect(_select_character.bind(i))
		_roster_row.add_child(button)
		_roster_buttons.append(button)


## Recorte del primer fotograma de reposo para el icono del botón.
func _make_icon(info: CharacterInfo) -> Texture2D:
	var texture: Texture2D = info.get_icon_texture()
	if texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	# Mismo encuadre sea cual sea la resolución del arte.
	var size: Vector2 = atlas.atlas.get_size()
	atlas.region = Rect2(size.x * 24.0 / 144.0, size.y * 4.0 / 96.0, size.x * 96.0 / 144.0, size.y * 90.0 / 96.0)
	return atlas


func _build_skin_buttons() -> void:
	var group := ButtonGroup.new()
	for skin_id in SKIN_ORDER:
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.text = SKIN_NAMES[skin_id]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_skin.bind(skin_id))
		_skin_box.add_child(button)
		_skin_buttons[skin_id] = button

# ── Selección ─────────────────────────────────────────────────────────────────

func _select_character(index: int) -> void:
	_index = index
	var info: CharacterInfo = roster.entries[index]
	var color: Color = FACTION_COLORS[info.faction]

	# Se marca explícitamente cada botón: con set_pressed_no_signal el grupo no desmarca al resto.
	for i in _roster_buttons.size():
		_roster_buttons[i].set_pressed_no_signal(i == index)

	_faction_label.text = info.faction.to_upper()
	_faction_label.add_theme_color_override("font_color", color)
	_name_label.text = info.display_name.to_upper()
	_role_label.text = info.role
	_desc_label.text = info.description
	_weapon_title.text = "ARMA · " + info.weapon_name
	_weapon_label.text = info.weapon_description
	_transform_title.text = "TRANSFORMACIÓN · " + info.transform_name
	_transform_label.text = info.transform_description
	_transform_button.text = "Ver " + info.transform_name

	for i in STAT_ROWS.size():
		var value: float = float(info.stats.get(STAT_ROWS[i][1]))
		_stat_bars[i].value = value
		_stat_values[i].text = str(int(value))
		_stat_bars[i].add_theme_stylebox_override("fill", _fill_style(color))

	# Si la skin elegida no existe para este personaje se usa la primera disponible.
	var frames: Dictionary = info.get_skin_paths()
	if not frames.has(_skin_id) and not frames.is_empty():
		_skin_id = frames.keys()[0]
	for skin_id in _skin_buttons:
		_skin_buttons[skin_id].disabled = not frames.has(skin_id)

	_show_transform = false
	_transform_button.set_pressed_no_signal(false)
	_refresh_preview()
	_stage.queue_redraw()


func _select_skin(skin_id: String) -> void:
	_skin_id = skin_id
	_refresh_preview()


func _cycle_skin(step: int) -> void:
	var frames: Dictionary = roster.entries[_index].get_skin_paths()
	var i: int = SKIN_ORDER.find(_skin_id)
	for _n in SKIN_ORDER.size():
		i = posmod(i + step, SKIN_ORDER.size())
		if frames.has(SKIN_ORDER[i]):
			break
	_select_skin(SKIN_ORDER[i])


func _fill_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	return style

# ── Vista previa ──────────────────────────────────────────────────────────────

func _refresh_preview() -> void:
	var skin_frames: SpriteFrames = roster.entries[_index].load_skin(_skin_id)
	if skin_frames == null:
		return
	for skin_id in _skin_buttons:
		_skin_buttons[skin_id].set_pressed_no_signal(skin_id == _skin_id)
	_preview.sprite_frames = skin_frames
	CharacterInfo.fit_preview(_preview, skin_frames, 3.0)
	_preview.play(&"transform_idle" if _show_transform and skin_frames.has_animation("transform_idle") else &"idle")


func _center_preview() -> void:
	# El sprite se coloca en la parte baja del escenario, con los pies sobre la "plataforma".
	_preview.position = Vector2(_stage.size.x * 0.5, _stage.size.y * 0.5)


func _on_transform_toggled(pressed: bool) -> void:
	_show_transform = pressed
	var frames: SpriteFrames = _preview.sprite_frames
	if frames == null or not frames.has_animation("transform_activate"):
		return
	if pressed:
		_preview.play(&"transform_activate")
	else:
		_preview.play_backwards(&"transform_activate")


func _on_preview_animation_finished() -> void:
	var frames: SpriteFrames = _preview.sprite_frames
	if _show_transform and frames.has_animation("transform_idle"):
		_preview.play(&"transform_idle")
	else:
		_preview.play(&"idle")


## Cada pocos segundos hace una demostración de ataque.
func _on_demo_timer() -> void:
	var frames: SpriteFrames = _preview.sprite_frames
	if frames == null:
		return
	var anim: StringName = &"transform_attack" if _show_transform else &"attack"
	if frames.has_animation(anim):
		_preview.play(anim)


## Plataforma elíptica con resplandor del color de la facción.
func _draw_stage() -> void:
	var color: Color = FACTION_COLORS[roster.entries[_index].faction]
	# Los pies del sprite (escala 3) quedan unos 135 px bajo su posición.
	var center := Vector2(_stage.size.x * 0.5, _stage.size.y * 0.5 + 137.0)
	for i in 4:
		var r: float = 215.0 - i * 36.0
		_stage.draw_set_transform(center, 0.0, Vector2(1.0, 0.2))
		_stage.draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, 0.08 + i * 0.05))
	_stage.draw_set_transform(center, 0.0, Vector2(1.0, 0.2))
	_stage.draw_arc(Vector2.ZERO, 215.0, 0.0, TAU, 64, Color(color.r, color.g, color.b, 0.6), 3.0)
	_stage.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ── Acciones ──────────────────────────────────────────────────────────────────

func _start_game() -> void:
	roster.entries[_index].select_for_run(_skin_id)
	get_tree().change_scene_to_file(GAME_SCENE)


func _go_back() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
