# optimus_prime.gd
# Personaje jugable: Optimus Prime.
# Rol: tanque cuerpo a cuerpo. Alta defensa y HP, velocidad media.
# Transformación: modo camión → superarmadura + embestida de área.
# Arma: axe_optimus.gd (hacha de energon, melee).
# LSP: puede usarse en cualquier lugar donde se espere BaseCharacter.

class_name OptimusPrime
extends BaseCharacter

# ── Nodos hijos (asignados en player_optimus.tscn) ───────────────────────────

@onready var _weapon: Node = $AxeOptimus
@onready var _transform_comp: Node = $TransformOptimus

# ── Skins: un SpriteFrames por diseño ────────────────────────────────────────
# Se asignan desde el Inspector en player_optimus.tscn.

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

func _process_movement(delta: float) -> void:
	var direction: Vector2 = _get_input_direction()
	velocity = direction * get_speed()
	move_and_slide()
	_update_facing(direction)


func _get_input_direction() -> Vector2:
	return Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()


func _update_facing(direction: Vector2) -> void:
	if direction.x != 0.0:
		_sprite.flip_h = direction.x < 0.0

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


## Al transformarse, Optimus gana superarmadura y ejecuta una embestida.
func _on_transform_activated() -> void:
	_sprite.play("transform_activate")
	EventBus.play_sfx.emit("optimus_transform")


func _on_transform_deactivated() -> void:
	_sprite.play("idle")
	EventBus.play_sfx.emit("optimus_revert")

# ── Muerte ────────────────────────────────────────────────────────────────────

func _on_died() -> void:
	_sprite.play("death")
	EventBus.play_sfx.emit("optimus_death")
	set_physics_process(false)
