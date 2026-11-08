# stingers_bee.gd
# Arma melee de Bumblebee: Puños Stinger de Energon.
# Ataques rápidos y encadenados. Alta cadencia, daño moderado.
# Combo de tres: directo, cruzado con la otra mano y remate con stun breve.
# SRP: solo lógica de ataque con stingers.
# OCP: extiende BaseWeapon sin modificarla.

class_name StingersBee
extends BaseWeapon

# ── Nodos hijos ───────────────────────────────────────────────────────────────

@onready var _hitbox: Hitbox = $Hitbox

# ── Configuración específica ──────────────────────────────────────────────────

## Duración del stun del tercer golpe en segundos.
@export_range(0.1, 2.0, 0.1) var finisher_stun_duration: float = 0.5

## Multiplicador de daño del remate (tercer golpe).
@export_range(1.0, 4.0, 0.1) var finisher_damage_multiplier: float = 2.0

# ── Estado del combo ──────────────────────────────────────────────────────────

var _combo_count: int = 0
const FINISHER_STEP: int = 3

## Animación de cada golpe del combo.
const COMBO_ANIMATIONS: Array[StringName] = [&"attack", &"attack_cross", &"attack_finisher"]

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _on_weapon_ready() -> void:
	_hitbox.enemy_hit.connect(_on_enemy_hit)

# ── IWeapon ───────────────────────────────────────────────────────────────────

func _perform_attack() -> void:
	_combo_count = (_combo_count + 1) % (FINISHER_STEP + 1)
	if _combo_count == 0:
		_combo_count = 1

	var damage: float = _calculate_damage()
	var is_finisher: bool = _combo_count == FINISHER_STEP

	if is_finisher:
		damage *= finisher_damage_multiplier

	_play_attack_animation()

	# El golpe cuenta cuando el puño llega, no al pulsar.
	if not await _wait_windup():
		return

	_hitbox.activate(damage, stats.hit_duration)


func _play_attack_animation() -> void:
	if _owner_character:
		_owner_character.play_animation(COMBO_ANIMATIONS[_combo_count - 1])

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_enemy_hit(target: Node, damage: float) -> void:
	hit.emit(target, damage)

	# El tercer golpe aplica stun.
	if _combo_count == FINISHER_STEP and target.has_method("apply_status"):
		target.apply_status("stun", finisher_stun_duration)
