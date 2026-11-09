# energon_manager.gd
# Gestiona el energon (moneda) del jugador durante la run.
# SRP: única responsabilidad es gestionar los drops físicos de energon en el
#      mundo. El SALDO vive en GameState (única fuente de verdad); este
#      manager solo lo consulta y delega las operaciones en él.
# DIP: escucha señales del EventBus; no depende de clases concretas.

class_name EnergonManager
extends Node

## Grupo del nodo donde se cuelgan los cubos (World/Pickups en game.tscn).
const PARENT_GROUP := &"pickups"

# ── Configuración ─────────────────────────────────────────────────────────────

## Escena del cubo de energon que aparece al morir un enemigo.
@export var energon_pickup_scene: PackedScene

## Cantidad máxima por cubo: los drops grandes (jefes) se reparten en varios.
@export_range(1, 200, 1) var max_amount_per_pickup: int = 25

## Número máximo de cubos por drop.
@export_range(1, 50, 1) var max_pickups_per_drop: int = 12

# ── Estado ────────────────────────────────────────────────────────────────────

var _player: Node2D = null

# ── Setup ─────────────────────────────────────────────────────────────────────

func setup(player: Node2D) -> void:
	_player = player
	EventBus.energon_dropped.connect(_on_energon_dropped)
	EventBus.wave_completed.connect(_on_wave_completed)

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
	if amount <= 0:
		return
	if energon_pickup_scene == null:
		# Sin escena de pickup: recolección inmediata.
		add_energon(amount)
		return
	for piece in _split(amount):
		_spawn_pickup(position, piece)


## Reparte [param amount] en trozos sin perder ni un punto de energon.
func _split(amount: int) -> Array[int]:
	var pieces: int = clampi(ceili(float(amount) / max_amount_per_pickup), 1, max_pickups_per_drop)
	var result: Array[int] = []
	for i in pieces:
		result.append(amount / pieces + (1 if i < amount % pieces else 0))
	return result


func _spawn_pickup(position: Vector2, amount: int) -> void:
	var pickup: Node2D = energon_pickup_scene.instantiate()
	var parent: Node = get_tree().get_first_node_in_group(PARENT_GROUP)
	if parent == null:
		parent = get_parent()
	parent.add_child(pickup)
	pickup.global_position = position
	pickup.reset_physics_interpolation()
	pickup.setup(amount, _player)
	pickup.collected.connect(add_energon)


## Al terminar la oleada los cubos que queden vuelan hacia el personaje: el energon
## ganado no se pierde por no haber pasado por encima.
func _on_wave_completed(_wave_number: int) -> void:
	for pickup in get_tree().get_nodes_in_group(EnergonPickup.GROUP):
		pickup.attract()
