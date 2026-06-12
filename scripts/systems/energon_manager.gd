# energon_manager.gd
# Gestiona el energon (moneda) del jugador durante la run.
# SRP: única responsabilidad es rastrear el saldo de energon y
#      gestionar los drops físicos en el mundo.
# DIP: escucha señales del EventBus; no depende de clases concretas.

class_name EnergonManager
extends Node

# ── Señales ───────────────────────────────────────────────────────────────────

signal energon_changed(current: int)

# ── Configuración ─────────────────────────────────────────────────────────────

## Escena del pickup de energon que se instancia en el mundo al morir un enemigo.
@export var energon_pickup_scene: PackedScene

## Nodo padre donde se instancian los pickups (normalmente el nivel).
@export var pickup_parent: Node

## Radio de recolección automática del jugador en píxeles.
@export_range(20.0, 200.0, 5.0) var collect_radius: float = 60.0

# ── Estado ────────────────────────────────────────────────────────────────────

var _current_energon: int = 0
var _player: Node = null

# ── Setup ─────────────────────────────────────────────────────────────────────

func setup(player: Node, starting_energon: int) -> void:
	_player = player
	_current_energon = starting_energon

	EventBus.energon_dropped.connect(_on_energon_dropped)
	EventBus.energon_collected.connect(_on_energon_collected)

	energon_changed.emit(_current_energon)
	EventBus.player_energon_changed.emit(_current_energon)

# ── API pública ───────────────────────────────────────────────────────────────

## Añade energon al saldo del jugador.
func add_energon(amount: int) -> void:
	_current_energon += amount
	_notify_change()


## Intenta gastar energon. Devuelve true si había suficiente saldo.
func spend_energon(amount: int) -> bool:
	if _current_energon < amount:
		return false
	_current_energon -= amount
	_notify_change()
	return true


func get_current_energon() -> int:
	return _current_energon

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


func _on_energon_collected(amount: int, _total: int) -> void:
	# Recolección directa sin pickup físico (bonus de oleada).
	add_energon(amount)

# ── Privados ──────────────────────────────────────────────────────────────────

func _notify_change() -> void:
	energon_changed.emit(_current_energon)
	EventBus.player_energon_changed.emit(_current_energon)
