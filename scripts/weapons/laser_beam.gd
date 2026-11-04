# laser_beam.gd
# Efecto visual del rayo continuo de Shockwave (cañón láser).
# SRP: solo DIBUJA un haz (capas de brillo, núcleo, destellos y boca). No hace daño:
#      el daño lo calcula TransformShockwave con el mismo largo y ancho.
# Se orienta con position/rotation: el haz sale hacia +X.

class_name LaserBeam
extends Node2D

## Largo del haz en píxeles.
@export_range(100.0, 1500.0, 10.0) var beam_length: float = 600.0

## Semiancho del haz en píxeles (el haz mide el doble).
@export_range(4.0, 80.0, 1.0) var beam_width: float = 18.0

## Color del halo exterior.
@export var glow_color: Color = Color(0.72, 0.38, 1.0)

## Color del núcleo.
@export var core_color: Color = Color(1.0, 0.95, 1.0)

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func configure(length: float, width: float) -> void:
	beam_length = length
	beam_width = width


func _draw() -> void:
	var flicker: float = 1.0 + 0.07 * sin(_time * 45.0) + 0.04 * sin(_time * 23.0)
	var w: float = beam_width * flicker
	# Capas de fuera hacia dentro.
	draw_rect(Rect2(0.0, -w, beam_length, w * 2.0), Color(glow_color.r, glow_color.g, glow_color.b, 0.16))
	draw_rect(Rect2(0.0, -w * 0.8, beam_length, w * 1.6), Color(glow_color.r, glow_color.g, glow_color.b, 0.28))
	draw_rect(Rect2(0.0, -w * 0.55, beam_length, w * 1.1), Color(glow_color.r, glow_color.g, glow_color.b, 0.55))
	draw_rect(Rect2(0.0, -w * 0.3, beam_length, w * 0.6), Color(0.92, 0.75, 1.0, 0.9))
	draw_rect(Rect2(0.0, -w * 0.14, beam_length, w * 0.28), core_color)
	# Destellos que viajan por el haz.
	for i in 9:
		var x: float = fposmod(_time * 520.0 + i * 83.0, beam_length)
		var y: float = sin(i * 2.3 + _time * 6.0) * w * 0.5
		draw_rect(Rect2(x, y - 1.0, 18.0, 2.0), Color(1, 1, 1, 0.75))
	# Aro de energía en la boca.
	draw_circle(Vector2.ZERO, w * 0.95, Color(glow_color.r, glow_color.g, glow_color.b, 0.4))
	draw_circle(Vector2.ZERO, w * 0.6, Color(0.95, 0.8, 1.0, 0.8))
	draw_circle(Vector2.ZERO, w * 0.3, core_color)
