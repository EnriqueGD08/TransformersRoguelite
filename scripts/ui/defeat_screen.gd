# defeat_screen.gd
# Pantalla de derrota: aparece cuando el jugador cae.
# SRP: muestra al personaje caído, el resumen de la partida y los botones de salida.
#      No calcula estadísticas (las lleva GameState) ni gestiona oleadas.
# DIP: escucha EventBus.game_over; el personaje se le inyecta con setup().
# Mientras está abierta el juego se pausa; la pantalla sigue animándose (PROCESS_MODE_ALWAYS).

class_name DefeatScreen
extends CanvasLayer

const CHARACTER_SELECT_SCENE := "res://scenes/char_select.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"

## Segundos entre la caída del jugador y la aparición de la pantalla
## (deja ver la animación de caída en la partida).
@export_range(0.0, 4.0, 0.1) var show_delay: float = 1.4

## Segundos entre una fila del resumen y la siguiente.
@export_range(0.05, 1.0, 0.05) var row_delay: float = 0.25

## Segundos que tarda en contar cada cifra desde 0.
@export_range(0.2, 3.0, 0.1) var count_duration: float = 0.9

@onready var _root: Control = $Root
@onready var _fallen_area: Control = %FallenArea
@onready var _glow: Sunburst = %Glow
@onready var _fallen: AnimatedSprite2D = %Fallen
@onready var _embers: CPUParticles2D = %Embers
@onready var _character_label: Label = %CharacterName
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _stats_list: RunStatsList = %StatsList
@onready var _retry_button: Button = %RetryButton
@onready var _select_button: Button = %SelectButton
@onready var _menu_button: Button = %MenuButton

var _frames: SpriteFrames = null
var _character_name: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.hide()
	EventBus.game_over.connect(_on_game_over)
	_retry_button.pressed.connect(_on_retry_pressed)
	_select_button.pressed.connect(_on_select_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_fallen_area.resized.connect(_place_fallen)
	if TouchUI.is_touch_device():
		for button in [_retry_button, _select_button, _menu_button]:
			button.custom_minimum_size.y = 64.0


## Inyección del personaje jugado: de él salen las imágenes del caído.
func setup(player: BaseCharacter) -> void:
	_frames = player.get_skin_frames()
	_character_name = player.stats.character_name if player.stats != null else ""

# ── Mostrar ───────────────────────────────────────────────────────────────────

func _on_game_over() -> void:
	# El temporizador ignora la pausa para que cuente aunque algo más pause el juego.
	await get_tree().create_timer(show_delay, true).timeout
	_show()


func _show() -> void:
	get_tree().paused = true
	_root.show()
	_fill_texts()
	_prepare_fallen()
	await get_tree().process_frame
	_place_fallen()
	_animate_title()
	_stats_list.play("Oleada alcanzada", row_delay, count_duration)
	_embers.restart()
	_retry_button.grab_focus()


func _fill_texts() -> void:
	_character_label.text = _character_name.to_upper()
	_title.text = "DERROTA"
	_subtitle.text = "Has caído en la oleada %d de %d" % [GameState.current_wave, GameState.total_waves]


## El personaje cae (animación "death") y se queda en el suelo, apagado.
func _prepare_fallen() -> void:
	if _frames == null:
		return
	_fallen.sprite_frames = _frames
	CharacterInfo.fit_preview(_fallen, _frames, 3.2)
	_fallen.flip_h = false
	_fallen.play(&"death" if _frames.has_animation("death") else &"idle")


## Centra el resplandor, el caído y las brasas en el hueco de la izquierda.
func _place_fallen() -> void:
	var center: Vector2 = _fallen_area.global_position + _fallen_area.size * Vector2(0.5, 0.46)
	_glow.global_position = center
	_fallen.global_position = center + Vector2(0, 20)
	_embers.global_position = center + Vector2(0, 150)


func _animate_title() -> void:
	_title.pivot_offset = _title.size * 0.5
	_title.scale = Vector2(1.5, 1.5)
	_title.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_title, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_title, "modulate:a", 1.0, 0.5)

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
