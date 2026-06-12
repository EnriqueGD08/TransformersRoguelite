# boss_enemy.gd
# Enemigo: Jefe de oleada.
# Aparece al final de oleadas específicas (configurado en wave_data.tres).
# HP muy alto, dos fases de comportamiento, recompensa elevada.
# Fase 1 (>50% HP): melee pesado + proyectiles ocasionales.
# Fase 2 (<=50% HP): añade ataques de área y aumenta cadencia.
# OCP: extiende BaseEnemy. La IA base se complementa con lógica de fases.

class_name BossEnemy
extends BaseEnemy

# ── Configuración ─────────────────────────────────────────────────────────────

## Escena del proyectil que usa en fase 1.
@export var projectile_scene_phase1: PackedScene

## Escena del proyectil de área que usa en fase 2.
@export var projectile_scene_phase2: PackedScene

## Radio del ataque de área en fase 2.
@export_range(80.0, 300.0, 10.0) var phase2_aoe_radius: float = 140.0

## Cadencia del ataque adicional de fase 2 (segundos entre ataques de área).
@export_range(0.5, 5.0, 0.5) var phase2_aoe_cooldown: float = 2.5

# ── Estado de fases ───────────────────────────────────────────────────────────

var _phase: int = 1
var _phase2_aoe_timer: float = 0.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _on_enemy_ready() -> void:
	_sprite.play("idle")
	EventBus.boss_spawned.emit(self)


func _physics_process(delta: float) -> void:
	if not _is_alive:
		return
	if _has_status("stun"):
		return

	_check_phase_transition()

	if _phase == 2:
		_process_phase2_aoe(delta)

	if _ai:
		_ai.process_ai(delta)

# ── Fases ─────────────────────────────────────────────────────────────────────

func _check_phase_transition() -> void:
	if _phase == 1 and _current_hp / stats.max_hp <= 0.5:
		_enter_phase2()


func _enter_phase2() -> void:
	_phase = 2
	# En fase 2 el jefe es más rápido.
	_speed_modifier = 1.4
	EventBus.boss_phase_changed.emit(self, 2)
	EventBus.play_sfx.emit("boss_phase2")
	_sprite.play("phase2_intro")


func _process_phase2_aoe(delta: float) -> void:
	_phase2_aoe_timer -= delta
	if _phase2_aoe_timer > 0.0:
		return

	_phase2_aoe_timer = phase2_aoe_cooldown
	_fire_aoe_attack()


func _fire_aoe_attack() -> void:
	if projectile_scene_phase2 == null or _player == null:
		return

	var projectile: Projectile = projectile_scene_phase2.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position

	var direction: Vector2 = global_position.direction_to(_player.global_position)
	projectile.setup(
		direction,
		180.0,
		get_damage() * 0.8,
		phase2_aoe_radius * 3.0,
		phase2_aoe_radius,
		false
	)
	projectile.collision_mask = 1

# ── Daño ─────────────────────────────────────────────────────────────────────

func _on_damaged(amount: float) -> void:
	EventBus.boss_hp_changed.emit(self, _current_hp, stats.max_hp)
	_sprite.modulate = Color.RED
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(self) and _is_alive:
		_sprite.modulate = Color.WHITE


func _on_died() -> void:
	EventBus.boss_defeated.emit(self)
	EventBus.play_sfx.emit("boss_death")
	_sprite.play("death")
	await _sprite.animation_finished
	queue_free()
