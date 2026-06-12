# seeker.gd
# Enemigo: Seeker (Caza Decepticon).
# Volador a distancia. Mantiene distancia óptima y dispara proyectiles.
# HP medio, velocidad alta, daño moderado.
# OCP: extiende BaseEnemy sobrescribiendo solo los hooks necesarios.

class_name Seeker
extends BaseEnemy

## Distancia óptima que el Seeker intenta mantener con el jugador.
@export_range(150.0, 400.0, 10.0) var preferred_distance: float = 220.0

func _on_enemy_ready() -> void:
	_sprite.play("idle")
	# Los Seekers vuelan: desactivamos colisión con el suelo.
	if stats.can_fly:
		set_collision_mask_value(4, false)  # capa de suelo


## Sobrescribe el movimiento para mantener distancia óptima en lugar de
## acercarse indefinidamente. La IA ranged_shooter se encarga del disparo.
func _physics_process(delta: float) -> void:
	if not _is_alive or _player == null:
		return
	if _has_status("stun"):
		return

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


func _on_damaged(_amount: float) -> void:
	_sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and _is_alive:
		_sprite.modulate = Color.WHITE


func _on_died() -> void:
	_sprite.play("death")
	EventBus.play_sfx.emit("seeker_death")
	await _sprite.animation_finished
	queue_free()
