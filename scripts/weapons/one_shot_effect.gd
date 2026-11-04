# one_shot_effect.gd
# Efecto visual de un solo uso (explosión, impacto...): se reproduce y se borra.
# SRP: solo reproduce su animación una vez y se libera.

class_name OneShotEffect
extends AnimatedSprite2D

## Nombre de la animación a reproducir.
@export var animation_to_play: StringName = &"explode"

## Diámetro visible del efecto a escala 1 (para que fit_diameter lo escale bien).
@export_range(10.0, 300.0, 1.0) var base_diameter: float = 110.0


func _ready() -> void:
	modulate.a = 0.9
	animation_finished.connect(queue_free)
	play(animation_to_play)


## Escala el efecto para que cubra aproximadamente [param diameter] píxeles.
func fit_diameter(diameter: float) -> void:
	scale = Vector2.ONE * (diameter / base_diameter)
