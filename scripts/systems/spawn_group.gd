# spawn_group.gd
# Resource que define un grupo de enemigos del mismo tipo dentro de una oleada.
# SRP: solo contiene datos de spawn (qué enemigo, cuántos, cadencia, posiciones).
# Vive en su propio archivo (class_name) para que Array[SpawnGroup] se pueda
# editar correctamente desde el Inspector en WaveData.

class_name SpawnGroup
extends Resource

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
