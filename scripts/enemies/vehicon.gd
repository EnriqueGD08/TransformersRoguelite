# vehicon.gd
# Enemigo: Vehicon.
# Soldado básico de los Decepticons. Melee, persigue al jugador directamente.
# HP bajo, velocidad media, daño bajo. Peligroso en grupos.
# OCP: extiende BaseEnemy; las animaciones y el destello de daño ya los hace la base.

class_name Vehicon
extends BaseEnemy


func _on_died() -> void:
	_sprite.modulate = Color.WHITE
	EventBus.play_sfx.emit("vehicon_death")
	super._on_died()
