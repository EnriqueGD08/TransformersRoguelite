# starscream.gd
# Personaje jugable: Starscream.
# Rol: francotirador aéreo a distancia. Máximo rango, HP bajo, esquiva media.
# Transformación: modo jet F-22 → vuelo real + bomba en picado de área.
# Arma: null_ray.gd (rayo nulificador, ranged de largo alcance).
# LSP: puede usarse en cualquier lugar donde se espere BaseCharacter.

class_name Starscream
extends BaseCharacter

# ── Nodos hijos ───────────────────────────────────────────────────────────────

@onready var _weapon: Node = $NullRay
@onready var _transform_comp: Node = $TransformStarscream

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
	velocity = direction * get_speed()
	move_and_slide()
	_aim_towards_mouse()
	_update_move_animation(direction)


func _aim_towards_mouse() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	_sprite.flip_h = mouse_pos.x < global_position.x

# ── Ataque ────────────────────────────────────────────────────────────────────

func _process_attack(_delta: float) -> void:
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
	EventBus.play_sfx.emit("starscream_transform")


func _on_transform_deactivated() -> void:
	# La animación de transformación al revés: jet -> robot.
	play_animation(&"transform_activate", true)
	EventBus.play_sfx.emit("starscream_revert")

# ── Muerte ────────────────────────────────────────────────────────────────────

func _on_died() -> void:
	play_animation(&"death")
	EventBus.play_sfx.emit("starscream_death")
	set_physics_process(false)
