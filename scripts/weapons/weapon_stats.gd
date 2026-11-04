# weapon_stats.gd
# Resource que almacena las estadísticas base de un arma.
# SRP: solo contiene datos, ninguna lógica de disparo ni colisión.
# DIP: base_weapon.gd y sus subclases reciben este Resource por referencia.
# Editable desde el Inspector de Godot sin tocar código.

class_name WeaponStats
extends Resource

# ── Identificación ────────────────────────────────────────────────────────────

## Nombre visible del arma (ej: "Hacha de Energon").
@export var weapon_name: String = ""

## Identificador único en minúsculas sin espacios (ej: "axe_optimus").
@export var weapon_id: String = ""

## Tipo de arma. Determina qué clase concreta debe instanciarse.
@export_enum("melee", "ranged") var weapon_type: String = "melee"

# ── Daño ─────────────────────────────────────────────────────────────────────

## Daño base por impacto o golpe.
@export_range(1.0, 999.0, 1.0) var damage: float = 25.0

## Multiplicador de daño crítico (1.0 = sin crítico, 2.0 = doble daño).
@export_range(1.0, 5.0, 0.1) var crit_multiplier: float = 1.5

## Probabilidad de golpe crítico (0.0 = nunca, 1.0 = siempre).
@export_range(0.0, 1.0, 0.01) var crit_chance: float = 0.05

# ── Cadencia ─────────────────────────────────────────────────────────────────

## Tiempo en segundos entre ataques consecutivos.
@export_range(0.05, 5.0, 0.05) var fire_rate: float = 0.5

# ── Rango y área ─────────────────────────────────────────────────────────────

## Alcance del arma en píxeles.
## Melee: distancia del hitbox. Ranged: distancia máxima del proyectil.
@export_range(40.0, 800.0, 10.0) var range_px: float = 80.0

## Radio de área de efecto en píxeles (0.0 = sin AoE, solo impacto directo).
@export_range(0.0, 300.0, 5.0) var aoe_radius: float = 0.0

# ── Solo armas a distancia ────────────────────────────────────────────────────

## Velocidad del proyectil en píxeles por segundo (ignorado en melee).
@export_range(0.0, 1200.0, 10.0) var projectile_speed: float = 400.0

## Número de proyectiles disparados por ataque (1 = normal, >1 = escopeta).
@export_range(1, 12, 1) var projectile_count: int = 1

## Ángulo de dispersión entre proyectiles en grados (0.0 = sin dispersión).
@export_range(0.0, 45.0, 1.0) var spread_angle: float = 0.0

## Si el proyectil puede atravesar múltiples enemigos.
@export var piercing: bool = false

# ── Solo armas melee ──────────────────────────────────────────────────────────

## Ángulo del arco de golpe en grados (180.0 = semicírculo frontal).
@export_range(30.0, 360.0, 5.0) var hit_arc_degrees: float = 120.0

## Tiempo en segundos que el hitbox permanece activo por golpe.
@export_range(0.05, 1.0, 0.05) var hit_duration: float = 0.15

# ── Efectos de estado ─────────────────────────────────────────────────────────

## Efecto de estado que aplica al impactar.
## Valores válidos: "", "slow", "stun", "burn", "knockback".
@export var status_effect: String = ""

## Probabilidad de aplicar el efecto de estado (0.0 = nunca, 1.0 = siempre).
@export_range(0.0, 1.0, 0.05) var status_chance: float = 0.0

## Duración del efecto de estado en segundos.
@export_range(0.0, 10.0, 0.5) var status_duration: float = 0.0
