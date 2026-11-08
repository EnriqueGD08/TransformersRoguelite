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
	_base_damage = stats.attack_damage

# ── Daño y furia ──────────────────────────────────────────────────────────────

func _on_damaged(_amount: float) -> void:
	_flash_hit(0.12)
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
	# Tono rojizo permanente en furia (el destello de daño vuelve a este color).
	_base_modulate = Color(1.5, 0.6, 0.6)
	_sprite.modulate = _base_modulate


## Sobreescribe get_damage() para aplicar el multiplicador de furia.
func get_damage() -> float:
	var base: float = stats.attack_damage
	if _fury_active:
		base *= fury_damage_multiplier
	return base


func _on_died() -> void:
	_fury_active = false
	_sprite.modulate = Color.WHITE
	EventBus.play_sfx.emit("constructicon_death")
	super._on_died()
