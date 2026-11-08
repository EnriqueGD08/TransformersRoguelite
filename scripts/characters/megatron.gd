# megatron.gd
# Personaje jugable: Megatron.
# Rol: artillero pesado a distancia. Daño altísimo, cadencia lenta, HP alto.
# Transformación: modo tanque/pistola → disparo único cargado devastador.
# Arma: fusion_cannon.gd (cañón de fusión, ranged).
# LSP: puede usarse en cualquier lugar donde se espere BaseCharacter.

class_name Megatron
extends BaseCharacter

# ── Nodos hijos ───────────────────────────────────────────────────────────────

@onready var _weapon: Node = $FusionCannon
@onready var _transform_comp: Node = $TransformMegatron

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _on_ready() -> void:
	_setup_transform_component(_transform_comp)
	_transform_comp.character = self

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


## Megatron apunta hacia el ratón en lugar de girar por dirección de movimiento.
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
	EventBus.play_sfx.emit("megatron_transform")


func _on_transform_deactivated() -> void:
	# Al terminar el modo tanque se libera el disparo cargado; vuelve a robot.
	play_animation(&"transform_activate", true)
	EventBus.play_sfx.emit("megatron_revert")

# ── Muerte ────────────────────────────────────────────────────────────────────

func _on_died() -> void:
	play_animation(&"death")
	EventBus.play_sfx.emit("megatron_death")
	set_physics_process(false)
