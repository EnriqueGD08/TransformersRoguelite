# shockwave_cannon.gd
# Arma a distancia de Shockwave: Cañón de Onda de Choque.
# Dispara una onda expansiva que ralentiza a todos los enemigos en su camino.
# Proyectil piercing con AoE progresivo: cuanto más avanza, más ancha la onda.
# SRP: solo lógica de disparo del cañón de onda.
# OCP: extiende BaseWeapon sin modificarla.

class_name ShockwaveCannon
extends BaseWeapon

# ── Configuración ─────────────────────────────────────────────────────────────

@export var projectile_scene: PackedScene

@export var muzzle_offset: Vector2 = Vector2(36.0, 0.0)

## Radio inicial de la onda al dispararse.
@export_range(10.0, 80.0, 5.0) var initial_wave_radius: float = 20.0

## Radio máximo que alcanza la onda al final de su recorrido.
@export_range(40.0, 200.0, 10.0) var max_wave_radius: float = 80.0

# ── IWeapon ───────────────────────────────────────────────────────────────────

func _perform_attack() -> void:
	if projectile_scene == null:
		push_error("ShockwaveCannon: projectile_scene no asignado")
		return

	var damage: float = _calculate_damage()
	var origin: Vector2 = _get_muzzle_position()
	var direction: Vector2 = _get_aim_direction(origin)

	var projectile: Projectile = projectile_scene.instantiate()
	ProjectileContainer.add(self, projectile)
	projectile.global_position = origin

	# Shockwave usa piercing y slow como efecto de estado desde WeaponStats.
	projectile.setup(
		direction,
		stats.projectile_speed,
		damage,
		stats.range_px,
		0.0,                  # sin explosión: el área es la propia onda que se ensancha
		true,                 # piercing siempre activo
		stats.status_effect,  # "slow" configurado en el .tres
		stats.status_chance,
		stats.status_duration
	)

	# La onda crece desde initial_wave_radius hasta max_wave_radius a lo largo del recorrido.
	projectile.set_expanding_wave(initial_wave_radius, max_wave_radius, stats.range_px)

	projectile.impacted.connect(func(target, dmg): hit.emit(target, dmg))
	_play_fire_animation()


func _get_muzzle_position() -> Vector2:
	if _owner_character == null:
		return global_position
	var offset: Vector2 = muzzle_offset
	if _owner_character.is_facing_left():
		offset.x *= -1.0
	return _owner_character.global_position + offset


func _get_aim_direction(from: Vector2) -> Vector2:
	if _owner_character == null:
		return Vector2.RIGHT
	return (get_global_mouse_position() - from).normalized()


func _play_fire_animation() -> void:
	if _owner_character:
		_owner_character.play_animation("attack")
