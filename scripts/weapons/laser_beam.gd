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

## Color del cuerpo del haz (el mismo morado de energía que usa el arte de Shockwave).
@export var glow_color: Color = Color(0.77, 0.55, 1.0)

## Color de la franja de sombra del cuerpo (estilo cel: tonos planos, sin degradados).
@export var shade_color: Color = Color(0.49, 0.28, 0.82)

## Color del trazo oscuro que rodea al haz.
@export var outline_color: Color = Color(0.1, 0.07, 0.17)

## Color del núcleo.
@export var core_color: Color = Color(1.0, 0.97, 1.0)

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func configure(length: float, width: float) -> void:
	beam_length = length
	beam_width = width


## Estilo cel como el resto de efectos: bandas planas de borde duro con trazo oscuro.
func _draw() -> void:
	var flicker: float = 1.0 + 0.06 * sin(_time * 45.0) + 0.03 * sin(_time * 23.0)
	var w: float = beam_width * flicker
	# Resplandor muy tenue (única transparencia) para que se note a distancia.
	draw_rect(Rect2(0.0, -w * 1.35, beam_length, w * 2.7), Color(glow_color.r, glow_color.g, glow_color.b, 0.12))
	# Trazo oscuro, cuerpo, sombra, luz y núcleo: de fuera hacia dentro.
	draw_rect(Rect2(0.0, -w - 3.0, beam_length, w * 2.0 + 6.0), outline_color)
	draw_rect(Rect2(0.0, -w, beam_length, w * 2.0), shade_color)
	draw_rect(Rect2(0.0, -w, beam_length, w * 1.25), glow_color)
	draw_rect(Rect2(0.0, -w * 0.55, beam_length, w * 0.8), Color(0.9, 0.8, 1.0))
	draw_rect(Rect2(0.0, -w * 0.26, beam_length, w * 0.46), core_color)
	# Chispas en forma de rombo que viajan por el haz.
	for i in 8:
		var x: float = fposmod(_time * 520.0 + i * 91.0, beam_length)
		var y: float = sin(i * 2.3 + _time * 6.0) * w * 0.55
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 11.0, y), Vector2(x, y - 3.0), Vector2(x + 11.0, y), Vector2(x, y + 3.0)]), Color.WHITE)
	# Boca: estallido en estrella con trazo, como los destellos de disparo.
	var spikes := 8
	var star := PackedVector2Array()
	var spin: float = _time * 3.0
	for k in spikes * 2:
		var radius: float = w * (1.55 if k % 2 == 0 else 0.8)
		var angle: float = spin + PI * float(k) / float(spikes)
		star.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(_grow(star, 3.0), outline_color)
	draw_colored_polygon(star, glow_color)
	draw_circle(Vector2.ZERO, w * 0.7, outline_color)
	draw_circle(Vector2.ZERO, w * 0.58, Color(0.9, 0.8, 1.0))
	draw_circle(Vector2.ZERO, w * 0.3, core_color)


## Polígono ensanchado desde el origen (sirve para el trazo del estallido, que es convexo
## respecto al centro).
func _grow(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(p + p.normalized() * amount)
	return out
