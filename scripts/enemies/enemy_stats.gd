# enemy_stats.gd
# Resource que almacena las estadísticas base de un tipo de enemigo.
# SRP: solo contiene datos, ninguna lógica de comportamiento.
# DIP: base_enemy.gd y enemy_ai.gd reciben este Resource por referencia.
# Editable desde el Inspector de Godot sin tocar código.

class_name EnemyStats
extends Resource

# ── Identificación ────────────────────────────────────────────────────────────

## Nombre visible del enemigo (ej: "Vehicon", "Seeker").
@export var enemy_name: String = ""

## Identificador único en minúsculas sin espacios (ej: "vehicon", "seeker").
@export var enemy_id: String = ""

# ── Vida ──────────────────────────────────────────────────────────────────────

@export_range(10.0, 5000.0, 10.0) var max_hp: float = 60.0

# ── Movimiento ────────────────────────────────────────────────────────────────

@export_range(20.0, 400.0, 5.0) var move_speed: float = 80.0

## Radio en píxeles dentro del cual el enemigo detecta al jugador.
@export_range(100.0, 1000.0, 20.0) var detection_range: float = 300.0

## Radio en píxeles dentro del cual el enemigo intenta atacar.
@export_range(40.0, 400.0, 10.0) var attack_range: float = 60.0

# ── Ataque ────────────────────────────────────────────────────────────────────

@export_range(1.0, 300.0, 1.0) var attack_damage: float = 10.0

## Tiempo en segundos entre ataques del enemigo.
@export_range(0.2, 5.0, 0.1) var attack_cooldown: float = 1.2

## Segundos entre que empieza la animación de ataque y que el golpe (o el disparo) cuenta:
## coincide con el momento en que el arma baja o sale el fogonazo. 0 = inmediato.
@export_range(0.0, 1.0, 0.01) var attack_windup: float = 0.0

# ── Resistencia ───────────────────────────────────────────────────────────────

## Fracción del empuje (knockback) que el enemigo ignora (0 = lo sufre entero, 1 = inmune).
@export_range(0.0, 1.0, 0.05) var knockback_resistance: float = 0.0

# ── Recompensa ────────────────────────────────────────────────────────────────

## Energon que suelta al morir.
@export_range(0, 200, 1) var energon_reward: int = 5

## Puntos de experiencia que aporta al árbol de habilidades al morir.
@export_range(0, 50, 1) var xp_reward: int = 1

# ── Comportamiento ────────────────────────────────────────────────────────────

## Tipo de IA que usará este enemigo.
## Determina qué estados activa enemy_ai.gd.
@export_enum("melee_chaser", "ranged_shooter", "flying_shooter", "tank_charger") \
	var ai_type: String = "melee_chaser"

## Si el enemigo puede volar (ignora obstáculos en el suelo).
@export var can_fly: bool = false

## Escena del proyectil que usa (solo para ai_type ranged/flying).
@export var projectile_scene: PackedScene
