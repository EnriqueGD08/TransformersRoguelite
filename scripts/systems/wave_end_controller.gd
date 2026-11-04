# wave_end_controller.gd
# Pantalla provisional de fin de oleada.
# SRP: mostrar un panel al terminar una oleada y avisar cuando el jugador continúa.
# DIP: se comunica solo por EventBus (skill_tree_opened / skill_tree_closed).
# NOTA: más adelante esta pantalla se sustituye por la UI del árbol de habilidades,
#       que usará exactamente las mismas dos señales.

class_name WaveEndController
extends CanvasLayer

@onready var _panel: Control = $Panel
@onready var _title: Label = $Panel/VBox/Title
@onready var _button: Button = $Panel/VBox/ContinueButton


func _ready() -> void:
	_panel.hide()
	EventBus.skill_tree_opened.connect(_on_opened)
	EventBus.wave_completed.connect(_on_wave_completed)
	_button.pressed.connect(_on_continue_pressed)


func _on_wave_completed(wave_number: int) -> void:
	_title.text = "¡Oleada %d completada!" % wave_number


func _on_opened() -> void:
	_panel.show()
	_button.grab_focus()


func _on_continue_pressed() -> void:
	_panel.hide()
	EventBus.skill_tree_closed.emit()
