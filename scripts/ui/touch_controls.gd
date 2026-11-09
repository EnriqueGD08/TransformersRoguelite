# touch_controls.gd
# Controles táctiles: joystick izquierdo para moverte, joystick derecho para apuntar
# (y atacar mientras lo mantienes) y botones de transformar y cambiar de arma.
# SRP: traduce los gestos a las MISMAS acciones que el teclado (move_*, attack) y a la
#      dirección de puntería de AimInput. El personaje no sabe si juegas con dedos o teclas.
# Solo se muestra en dispositivos táctiles (o con el argumento --touch-controls para probarlo).

class_name TouchControls
extends CanvasLayer

## Acciones de movimiento: (acción, eje, signo).
const MOVE_ACTIONS: Array = [
	[&"move_left", "x", -1.0],
	[&"move_right", "x", 1.0],
	[&"move_up", "y", -1.0],
	[&"move_down", "y", 1.0],
]

@onready var _move_stick: VirtualJoystick = %MoveStick
@onready var _aim_stick: VirtualJoystick = %AimStick
@onready var _transform_button: TouchActionButton = %TransformButton
@onready var _swap_button: TouchActionButton = %SwapButton

var _aiming: bool = false


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available() or OS.get_cmdline_user_args().has("--touch-controls")
	_move_stick.vector_changed.connect(_on_move_changed)
	_aim_stick.vector_changed.connect(_on_aim_changed)
	EventBus.transform_cooldown_updated.connect(_transform_button.set_cooldown)
	_swap_button.hide()


## Inyección del personaje: solo Arcee tiene botón de cambio de arma.
func setup(player: BaseCharacter) -> void:
	_swap_button.visible = player.supports_weapon_swap()


func _on_move_changed(vector: Vector2) -> void:
	for entry in MOVE_ACTIONS:
		var amount: float = vector[entry[1]] * entry[2]
		if amount > 0.0:
			Input.action_press(entry[0], amount)
		else:
			Input.action_release(entry[0])
	# Sin apuntar, el personaje mira hacia donde camina.
	if not _aiming and vector != Vector2.ZERO:
		AimInput.set_direction(vector)


## Mientras el joystick derecho está empujado: apunta hacia allí y ataca.
func _on_aim_changed(vector: Vector2) -> void:
	_aiming = vector != Vector2.ZERO
	if _aiming:
		AimInput.set_direction(vector)
		Input.action_press(&"attack")
	else:
		Input.action_release(&"attack")


func _exit_tree() -> void:
	for entry in MOVE_ACTIONS:
		Input.action_release(entry[0])
	Input.action_release(&"attack")
