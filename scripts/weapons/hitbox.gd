# hitbox.gd
# Zona de golpe para armas melee.
# SRP: única responsabilidad es activarse durante el tiempo de golpe,
#      detectar enemigos en el arco y notificar al arma propietaria.
# Se instancia como nodo hijo de cada arma melee.
# El arma lo activa llamando a activate(); se desactiva solo tras hit_duration.

class_name Hitbox
extends Area2D

# ── Señales ───────────────────────────────────────────────────────────────────

## Emitida por cada enemigo alcanzado durante el golpe.
## [param target] Nodo del enemigo. [param damage] Daño calculado por el arma.
signal enemy_hit(target: Node, damage: float)

# ── Estado ────────────────────────────────────────────────────────────────────

var _active: bool = false
var _damage: float = 0.0
var _hit_targets: Array = []  # evita aplicar daño dos veces en el mismo swing

@onready var _hit_timer: Timer = $HitTimer
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_hit_timer.one_shot = true
	_hit_timer.timeout.connect(_on_hit_timer_expired)
	monitoring = false
	body_entered.connect(_on_body_entered)

# ── API pública ───────────────────────────────────────────────────────────────

## Activa el hitbox durante [param duration] segundos con [param damage] de daño.
## El arma melee llama a esto en cada _perform_attack().
func activate(damage: float, duration: float) -> void:
	_damage = damage
	_hit_targets.clear()
	monitoring = true
	_active = true
	_hit_timer.start(duration)


## Desactiva el hitbox manualmente (por ejemplo, al morir el personaje).
func deactivate() -> void:
	monitoring = false
	_active = false
	_hit_timer.stop()
	_hit_targets.clear()

# ── Detección ─────────────────────────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
	if not _active:
		return
	if body in _hit_targets:
		return
	if not body.has_method("take_damage"):
		return

	_hit_targets.append(body)
	body.take_damage(_damage)
	enemy_hit.emit(body, _damage)

# ── Callback ──────────────────────────────────────────────────────────────────

func _on_hit_timer_expired() -> void:
	deactivate()
