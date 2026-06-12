# axe_optimus.gd
# Arma melee de Optimus Prime: Hacha de Energon.
# Golpe amplio de arco frontal con knockback.
# Durante la transformación el golpe aumenta su radio y añade AoE circular.
# SRP: solo lógica de ataque con hacha.
# OCP: extiende BaseWeapon sin modificarla.

class_name AxeOptimus
extends BaseWeapon

# ── Nodos hijos ───────────────────────────────────────────────────────────────

@onready var _hitbox: Hitbox = $Hitbox

# ── Configuración específica ──────────────────────────────────────────────────

## Radio adicional del hitbox durante la transformación en píxeles.
@export_range(0.0, 100.0, 5.0) var transform_radius_bonus: float = 40.0

## Fuerza de knockback aplicada a los enemigos golpeados.
@export_range(0.0, 600.0, 20.0) var knockback_force: float = 250.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _on_weapon_ready() -> void:
	_hitbox.enemy_hit.connect(_on_enemy_hit)

# ── IWeapon ───────────────────────────────────────────────────────────────────

func _perform_attack() -> void:
	var damage: float = _calculate_damage()

	# Si el propietario está transformado, aumenta el radio del hitbox.
	if _owner_character and _owner_character.is_transformed():
		_scale_hitbox(transform_radius_bonus)
		damage *= _owner_character.stats.transform_damage_multiplier

	_hitbox.activate(damage, stats.hit_duration)
	_play_swing_animation()


func _play_swing_animation() -> void:
	if _owner_character:
		_owner_character._sprite.play("attack")


## Escala temporalmente el CollisionShape del hitbox.
func _scale_hitbox(bonus_radius: float) -> void:
	var shape: Shape2D = _hitbox.get_node("CollisionShape2D").shape
	if shape is CircleShape2D:
		shape.radius += bonus_radius
		# Restaura el radio original tras el golpe.
		await get_tree().create_timer(stats.hit_duration + 0.05).timeout
		shape.radius -= bonus_radius

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_enemy_hit(target: Node, damage: float) -> void:
	hit.emit(target, damage)
	if target.has_method("apply_knockback"):
		var direction: Vector2 = (target.global_position \
			- _owner_character.global_position).normalized()
		target.apply_knockback(direction * knockback_force)
