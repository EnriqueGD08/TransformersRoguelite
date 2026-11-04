# energon_manager.gd
# Gestiona el energon (moneda) del jugador durante la run.
# SRP: única responsabilidad es gestionar los drops físicos de energon en el
#      mundo. El SALDO vive en GameState (única fuente de verdad); este
#      manager solo lo consulta y delega las operaciones en él.
# DIP: escucha señales del EventBus; no depende de clases concretas.

class_name EnergonManager
extends Node

# ── Señales ───────────────────────────────────────────────────────────────────

# ── Configuración ─────────────────────────────────────────────────────────────

## Escena del pickup de energon que se instancia en el mundo al morir un enemigo.
@export var energon_pickup_scene: PackedScene

## Nodo padre donde se instancian los pickups (normalmente el nivel).
@export var pickup_parent: Node

## Radio de recolección automática del jugador en píxeles.
@export_range(20.0, 200.0, 5.0) var collect_radius: float = 60.0

# ── Estado ────────────────────────────────────────────────────────────────────

var _player: Node = null

# ── Setup ─────────────────────────────────────────────────────────────────────

func setup(player: Node) -> void:
	_player = player
	EventBus.energon_dropped.connect(_on_energon_dropped)

# ── API pública ───────────────────────────────────────────────────────────────

## Añade energon al saldo del jugador (delegado en GameState).
func add_energon(amount: int) -> void:
	GameState.add_energon(amount)


## Intenta gastar energon. Devuelve true si había suficiente saldo.
func spend_energon(amount: int) -> bool:
	return GameState.spend_energon(amount)


func get_current_energon() -> int:
	return GameState.current_energon

# ── Drops en el mundo ─────────────────────────────────────────────────────────

func _on_energon_dropped(position: Vector2, amount: int) -> void:
	if energon_pickup_scene == null:
		# Sin escena de pickup: recolección inmediata.
		add_energon(amount)
		return

	var pickup: Node = energon_pickup_scene.instantiate()
	var parent: Node = pickup_parent if pickup_parent else get_tree().current_scene
	parent.add_child(pickup)
	pickup.global_position = position

	if pickup.has_method("setup"):
		pickup.setup(amount, _player, collect_radius)

	if pickup.has_signal("collected"):
		pickup.collected.connect(_on_pickup_collected)


func _on_pickup_collected(amount: int) -> void:
	add_energon(amount)
