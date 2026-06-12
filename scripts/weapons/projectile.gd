# projectile.gd
# Proyectil instanciado por armas a distancia.
# SRP: única responsabilidad es moverse, detectar colisiones y aplicar daño.
#      No conoce al personaje que lo disparó, solo sus datos de impacto.
# OCP: el comportamiento se configura mediante setup(); no hay subclases
#      para cada tipo de proyectil, los datos determinan el comportamiento.

class_name Projectile
extends Area2D

# ── Señales ───────────────────────────────────────────────────────────────────

## Emitida al impactar con un enemigo.
## [param target] Nodo del enemigo. [param damage] Daño aplicado.
signal impacted(target: Node, damage: float)

# ── Configuración (asignada por el arma al instanciar) ────────────────────────

var _direction: Vector2 = Vector2.RIGHT
var _speed: float = 400.0
var _damage: float = 20.0
var _aoe_radius: float = 0.0
var _piercing: bool = false
var _status_effect: String = ""
var _status_chance: float = 0.0
var _status_duration: float = 0.0

## Distancia máxima recorrida antes de destruirse (en píxeles).
var _max_range: float = 800.0
var _distance_traveled: float = 0.0

## Nodos ya impactados (para proyectiles piercing, evitar doble daño).
var _hit_targets: Array = []

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var move: Vector2 = _direction * _speed * delta
	position += move
	_distance_traveled += move.length()

	if _distance_traveled >= _max_range:
		_destroy()

# ── Setup ─────────────────────────────────────────────────────────────────────

## Inicializa el proyectil con todos sus parámetros de vuelo e impacto.
## Llamar inmediatamente después de instanciar, antes del primer frame.
func setup(
	direction: Vector2,
	speed: float,
	damage: float,
	max_range: float,
	aoe_radius: float = 0.0,
	piercing: bool = false,
	status_effect: String = "",
	status_chance: float = 0.0,
	status_duration: float = 0.0
) -> void:
	_direction = direction.normalized()
	_speed = speed
	_damage = damage
	_max_range = max_range
	_aoe_radius = aoe_radius
	_piercing = piercing
	_status_effect = status_effect
	_status_chance = status_chance
	_status_duration = status_duration

	# Rota el sprite en la dirección de vuelo.
	rotation = _direction.angle()

# ── Impacto ───────────────────────────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
	if body in _hit_targets:
		return

	if not body.has_method("take_damage"):
		return

	_hit_targets.append(body)

	if _aoe_radius > 0.0:
		_apply_aoe_damage()
	else:
		_apply_direct_damage(body)

	if not _piercing:
		_destroy()


func _apply_direct_damage(target: Node) -> void:
	target.take_damage(_damage)
	_try_apply_status(target)
	impacted.emit(target, _damage)


func _apply_aoe_damage() -> void:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = _aoe_radius
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 2  # capa de enemigos

	for result in space_state.intersect_shape(query):
		var body: Node = result.collider
		if body.has_method("take_damage"):
			var dist: float = global_position.distance_to(body.global_position)
			# Daño decreciente con la distancia al centro de la explosión.
			var falloff: float = 1.0 - clampf(dist / _aoe_radius, 0.0, 1.0)
			var aoe_dmg: float = _damage * (0.4 + 0.6 * falloff)
			body.take_damage(aoe_dmg)
			_try_apply_status(body)
			impacted.emit(body, aoe_dmg)


func _try_apply_status(target: Node) -> void:
	if _status_effect.is_empty() or _status_chance <= 0.0:
		return
	if randf() > _status_chance:
		return
	if target.has_method("apply_status"):
		target.apply_status(_status_effect, _status_duration)

# ── Destrucción ───────────────────────────────────────────────────────────────

func _destroy() -> void:
	set_physics_process(false)
	queue_free()
