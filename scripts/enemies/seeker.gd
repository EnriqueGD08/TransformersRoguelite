# seeker.gd
# Enemigo: Seeker (Caza Decepticon).
# Volador a distancia. Mantiene distancia óptima y dispara proyectiles.
# HP medio, velocidad alta, daño moderado.
# OCP: extiende BaseEnemy; la IA "flying_shooter" dispara y este script solo decide
#      a qué distancia se mantiene.

class_name Seeker
extends BaseEnemy

## Distancia óptima que el Seeker intenta mantener con el jugador.
@export_range(150.0, 400.0, 10.0) var preferred_distance: float = 220.0


## Sobrescribe el movimiento para mantener la distancia óptima en lugar de
## acercarse indefinidamente. La IA se encarga del disparo.
func _physics_process(delta: float) -> void:
	if not _is_alive or _player == null:
		return
	if _has_status("stun"):
		return

	# Siempre mira al jugador (vuela de lado, no gira para huir).
	_sprite.flip_h = _player.global_position.x < global_position.x

	var dist: float = global_position.distance_to(_player.global_position)

	if dist < preferred_distance * 0.8:
		# Demasiado cerca: retrocede.
		var away: Vector2 = global_position.direction_to(_player.global_position) * -1.0
		velocity = away * get_speed()
		move_and_slide()
	elif dist > preferred_distance * 1.2:
		# Demasiado lejos: se acerca.
		if _ai:
			_ai.process_ai(delta)
	else:
		# En rango óptimo: solo dispara (la IA gestiona el ataque).
		velocity = Vector2.ZERO
		if _ai:
			_ai.process_ai(delta)


func _on_died() -> void:
	_sprite.modulate = Color.WHITE
	EventBus.play_sfx.emit("seeker_death")
	super._on_died()
