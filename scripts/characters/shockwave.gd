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
	velocity = direction * get_speed()
	move_and_slide()
	_aim_towards_mouse()


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
	_sprite.play("transform_activate")
	EventBus.play_sfx.emit("shockwave_transform")


func _on_transform_deactivated() -> void:
	_sprite.play("idle")
	EventBus.play_sfx.emit("shockwave_revert")

# ── Muerte ────────────────────────────────────────────────────────────────────

func _on_died() -> void:
	_sprite.play("death")
	EventBus.play_sfx.emit("shockwave_death")
	set_physics_process(false)
