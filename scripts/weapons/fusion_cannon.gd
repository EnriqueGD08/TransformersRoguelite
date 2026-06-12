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

# ── IWeapon ───────────────────────────────────────────────────────────────────

func _perform_attack() -> void:
	if projectile_scene == null:
		push_error("FusionCannon: projectile_scene no asignado")
		return

	var damage: float = _calculate_damage()
	var origin: Vector2 = _get_muzzle_position()
	var direction: Vector2 = _get_aim_direction(origin)

	_spawn_projectile(origin, direction, damage)
	_play_fire_animation()


func _get_muzzle_position() -> Vector2:
	if _owner_character == null:
		return global_position
	var offset: Vector2 = muzzle_offset
	if _owner_character._sprite.flip_h:
		offset.x *= -1.0
	return _owner_character.global_position + offset


func _get_aim_direction(from: Vector2) -> Vector2:
	if _owner_character == null:
		return Vector2.RIGHT
	return (get_global_mouse_position() - from).normalized()


func _spawn_projectile(origin: Vector2, direction: Vector2, damage: float) -> void:
	var projectile: Projectile = projectile_scene.instantiate()
	get_parent().get_parent().add_child(projectile)
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
		_owner_character._sprite.play("attack")
