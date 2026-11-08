# main_menu.gd
# Menú principal: título, vista previa animada de dos personajes y botones.
# SRP: solo navega (Jugar -> selección de personaje, Salir). No contiene lógica de juego.

class_name MainMenu
extends Control

const CHAR_SELECT_SCENE := "res://scenes/char_select.tscn"

@export var roster: CharacterRoster

@onready var _left: AnimatedSprite2D = $LeftSprite
@onready var _right: AnimatedSprite2D = $RightSprite
@onready var _play_button: Button = %PlayButton
@onready var _quit_button: Button = %QuitButton
@onready var _attack_timer: Timer = $AttackTimer


func _ready() -> void:
	GameState.reset()
	_play_button.pressed.connect(_on_play_pressed)
	_quit_button.pressed.connect(get_tree().quit)
	_play_button.grab_focus()

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


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(CHAR_SELECT_SCENE)
