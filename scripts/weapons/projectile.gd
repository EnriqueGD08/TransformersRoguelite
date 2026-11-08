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

# ── Efecto visual de impacto ──────────────────────────────────────────────────

## Efecto (OneShotEffect) que aparece al impactar. Vacío = sin efecto.
@export var impact_effect_scene: PackedScene

## Diámetro del efecto cuando el proyectil no tiene explosión de área.
@export_range(10.0, 200.0, 5.0) var impact_effect_diameter: float = 40.0

## Tinte del efecto de impacto (permite reutilizar un mismo efecto con otro color).
@export var impact_tint: Color = Color.WHITE

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

## Ondas expansivas (ej: Shockwave): radio inicial/final de la colisión.
var _wave_start: float = 0.0
var _wave_end: float = 0.0
var _wave_shape: CircleShape2D = null
var _wave_visual: Node2D = null

## Radio del arco dibujado en el arte a escala 1 (para escalar el sprite con la onda).
@export_range(1.0, 100.0, 0.5) var wave_art_radius: float = 21.0

## Nodos ya impactados (para proyectiles piercing, evitar doble daño).
var _hit_targets: Array = []

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var move: Vector2 = _direction * _speed * delta
	position += move
	_distance_traveled += move.length()

	if _wave_shape != null:
		_update_wave()
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

# ── Onda expansiva ────────────────────────────────────────────────────────────

## Convierte el proyectil en una onda cuya colisión y sprite crecen con la distancia.
## Duplica la forma de colisión para no modificar el recurso compartido de la escena.
func set_expanding_wave(start_radius: float, end_radius: float, _wave_range: float) -> void:
	_wave_start = start_radius
	_wave_end = end_radius
	for child in get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			_wave_shape = child.shape.duplicate()
			child.shape = _wave_shape
		elif child is AnimatedSprite2D or child is Sprite2D:
			_wave_visual = child
	_update_wave()


func _update_wave() -> void:
	var f: float = clampf(_distance_traveled / maxf(_max_range, 1.0), 0.0, 1.0)
	var radius: float = lerpf(_wave_start, _wave_end, f)
	_wave_shape.radius = radius
	if _wave_visual != null:
		_wave_visual.scale = Vector2.ONE * (radius / wave_art_radius)

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
		_spawn_impact_effect()
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
	# Usa la máscara del propio proyectil: los del jugador buscan enemigos (2) y los
	# enemigos buscan al jugador (1).
	query.collision_mask = collision_mask

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

# ── Efecto de impacto ─────────────────────────────────────────────────────────

func _spawn_impact_effect() -> void:
	if impact_effect_scene == null:
		return
	var effect: Node2D = impact_effect_scene.instantiate()
	ProjectileContainer.add(self, effect)
	effect.global_position = global_position
	effect.modulate = impact_tint
	if effect.has_method("fit_diameter"):
		# El efecto se dibuja algo más pequeño que el área real para no tapar la pantalla.
		effect.fit_diameter(_aoe_radius * 1.6 if _aoe_radius > 0.0 else impact_effect_diameter)

# ── Destrucción ───────────────────────────────────────────────────────────────

func _destroy() -> void:
	set_physics_process(false)
	queue_free()
