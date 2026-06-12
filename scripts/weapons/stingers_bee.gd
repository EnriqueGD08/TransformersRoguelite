# stingers_bee.gd
# Arma melee de Bumblebee: Puños Stinger de Energon.
# Ataques rápidos y encadenados. Alta cadencia, daño moderado.
# Cada tercer golpe es un remate con stun breve.
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

	_hitbox.activate(damage, stats.hit_duration)
	_play_attack_animation(is_finisher)


func _play_attack_animation(is_finisher: bool) -> void:
	if _owner_character:
		_owner_character._sprite.play("attack_finisher" if is_finisher else "attack")

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_enemy_hit(target: Node, damage: float) -> void:
	hit.emit(target, damage)

	# El tercer golpe aplica stun.
	if _combo_count == FINISHER_STEP and target.has_method("apply_status"):
		target.apply_status("stun", finisher_stun_duration)
