# twin_blades_arcee.gd
# Arma melee de Arcee: Cuchillas Gemelas de Energon.
# Ataque en X con dos hitboxes simultáneos (izquierda y derecha).
# Alta cadencia, rango corto, daño moderado con posibilidad de sangrado.
# SRP: solo lógica de ataque con cuchillas gemelas.
# OCP: extiende BaseWeapon sin modificarla.

class_name TwinBladesArcee
extends BaseWeapon

# ── Nodos hijos ───────────────────────────────────────────────────────────────

## Hitbox del brazo izquierdo.
@onready var _hitbox_left: Hitbox = $HitboxLeft

## Hitbox del brazo derecho.
@onready var _hitbox_right: Hitbox = $HitboxRight

# ── Configuración ─────────────────────────────────────────────────────────────

## Probabilidad de aplicar sangrado (daño por tick durante 3 segundos).
@export_range(0.0, 1.0, 0.05) var bleed_chance: float = 0.20

## Daño por tick del sangrado.
@export_range(1.0, 30.0, 1.0) var bleed_damage_per_tick: float = 5.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _on_weapon_ready() -> void:
	# Ambos hitboxes se solapan en el centro: comparten la lista para no golpear 2 veces.
	var shared: Array = []
	_hitbox_left.share_hit_list(shared)
	_hitbox_right.share_hit_list(shared)
	_hitbox_left.enemy_hit.connect(_on_enemy_hit)
	_hitbox_right.enemy_hit.connect(_on_enemy_hit)

# ── IWeapon ───────────────────────────────────────────────────────────────────

func _perform_attack() -> void:
	var damage: float = _calculate_damage()
	_play_attack_animation()

	# El tajo cuenta cuando las cuchillas bajan, no al pulsar.
	if not await _wait_windup():
		return

	_hitbox_left.activate(damage, stats.hit_duration)
	_hitbox_right.activate(damage, stats.hit_duration)


func _play_attack_animation() -> void:
	if _owner_character:
		_owner_character.play_animation("attack")

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_enemy_hit(target: Node, damage: float) -> void:
	hit.emit(target, damage)

	if randf() < bleed_chance and target.has_method("apply_status"):
		target.apply_status("bleed", 3.0)
