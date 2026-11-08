# arcee.gd
# Personaje jugable: Arcee.
# Rol: híbrida. Melee rápido a corta distancia + pistolas a media distancia.
#      Velocidad alta, HP medio, especialista en cambio de distancia.
# Transformación: modo moto → velocidad extrema + dash que deja estela cortante.
# Armas: twin_blades_arcee.gd (melee) y photon_pistols_arcee.gd (ranged).
#        Alterna entre ellas con el botón "swap_weapon".
# LSP: puede usarse en cualquier lugar donde se espere BaseCharacter.

class_name Arcee
extends BaseCharacter

# ── Nodos hijos ───────────────────────────────────────────────────────────────

@onready var _melee_weapon: Node = $TwinBladesArcee
@onready var _ranged_weapon: Node = $PhotonPistolsArcee
@onready var _transform_comp: Node = $TransformArcee

# ── Estado de arma activa ─────────────────────────────────────────────────────

var _active_weapon: Node = null
var _using_melee: bool = true

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _on_ready() -> void:
	_setup_transform_component(_transform_comp)
	_transform_comp.character = self

	_active_weapon = _melee_weapon
	EventBus.weapon_swapped.emit("melee")

# ── Movimiento ────────────────────────────────────────────────────────────────

func _process_movement(_delta: float) -> void:
	var direction: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()
	velocity = direction * get_speed()
	move_and_slide()
	if _using_melee or _is_transformed:
		# Cuerpo a cuerpo y en moto: mira hacia donde se mueve.
		if direction.x != 0.0:
			_sprite.flip_h = direction.x < 0.0
	else:
		# Con las pistolas apunta al ratón.
		_sprite.flip_h = get_global_mouse_position().x < global_position.x
	_update_move_animation(direction)

# ── Ataque ────────────────────────────────────────────────────────────────────

func _process_attack(_delta: float) -> void:
	if Input.is_action_pressed("attack") and _active_weapon.can_fire():
		_active_weapon.fire()


func can_attack() -> bool:
	return _active_weapon != null and _active_weapon.can_fire()

# ── Transformación e input ────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("transform"):
		request_transform()
	elif event.is_action_pressed("swap_weapon"):
		_swap_weapon()


## Alterna entre arma melee y a distancia.
func _swap_weapon() -> void:
	_using_melee = not _using_melee
	_active_weapon = _melee_weapon if _using_melee else _ranged_weapon
	var label: String = "melee" if _using_melee else "ranged"
	EventBus.weapon_swapped.emit(label)
	EventBus.play_sfx.emit("arcee_swap")
	# Refresca el aspecto (cuchillas <-> pistolas) si está en reposo o caminando.
	_update_move_animation(velocity)


## Cada arma tiene sus propias animaciones ("ranged_idle", "ranged_walk"...).
func _resolve_animation(base_name: StringName) -> StringName:
	if not _is_transformed and not _using_melee and _sprite.sprite_frames != null:
		var frames: SpriteFrames = _sprite.sprite_frames
		# Disparar en movimiento: las piernas siguen caminando.
		var moving_attack: StringName = StringName("ranged_walk_" + base_name)
		if velocity.length() > 1.0 and frames.has_animation(moving_attack):
			return moving_attack
		var ranged: StringName = StringName("ranged_" + base_name)
		if frames.has_animation(ranged):
			return ranged
	return super._resolve_animation(base_name)


func _on_transform_activated() -> void:
	play_animation(&"transform_activate")
	EventBus.play_sfx.emit("arcee_transform")


func _on_transform_deactivated() -> void:
	# La animación de transformación al revés: moto -> robot.
	play_animation(&"transform_activate", true)
	EventBus.play_sfx.emit("arcee_revert")

# ── Muerte ────────────────────────────────────────────────────────────────────

func _on_died() -> void:
	play_animation(&"death")
	EventBus.play_sfx.emit("arcee_death")
	set_physics_process(false)
