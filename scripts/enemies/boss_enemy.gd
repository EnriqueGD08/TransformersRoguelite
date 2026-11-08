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

## Segundos entre los disparos sueltos (fases 1 y 2).
@export_range(0.5, 10.0, 0.5) var shot_cooldown: float = 3.0

## Fracción del daño del jefe que hace cada disparo suelto.
@export_range(0.1, 2.0, 0.1) var shot_damage_ratio: float = 0.5

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
var _shot_timer: float = 1.5

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _on_enemy_ready() -> void:
	EventBus.boss_spawned.emit(self)


func _physics_process(delta: float) -> void:
	if not _is_alive:
		return
	if _has_status("stun"):
		return

	_check_phase_transition()
	_process_shots(delta)

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
	# Rugido: durante la animación no se alterna idle/walk; después queda teñido de rojo.
	_anim_locked = true
	_sprite.play("phase2_intro")
	_base_modulate = Color(1.2, 0.8, 0.8)
	_sprite.modulate = _base_modulate
	shot_cooldown = maxf(shot_cooldown * 0.6, 0.8)


## Disparos sueltos hacia el jugador (fase 1: "proyectiles ocasionales"; en fase 2 más rápidos).
func _process_shots(delta: float) -> void:
	_shot_timer -= delta
	if _shot_timer > 0.0:
		return
	_shot_timer = shot_cooldown
	if projectile_scene_phase1 == null or _player == null:
		return
	var projectile: Projectile = projectile_scene_phase1.instantiate()
	ProjectileContainer.add(self, projectile)
	projectile.global_position = global_position
	projectile.setup(
		global_position.direction_to(_player.global_position),
		260.0,
		get_damage() * shot_damage_ratio,
		stats.detection_range
	)
	projectile.collision_mask = 1
	EventBus.play_sfx.emit("boss_shot")


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
	ProjectileContainer.add(self, projectile)
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

func _on_damaged(_amount: float) -> void:
	EventBus.boss_hp_changed.emit(self, _current_hp, stats.max_hp)
	_flash_hit(0.08)


func _on_died() -> void:
	EventBus.boss_defeated.emit(self)
	EventBus.play_sfx.emit("boss_death")
	_sprite.modulate = Color.WHITE
	super._on_died()
