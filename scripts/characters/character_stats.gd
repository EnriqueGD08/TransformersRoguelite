# character_stats.gd
# Resource que almacena las estadísticas base de un personaje.
# SRP: solo contiene datos, ninguna lógica de juego.
# DIP: los sistemas reciben este Resource por referencia,
#      no dependen de clases concretas de personaje.
# Editable desde el Inspector de Godot sin tocar código.

class_name CharacterStats
extends Resource

# ── Identificación ────────────────────────────────────────────────────────────

## Nombre visible del personaje (ej: "Optimus Prime").
@export var character_name: String = ""

## Identificador único en minúsculas sin espacios (ej: "optimus_prime").
@export var character_id: String = ""

# ── Vida ──────────────────────────────────────────────────────────────────────

## Puntos de vida máximos en modo robot.
@export_range(50.0, 1000.0, 5.0) var max_hp: float = 100.0

## Regeneración de HP por segundo en modo robot (0.0 = sin regeneración).
@export_range(0.0, 20.0, 0.5) var hp_regen_per_second: float = 0.0

# ── Movimiento ────────────────────────────────────────────────────────────────

## Velocidad de movimiento base en píxeles por segundo.
@export_range(50.0, 500.0, 10.0) var move_speed: float = 150.0

# ── Ataque ────────────────────────────────────────────────────────────────────

## Daño base por golpe o proyectil.
@export_range(1.0, 500.0, 1.0) var base_damage: float = 20.0

## Tiempo en segundos entre ataques (cadencia).
@export_range(0.1, 5.0, 0.05) var attack_cooldown: float = 0.5

## Rango de ataque en píxeles (melee ~80, distancia ~400).
@export_range(40.0, 600.0, 10.0) var attack_range: float = 80.0

# ── Defensa ───────────────────────────────────────────────────────────────────

## Reducción de daño recibido en porcentaje (0.0 = ninguna, 0.5 = 50%).
@export_range(0.0, 0.9, 0.01) var damage_reduction: float = 0.0

## Probabilidad de esquivar un ataque (0.0 = nunca, 1.0 = siempre).
@export_range(0.0, 0.75, 0.01) var dodge_chance: float = 0.0

# ── Transformación ────────────────────────────────────────────────────────────

## Duración de la transformación en segundos.
@export_range(1.0, 15.0, 0.5) var transform_duration: float = 5.0

## Tiempo de cooldown tras usar la transformación, en segundos.
@export_range(5.0, 60.0, 1.0) var transform_cooldown: float = 20.0

# ── Modificadores en modo transformado ───────────────────────────────────────
# Multiplicadores que se aplican SOLO mientras la transformación está activa.
# 1.0 = sin cambio. 2.0 = doble. 0.5 = la mitad.

## Multiplicador de HP máximo durante la transformación.
@export_range(0.5, 3.0, 0.1) var transform_hp_multiplier: float = 1.0

## Multiplicador de velocidad durante la transformación.
@export_range(0.5, 3.0, 0.1) var transform_speed_multiplier: float = 1.0

## Multiplicador de daño durante la transformación.
@export_range(0.5, 5.0, 0.1) var transform_damage_multiplier: float = 1.0

## Multiplicador de reducción de daño durante la transformación.
@export_range(0.5, 3.0, 0.1) var transform_defense_multiplier: float = 1.0

# ── Progresión ────────────────────────────────────────────────────────────────

## Radio en píxeles dentro del cual el energon vuela hacia el personaje.
@export_range(20.0, 400.0, 5.0) var pickup_radius: float = 90.0

## Puntos de habilidad iniciales al comenzar una run.
@export_range(0, 10, 1) var starting_skill_points: int = 0

## Energon inicial al comenzar una run.
@export_range(0, 500, 10) var starting_energon: int = 0

# ── Skins ─────────────────────────────────────────────────────────────────────

## IDs de skins disponibles para este personaje.
## Valores válidos: "g1", "prime", "bay".
@export var available_skins: Array[String] = ["g1", "prime", "bay"]

## Skin activa por defecto al seleccionar el personaje.
@export var default_skin: String = "g1"
