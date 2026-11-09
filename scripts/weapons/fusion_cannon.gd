# fusion_cannon.gd
# Arma a distancia de Megatron: Cañón de Fusión.
# Disparo único de alta potencia con pequeña área de explosión.
# Cadencia lenta, daño altísimo. Apunta al ratón.
# SRP: solo lógica de disparo del cañón de fusión.
# OCP: extiende BaseWeapon sin modificarla.

class_name FusionCannon
extends BaseWeapon

# ── Configuración ─────────────────────────────────────────────────────────────

## Escena del proyectil estándar del cañón.
@export var projectile_scene: PackedScene

## Offset de spawn del proyectil respecto al centro del personaje.
@export var muzzle_offset: Vector2 = Vector2(32.0, 0.0)

## Offset de la boca del cañón en modo tanque.
@export var transformed_muzzle_offset: Vector2 = Vector2(32.0, 0.0)

# ── IWeapon ───────────────────────────────────────────────────────────────────

func _perform_attack() -> void:
	if projectile_scene == null:
		push_error("FusionCannon: projectile_scene no asignado")
		return

	var damage: float = _calculate_damage()
	_play_fire_animation()

	if not await _wait_windup():
		return

	var origin: Vector2 = _get_muzzle_position()
	_spawn_projectile(origin, _get_aim_direction(origin), damage)


func _get_muzzle_position() -> Vector2:
	if _owner_character == null:
		return global_position
	var offset: Vector2 = transformed_muzzle_offset if _owner_character.is_transformed() else muzzle_offset
	if _owner_character.is_facing_left():
		offset.x *= -1.0
	return _owner_character.global_position + offset


func _get_aim_direction(from: Vector2) -> Vector2:
	if _owner_character == null:
		return Vector2.RIGHT
	return AimInput.get_aim_direction(self, from)


func _spawn_projectile(origin: Vector2, direction: Vector2, damage: float) -> void:
	var projectile: Projectile = projectile_scene.instantiate()
	ProjectileContainer.add(self, projectile)
	projectile.global_position = origin
	projectile.reset_physics_interpolation()
	projectile.setup(
		direction,
		stats.projectile_speed,
		damage,
		stats.range_px,
		stats.aoe_radius,
		stats.piercing,
		stats.status_effect,
		stats.status_chance,
		stats.status_duration
	)
	projectile.impacted.connect(func(target, dmg): hit.emit(target, dmg))


func _play_fire_animation() -> void:
	if _owner_character:
		_owner_character.play_animation("attack")
