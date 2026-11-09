# main_menu.gd
# Menú principal: título, vista previa animada de dos personajes y botones.
# SRP: solo navega (Jugar -> selección de personaje, Salir). No contiene lógica de juego.

class_name MainMenu
extends Control

const CHAR_SELECT_SCENE := "res://scenes/char_select.tscn"
const GAME_SCENE := "res://scenes/game.tscn"

@export var roster: CharacterRoster

@onready var _left: AnimatedSprite2D = $LeftSprite
@onready var _right: AnimatedSprite2D = $RightSprite
@onready var _continue_button: Button = %ContinueButton
@onready var _continue_info: Label = %ContinueInfo
@onready var _play_button: Button = %PlayButton
@onready var _quit_button: Button = %QuitButton
@onready var _attack_timer: Timer = $AttackTimer


func _ready() -> void:
	GameState.reset()
	_continue_button.pressed.connect(_on_continue_pressed)
	_play_button.pressed.connect(_on_play_pressed)
	_quit_button.pressed.connect(get_tree().quit)
	_refresh_continue()
	EventBus.play_music.emit("menu")

	# Dos rivales frente a frente: el primero (Optimus) y el de la mitad de la lista (Megatron).
	_setup_sprite(_left, 0, false)
	_setup_sprite(_right, 2, true)
	_attack_timer.timeout.connect(_on_attack_timer)
	_attack_timer.start()


func _setup_sprite(sprite: AnimatedSprite2D, entry_index: int, flipped: bool) -> void:
	if roster == null or entry_index >= roster.entries.size():
		return
	var frames: SpriteFrames = roster.entries[entry_index].load_skin("g1")
	if frames == null:
		return
	sprite.sprite_frames = frames
	CharacterInfo.fit_preview(sprite, sprite.sprite_frames, 3.0)
	sprite.flip_h = flipped
	sprite.play("idle")
	sprite.animation_finished.connect(func(): sprite.play("idle"))


## De vez en cuando atacan (solo es decoración).
func _on_attack_timer() -> void:
	for sprite in [_left, _right]:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("attack"):
			sprite.play("attack")


## Muestra "Continuar" (con el personaje y la oleada) solo si hay una partida guardada válida.
func _refresh_continue() -> void:
	var snapshot: Dictionary = SaveManager.read_run()
	var info: CharacterInfo = _find_character(str(snapshot.get("character_id", "")))
	var has_save: bool = info != null
	_continue_button.visible = has_save
	_continue_info.visible = has_save
	_play_button.text = "NUEVA PARTIDA" if has_save else "JUGAR"
	if has_save:
		_continue_info.text = "%s  ·  oleada %d / %d" % [
			info.display_name, int(snapshot.get("next_wave_index", 0)) + 1, int(snapshot.get("total_waves", 0))]
		_continue_button.grab_focus()
	else:
		_play_button.grab_focus()


func _find_character(character_id: String) -> CharacterInfo:
	if roster == null or character_id.is_empty():
		return null
	for entry in roster.entries:
		if entry.id == character_id:
			return entry
	return null


func _on_continue_pressed() -> void:
	var snapshot: Dictionary = SaveManager.read_run()
	var info: CharacterInfo = _find_character(str(snapshot.get("character_id", "")))
	if info == null:
		# El guardado ya no es válido (por ejemplo, un personaje que no existe): se descarta.
		SaveManager.delete_run()
		_refresh_continue()
		return
	info.select_for_run(str(snapshot.get("skin_id", "g1")))
	GameState.pending_run = snapshot
	get_tree().change_scene_to_file(GAME_SCENE)


## Con una partida guardada, empezar otra la borraría: se pide confirmación.
func _on_play_pressed() -> void:
	if not SaveManager.has_run():
		get_tree().change_scene_to_file(CHAR_SELECT_SCENE)
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = "Nueva partida"
	dialog.dialog_text = "Ya tienes una partida guardada.\nSi empiezas una nueva, se perderá.\n\n¿Quieres empezar de nuevo?"
	dialog.ok_button_text = "Empezar de nuevo"
	dialog.cancel_button_text = "Cancelar"
	dialog.confirmed.connect(func() -> void:
		SaveManager.delete_run()
		get_tree().change_scene_to_file(CHAR_SELECT_SCENE))
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()
