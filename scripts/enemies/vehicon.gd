# vehicon.gd
# Enemigo: Vehicon.
# Soldado básico de los Decepticons. Melee, persigue al jugador directamente.
# HP bajo, velocidad media, daño bajo. Peligroso en grupos.
# OCP: extiende BaseEnemy sobrescribiendo solo los hooks necesarios.

class_name Vehicon
extends BaseEnemy


func _on_enemy_ready() -> void:
	# Siempre persigue, así que camina por defecto y ataca al golpear.
	_sprite.play("walk")
	attacked_player.connect(_on_attacked_player)
	_sprite.animation_finished.connect(_on_animation_finished)


func _on_attacked_player(_damage: float) -> void:
	if _is_alive:
		_sprite.play("attack")


func _on_animation_finished() -> void:
	if _is_alive:
		_sprite.play("walk")


func _on_damaged(_amount: float) -> void:
	# Parpadeo visual al recibir daño.
	_sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self) and _is_alive:
		_sprite.modulate = Color.WHITE


func _on_died() -> void:
	_sprite.modulate = Color.WHITE
	_sprite.play("death")
	EventBus.play_sfx.emit("vehicon_death")
	await _sprite.animation_finished
	queue_free()
