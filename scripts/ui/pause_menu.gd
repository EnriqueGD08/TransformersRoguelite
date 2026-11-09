# pause_menu.gd
# Menú de pausa: se abre con Esc (o P) o con el botón de la esquina.
# SRP: pausa y reanuda el juego, ajusta el volumen y sale al menú principal. No guarda la
#      partida (eso ocurre al empezar cada oleada) ni conoce las armas, enemigos o tienda.
# DIP: usa GameState (¿hay partida en curso?) y Settings (volúmenes); no toca otros sistemas.
# No se abre si el juego ya está en pausa por otra pantalla (tienda, árbol, victoria) ni si la
# partida terminó.

class_name PauseMenu
extends Node

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"

@onready var _pause_button: PauseButton = %PauseButton
@onready var _root: Control = %MenuRoot
@onready var _info: Label = %InfoLabel
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _music_value: Label = %MusicValue
@onready var _sfx_value: Label = %SfxValue
@onready var _continue_button: Button = %ContinueButton
@onready var _exit_button: Button = %ExitButton

var _is_open: bool = false


func _ready() -> void:
	# Este nodo debe recibir la tecla de pausa también con el juego pausado (para cerrarla).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.hide()
	_pause_button.pressed.connect(_open)
	_continue_button.pressed.connect(_close)
	_exit_button.pressed.connect(_confirm_exit)
	_music_slider.value = Settings.music_volume * 100.0
	_sfx_slider.value = Settings.sfx_volume * 100.0
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	# Al soltar el control se guarda, y el de efectos suena para oír el nivel.
	_music_slider.drag_ended.connect(func(_changed: bool) -> void: Settings.save())
	_sfx_slider.drag_ended.connect(func(_changed: bool) -> void:
		Settings.save()
		EventBus.play_sfx.emit("energon_pickup"))
	_update_value_labels()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if _is_open:
		_close()
	else:
		_open()
	get_viewport().set_input_as_handled()


## Si la ventana o la pestaña pierde el foco (cambias de aplicación), se pausa sola.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_open()


func _open() -> void:
	# Sin partida en curso, o con otra pantalla que ya pausó el juego, no se hace nada.
	if _is_open or not GameState.run_active or get_tree().paused:
		return
	_is_open = true
	get_tree().paused = true
	_info.text = _describe_run()
	_root.show()
	_continue_button.grab_focus()


func _close() -> void:
	if not _is_open:
		return
	_is_open = false
	Settings.save()
	_root.hide()
	get_tree().paused = false


func _describe_run() -> String:
	var stats: CharacterStats = GameState.selected_character_stats
	var who: String = stats.character_name if stats != null else ""
	var wave: String = "Oleada %d / %d" % [GameState.current_wave, GameState.total_waves]
	return "%s  ·  %s" % [who, wave] if who != "" else wave


func _on_music_changed(value: float) -> void:
	Settings.set_music_volume(value / 100.0)
	_update_value_labels()


func _on_sfx_changed(value: float) -> void:
	Settings.set_sfx_volume(value / 100.0)
	_update_value_labels()


func _update_value_labels() -> void:
	_music_value.text = "%d %%" % int(round(_music_slider.value))
	_sfx_value.text = "%d %%" % int(round(_sfx_slider.value))


## Salir pide confirmación: está justo debajo de "Continuar" y es fácil pulsarlo sin querer.
func _confirm_exit() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Salir al menú"
	dialog.dialog_text = "Saldrás al menú principal.\nTu partida se guardó al empezar esta oleada: podrás continuarla desde ahí.\n\n¿Quieres salir?"
	dialog.ok_button_text = "Salir al menú"
	dialog.cancel_button_text = "Cancelar"
	dialog.confirmed.connect(_exit_to_menu)
	dialog.canceled.connect(dialog.queue_free)
	# Debe funcionar con el juego en pausa.
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dialog)
	dialog.popup_centered()


func _exit_to_menu() -> void:
	Settings.save()
	get_tree().paused = false
	_is_open = false
	GameState.reset()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
