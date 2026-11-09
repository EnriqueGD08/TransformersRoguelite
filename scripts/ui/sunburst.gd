# sunburst.gd
# Rayos de luz que giran despacio, como fondo de la pantalla de victoria.
# SRP: solo dibuja el resplandor y los rayos; el giro lo hace la propia rotación del nodo.

class_name Sunburst
extends Node2D

## Alcance de los rayos en píxeles.
@export_range(100.0, 1500.0, 10.0) var radius: float = 460.0

## Número de rayos.
@export_range(4, 40, 1) var ray_count: int = 14

## Color de los rayos (con su transparencia).
@export var color: Color = Color(1.0, 0.78, 0.24, 0.16)

## Velocidad de giro en radianes por segundo.
@export_range(-1.0, 1.0, 0.01) var spin_speed: float = 0.12


func _process(delta: float) -> void:
	rotation += spin_speed * delta


func _draw() -> void:
	# Resplandor: círculos concéntricos muy tenues.
	for i in 6:
		var r: float = radius * 0.55 * (1.0 - float(i) * 0.14)
		draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, 0.05))
	# Rayos: triángulos delgados que salen del centro.
	for i in ray_count:
		var a0: float = TAU * float(i) / float(ray_count)
		var a1: float = a0 + TAU / float(ray_count) * 0.5
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a0) * radius, Vector2.from_angle(a1) * radius]), color)
