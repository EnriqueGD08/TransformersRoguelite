# wave_data.gd
# Resource que define el contenido de una oleada concreta.
# SRP: solo contiene datos de qué enemigos aparecen y cuándo.
#      WaveManager lee este Resource y delega el spawn al EnemySpawner.
# DIP: WaveManager depende de este Resource, no de tipos concretos de enemigo.
# Editable desde el Inspector sin tocar código.

class_name WaveData
extends Resource

# ── Identificación ────────────────────────────────────────────────────────────

## Número de la oleada (1-based). Debe coincidir con el nombre del archivo.
@export_range(1, 100, 1) var wave_number: int = 1

## Tiempo en segundos de duración total de la oleada.
## Al expirar, los enemigos restantes se eliminan y se avanza.
@export_range(10.0, 300.0, 5.0) var duration: float = 60.0

## Si es true, la oleada no termina hasta matar a todos los enemigos
## (independientemente del tiempo).
@export var must_kill_all: bool = false

# ── Enemigos ──────────────────────────────────────────────────────────────────

## Lista de grupos de spawn de esta oleada.
## Cada entrada define qué enemigo, cuántos y con qué cadencia aparecen.
@export var spawn_groups: Array[SpawnGroup] = []

## Si es true, esta oleada incluye un jefe al final.
@export var has_boss: bool = false

## Escena del jefe de esta oleada (ignorado si has_boss es false).
@export var boss_scene: PackedScene

# ── Modificadores de dificultad ───────────────────────────────────────────────

## Multiplicador global de HP de todos los enemigos de esta oleada.
## Permite escalar la dificultad sin duplicar Resources.
@export_range(0.5, 5.0, 0.1) var enemy_hp_multiplier: float = 1.0

## Multiplicador global de daño de todos los enemigos de esta oleada.
@export_range(0.5, 5.0, 0.1) var enemy_damage_multiplier: float = 1.0

## Multiplicador global de velocidad de todos los enemigos de esta oleada.
@export_range(0.5, 3.0, 0.1) var enemy_speed_multiplier: float = 1.0

# ── Recompensas ───────────────────────────────────────────────────────────────

## Puntos de habilidad extra que otorga completar esta oleada.
@export_range(0, 10, 1) var bonus_skill_points: int = 1

## Energon extra garantizado al completar la oleada.
@export_range(0, 500, 10) var bonus_energon: int = 0


# ── SpawnGroup (clase interna del Resource) ───────────────────────────────────

## Define un grupo de enemigos del mismo tipo dentro de una oleada.
class SpawnGroup extends Resource:

	## Escena del enemigo a spawnear.
	@export var enemy_scene: PackedScene

	## Número total de enemigos de este grupo en la oleada.
	@export_range(1, 100, 1) var count: int = 5

	## Tiempo en segundos entre spawns consecutivos de este grupo.
	@export_range(0.1, 10.0, 0.1) var spawn_interval: float = 1.5

	## Retardo inicial antes del primer spawn de este grupo (segundos).
	@export_range(0.0, 30.0, 0.5) var initial_delay: float = 0.0

	## Si es true, los enemigos del grupo aparecen en posiciones fijas
	## definidas en spawn_positions. Si es false, se usan posiciones aleatorias.
	@export var use_fixed_positions: bool = false

	## Posiciones fijas de spawn (en coordenadas locales del nivel).
	## Solo se usa si use_fixed_positions es true.
	@export var spawn_positions: Array[Vector2] = []
