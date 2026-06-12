# photon_pistols_arcee.gd
# Arma a distancia de Arcee: Pistolas Fotónicas.
# Dispara dos proyectiles simultáneos (uno por pistola) con ligera dispersión.
# Cadencia media, buena movilidad al disparar (sin penalización de velocidad).
# SRP: solo lógica de disparo de pistolas fotónicas.
# OCP: extiende BaseWeapon sin modificarla.

class_name PhotonPistolsArcee
extends BaseWeapon

# ── Configuración ─────────────────────────────────────────────────────────────

@export var projectile_scene: PackedScene

## Offsets de las dos pistolas respecto al centro del personaje.
@export var muzzle_offset_left: Vector2 = Vector2(20.0, -4.0)
@export var muzzle_offset_right: Vector2 = Vector2(20.0, 4.0)

## Dispersión angular entre los dos proyectiles en grados.
@export_range(0.0, 15.0, 1.0) var spread_degrees: float = 5.0

# ── IWeapon ───────────────────────────────────────────────────────────────────

func _perform_attack() -> void:
	if projectile_scene == null:
		push_error("PhotonPistolsArcee: projectile_scene no asignado")
		return

	var damage: float = _calculate_damage()
	var aim: Vector2 = _get_aim_direction()
	var half_spread: float = deg_to_rad(spread_degrees / 2.0)

	_spawn_projectile(_get_muzzle(muzzle_offset_left), aim.rotated(-half_spread), damage)
	_spawn_projectile(_get_muzzle(muzzle_offset_right), aim.rotated(half_spread), damage)

	_play_fire_animation()


func _get_muzzle(offset: Vector2) -> Vector2:
	if _owner_character == null:
		return global_position
	var o: Vector2 = offset
	if _owner_character._sprite.flip_h:
		o.x *= -1.0
	return _owner_character.global_position + o


func _get_aim_direction() -> Vector2:
	if _owner_character == null:
		return Vector2.RIGHT
	return (get_global_mouse_position() - _owner_character.global_position).normalized()


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
