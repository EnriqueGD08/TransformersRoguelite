# constructicon.gd
# Enemigo: Constructicon.
# Tanque pesado melee. HP muy alto, velocidad muy baja, daño alto.
# Al llegar al 30% de HP entra en modo "furia": velocidad y daño aumentan.
# OCP: extiende BaseEnemy sobrescribiendo solo los hooks necesarios.

class_name Constructicon
extends BaseEnemy

## Umbral de HP (porcentaje) a partir del cual se activa la furia.
@export_range(0.1, 0.5, 0.05) var fury_threshold: float = 0.30

## Multiplicador de velocidad durante la furia.
@export_range(1.1, 3.0, 0.1) var fury_speed_multiplier: float = 1.8

## Multiplicador de daño durante la furia.
@export_range(1.1, 3.0, 0.1) var fury_damage_multiplier: float = 1.5

var _fury_active: bool = false
var _base_damage: float = 0.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _on_enemy_ready() -> void:
	_sprite.play("idle")
	_base_damage = stats.attack_damage

# ── Daño y furia ──────────────────────────────────────────────────────────────

func _on_damaged(_amount: float) -> void:
	_sprite.modulate = Color.RED
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(self) and _is_alive:
		_sprite.modulate = Color.WHITE

	_check_fury_trigger()


func _check_fury_trigger() -> void:
	if _fury_active:
		return
	if _current_hp / stats.max_hp <= fury_threshold:
		_activate_fury()


func _activate_fury() -> void:
	_fury_active = true
	_speed_modifier = fury_speed_multiplier
	# El daño extra se aplica sobreescribiendo get_damage().
	EventBus.play_sfx.emit("constructicon_fury")
	_sprite.modulate = Color(1.5, 0.5, 0.5)  # tono rojizo permanente en furia


## Sobreescribe get_damage() para aplicar el multiplicador de furia.
func get_damage() -> float:
	var base: float = stats.attack_damage
	if _fury_active:
		base *= fury_damage_multiplier
	return base


func _on_died() -> void:
	_fury_active = false
	_sprite.play("death")
	EventBus.play_sfx.emit("constructicon_death")
	await _sprite.animation_finished
	queue_free()
