# null_ray.gd
# Arma a distancia de Starscream: Rayo Nulificador.
# Proyectil de alta velocidad y largo alcance que aplica slow al impactar.
# Puede disparar en ráfaga de dos rayos con leve dispersión.
# SRP: solo lógica de disparo del rayo nulificador.
# OCP: extiende BaseWeapon sin modificarla.

class_name NullRay
extends BaseWeapon

# ── Configuración ─────────────────────────────────────────────────────────────

## Escena del proyectil del rayo.
@export var projectile_scene: PackedScene

## Offset del cañón respecto al centro del personaje.
@export var muzzle_offset: Vector2 = Vector2(28.0, -6.0)

## Offset del morro en modo jet.
@export var transformed_muzzle_offset: Vector2 = Vector2(28.0, -6.0)

## Separación angular entre los dos rayos de la ráfaga en grados.
@export_range(0.0, 20.0, 1.0) var burst_spread_degrees: float = 6.0

# ── IWeapon ───────────────────────────────────────────────────────────────────

func _perform_attack() -> void:
	if projectile_scene == null:
		push_error("NullRay: projectile_scene no asignado")
		return

	var damage: float = _calculate_damage()
	_play_fire_animation()

	if not await _wait_windup():
		return

	var origin: Vector2 = _get_muzzle_position()
	var base_direction: Vector2 = _get_aim_direction(origin)

	# Dispara el número de proyectiles definido en WeaponStats.
	for i in stats.projectile_count:
		var spread_angle: float = 0.0
		if stats.projectile_count > 1:
			var half: float = (stats.projectile_count - 1) / 2.0
			spread_angle = deg_to_rad(burst_spread_degrees * (i - half))

		var direction: Vector2 = base_direction.rotated(spread_angle)
		_spawn_projectile(origin, direction, damage)


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
	return (get_global_mouse_position() - from).normalized()


func _spawn_projectile(origin: Vector2, direction: Vector2, damage: float) -> void:
	var projectile: Projectile = projectile_scene.instantiate()
	ProjectileContainer.add(self, projectile)
	projectile.global_position = origin
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
