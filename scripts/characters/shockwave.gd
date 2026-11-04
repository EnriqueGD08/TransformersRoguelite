# shockwave.gd
# Personaje jugable: Shockwave.
# Rol: artillero de control. Daño alto a distancia + ralentización de enemigos.
#      HP alto, velocidad baja. Especialista en mantener distancia y controlar oleadas.
# Transformación: modo cañón láser → rayo continuo que perfora todas las filas.
# Arma: shockwave_cannon.gd (cañón de onda de choque, ranged con slow).
# LSP: puede usarse en cualquier lugar donde se espere BaseCharacter.

class_name Shockwave
extends BaseCharacter

# ── Nodos hijos ───────────────────────────────────────────────────────────────

@onready var _weapon: Node = $ShockwaveCannon
@onready var _transform_comp: Node = $TransformShockwave

# ── Skins ─────────────────────────────────────────────────────────────────────

@export var skin_frames_g1: SpriteFrames
@export var skin_frames_prime: SpriteFrames
@export var skin_frames_bay: SpriteFrames

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _on_ready() -> void:
	_setup_transform_component(_transform_comp)
	_transform_comp.character = self

	var frames: Dictionary = {
		"g1": skin_frames_g1,
		"prime": skin_frames_prime,
		"bay": skin_frames_bay,
	}
	_skin_manager.setup(_sprite, frames, stats.available_skins)
	_skin_manager.set_skin(stats.default_skin)

# ── Movimiento ────────────────────────────────────────────────────────────────

func _process_movement(_delta: float) -> void:
	var direction: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()
	# Como cañón láser está inmóvil (pero sigue apuntando).
	if _movement_locked:
		direction = Vector2.ZERO
	velocity = direction * get_speed()
	move_and_slide()
	_aim_towards_mouse()
	_update_move_animation(direction)


## Mira hacia el ratón. Como cañón láser, además gira el sprite entero para que
## el cañón apunte exactamente donde se dispara el rayo.
func _aim_towards_mouse() -> void:
	var to_mouse: Vector2 = get_global_mouse_position() - global_position
	_sprite.flip_h = to_mouse.x < 0.0
	if _is_transformed and to_mouse.length() > 1.0:
		# Con el sprite espejado el cañón apunta a la izquierda: se compensa con PI.
		_sprite.rotation = to_mouse.angle() - (PI if _sprite.flip_h else 0.0)
	else:
		_sprite.rotation = 0.0

# ── Ataque ────────────────────────────────────────────────────────────────────

func _process_attack(_delta: float) -> void:
	# Como cañón láser el rayo sustituye al disparo normal.
	if _is_transformed:
		return
	if Input.is_action_pressed("attack") and _weapon.can_fire():
		_weapon.fire()


func can_attack() -> bool:
	return _weapon != null and _weapon.can_fire()

# ── Transformación ────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("transform"):
		request_transform()


func _on_transform_activated() -> void:
	play_animation(&"transform_activate")
	EventBus.play_sfx.emit("shockwave_transform")


func _on_transform_deactivated() -> void:
	# La animación de transformación al revés: cañón -> robot.
	play_animation(&"transform_activate", true)
	EventBus.play_sfx.emit("shockwave_revert")

# ── Muerte ────────────────────────────────────────────────────────────────────

func _on_died() -> void:
	play_animation(&"death")
	EventBus.play_sfx.emit("shockwave_death")
	set_physics_process(false)
