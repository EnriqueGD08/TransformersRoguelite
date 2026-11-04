# training_dummy.gd
# Muñeco de entrenamiento SOLO para pruebas de desarrollo.
# Implementa por convención IDamageable (take_damage) y apply_knockback,
# así se pueden probar armas y transformaciones antes de tener enemigos reales.
# SRP: recibir daño y mostrarlo; nada más.

class_name TrainingDummy
extends CharacterBody2D

## Daño total recibido (para comprobar el ataque en pruebas).
var total_damage: float = 0.0
var hits: int = 0

@onready var _label: Label = $Label


func take_damage(amount: float) -> void:
	total_damage += amount
	hits += 1
	_label.text = "Golpes: %d\nDaño: %.0f" % [hits, total_damage]


func apply_knockback(force: Vector2) -> void:
	velocity = force
	move_and_slide()
