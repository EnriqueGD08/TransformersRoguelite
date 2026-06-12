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

# ── Skins ─────────────────────────────────────────────────────────────────────

@export var skin_frames_g1: SpriteFrames
@export var skin_frames_prime: SpriteFrames
@export var skin_frames_bay: SpriteFrames

# ── Estado de arma activa ─────────────────────────────────────────────────────

var _active_weapon: Node = null
var _using_melee: bool = true

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
	if direction.x != 0.0:
		_sprite.flip_h = direction.x < 0.0

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


func _on_transform_activated() -> void:
	_sprite.play("transform_activate")
	EventBus.play_sfx.emit("arcee_transform")


func _on_transform_deactivated() -> void:
	_sprite.play("idle")
	EventBus.play_sfx.emit("arcee_revert")

# ── Muerte ────────────────────────────────────────────────────────────────────

func _on_died() -> void:
	_sprite.play("death")
	EventBus.play_sfx.emit("arcee_death")
	set_physics_process(false)
