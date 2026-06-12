# cooldown_manager.gd
# Centraliza el seguimiento del cooldown de transformación del jugador
# y emite actualizaciones al HUD a través del EventBus.
# SRP: única responsabilidad es leer el estado del componente de transformación
#      y traducirlo a señales que el HUD pueda consumir.
# DIP: depende de ITransformable (interfaz), no de implementaciones concretas.

class_name CooldownManager
extends Node

# ── Configuración ─────────────────────────────────────────────────────────────

## Frecuencia de actualización del HUD en segundos.
## 0.05 = 20 actualizaciones por segundo (suficiente para una barra suave).
@export_range(0.02, 0.2, 0.01) var update_interval: float = 0.05

# ── Estado ────────────────────────────────────────────────────────────────────

## Referencia al componente de transformación del personaje activo.
## Debe implementar ITransformable.
var _transform_component: Node = null

var _update_timer: float = 0.0

# ── Setup ─────────────────────────────────────────────────────────────────────

## Asigna el componente de transformación a monitorizar.
## Llamar desde game.tscn tras instanciar el personaje.
func setup(transform_component: Node) -> void:
	assert(
		transform_component.has_method("on_cooldown"),
		"CooldownManager: el componente no implementa ITransformable"
	)
	_transform_component = transform_component

# ── Proceso ───────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _transform_component == null:
		return

	_update_timer -= delta
	if _update_timer > 0.0:
		return

	_update_timer = update_interval
	_emit_cooldown_update()


func _emit_cooldown_update() -> void:
	var remaining: float = _transform_component.get_cooldown_remaining()
	var total: float = _transform_component.get_cooldown_duration()
	EventBus.transform_cooldown_updated.emit(remaining, total)
