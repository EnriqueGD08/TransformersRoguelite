# terrain_layer.gd
# Una capa del terreno (suelo o manchas) que parece infinita.
# SRP: solo mantiene su textura repetida centrada bajo el jugador.
# El truco: se mueve de tile en tile (múltiplos exactos del tamaño del bloque), así el dibujo
# queda alineado con el mundo y el salto no se nota; la cámara no ve nunca el borde.

class_name TerrainLayer
extends Sprite2D

## Tamaño en píxeles del MUNDO de un bloque de la textura (ya con la escala del sprite).
@export_range(32.0, 4096.0, 1.0) var tile_world_size: float = 640.0

## Grupo del nodo al que sigue.
@export var target_group: StringName = &"player"

var _target: Node2D = null


func _process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group(target_group) as Node2D
		if _target == null:
			return
	# Mitad de la zona dibujada, en píxeles del mundo (es un múltiplo del tile).
	var half: Vector2 = region_rect.size * scale * 0.5
	var snapped_center: Vector2 = (_target.global_position / tile_world_size).round() * tile_world_size
	global_position = snapped_center - half
