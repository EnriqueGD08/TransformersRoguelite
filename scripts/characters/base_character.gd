# base_character.gd
# Clase base de todos los personajes jugables.
# SRP: gestiona el ciclo de vida del personaje (HP, muerte, señales).
#      La lógica de movimiento, ataque y transformación se delega
#      a componentes que implementan sus respectivas interfaces.
# OCP: los personajes concretos extienden esta clase y sobrescriben
#      solo lo que necesitan, sin modificar esta base.
# LSP: cualquier subclase puede usarse donde se espere BaseCharacter.

class_name BaseCharacter
extends CharacterBody2D

# ── Dependencias ──────────────────────────────────────────────────────────────

## Resource con todos los datos base del personaje.
## Se asigna desde el Inspector o desde la escena concreta del personaje.
@export var stats: CharacterStats

# ── Señales ───────────────────────────────────────────────────────────────────

## Emitida cuando el personaje recibe daño.
## [param amount] Daño recibido tras aplicar reducciones.
## [param current_hp] HP restante tras el golpe.
signal damaged(amount: float, current_hp: float)

## Emitida cuando el HP cambia por cualquier motivo (daño o curación).
## [param current_hp] HP actual. [param max_hp] HP máximo.
signal hp_changed(current_hp: float, max_hp: float)

## Emitida cuando el personaje muere (HP llega a 0).
signal died()

## Emitida cuando la transformación se activa.
signal transform_activated()

## Emitida cuando la transformación se desactiva.
signal transform_deactivated()

## Emitida cuando el cooldown de transformación termina y está disponible.
signal transform_ready()

# ── Estado interno ────────────────────────────────────────────────────────────

var _current_hp: float = 0.0
var _is_alive: bool = true
var _is_transformed: bool = false

## Modificadores acumulados por el árbol de habilidades.
## Clave: nombre del stat (ej: "damage", "speed"). Valor: delta acumulado.
var _stat_modifiers: Dictionary = {}

## Referencia al componente de transformación (ITransformable).
## Se asigna en _ready() de cada subclase mediante _setup_transform_component().
var _transform_component: Node = null

## Referencia al componente de skin (ISkinProvider).
var _skin_manager: Node = null

## Referencia al AnimatedSprite2D del personaje.
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

## Timer de regeneración de HP.
@onready var _regen_timer: Timer = $RegenTimer

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	assert(stats != null, "BaseCharacter: stats no asignado en " + name)
	_current_hp = stats.max_hp
	_setup_components()
	_setup_regen_timer()
	_on_ready()


## Hook para que las subclases ejecuten lógica adicional en _ready()
## sin necesidad de llamar a super._ready() explícitamente.
## OCP: la base no se modifica; las subclases extienden mediante este hook.
func _on_ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	if not _is_alive:
		return
	_process_movement(delta)
	_process_attack(delta)


## Hook de movimiento. Las subclases implementan su lógica aquí.
func _process_movement(_delta: float) -> void:
	pass


## Hook de ataque. Las subclases implementan su lógica aquí.
func _process_attack(_delta: float) -> void:
	pass

# ── Configuración de componentes ──────────────────────────────────────────────

## Inicializa los componentes del personaje.
## Cada subclase debe llamar a _setup_transform_component() y
## _setup_skin_manager() con sus implementaciones concretas.
func _setup_components() -> void:
	_skin_manager = $SkinManager
	if _skin_manager:
		_skin_manager.set_skin(stats.default_skin)


## Asigna el componente de transformación concreto.
## Llamar desde _on_ready() en cada subclase.
## DIP: recibe un Node que implementa ITransformable.
func _setup_transform_component(component: Node) -> void:
	_transform_component = component


func _setup_regen_timer() -> void:
	if stats.hp_regen_per_second <= 0.0:
		return
	_regen_timer.wait_time = 1.0
	_regen_timer.autostart = true
	_regen_timer.timeout.connect(_on_regen_tick)

# ── IDamageable ───────────────────────────────────────────────────────────────

## Aplica daño al personaje, respetando reducción y esquiva.
## Emite hp_changed y damaged. Si HP llega a 0, llama a _die().
func take_damage(amount: float) -> void:
	if not _is_alive:
		return

	if _try_dodge():
		return

	var reduced: float = _calculate_damage_reduction(amount)
	_current_hp = maxf(_current_hp - reduced, 0.0)

	damaged.emit(reduced, _current_hp)
	hp_changed.emit(_current_hp, get_max_hp())

	if _current_hp <= 0.0:
		_die()


func is_alive() -> bool:
	return _is_alive


func get_current_hp() -> float:
	return _current_hp


func get_max_hp() -> float:
	var base: float = stats.max_hp
	if _is_transformed:
		base *= stats.transform_hp_multiplier
	return base + _get_modifier("max_hp")

# ── IMovable (datos) ──────────────────────────────────────────────────────────

## Devuelve la velocidad de movimiento actual con modificadores aplicados.
func get_speed() -> float:
	var base: float = stats.move_speed
	if _is_transformed:
		base *= stats.transform_speed_multiplier
	return base + _get_modifier("move_speed")

# ── IAttackable (datos) ───────────────────────────────────────────────────────

## Devuelve el daño base actual con modificadores aplicados.
func get_damage() -> float:
	var base: float = stats.base_damage
	if _is_transformed:
		base *= stats.transform_damage_multiplier
	return base + _get_modifier("base_damage")


func get_attack_range() -> float:
	return stats.attack_range + _get_modifier("attack_range")

# ── Transformación ────────────────────────────────────────────────────────────

## Solicita la activación de la transformación al componente delegado.
## Si no hay componente asignado o está en cooldown, no hace nada.
func request_transform() -> void:
	if _transform_component == null:
		push_warning("BaseCharacter: sin componente de transformación en " + name)
		return
	if _transform_component.on_cooldown() or _transform_component.is_transformed():
		return
	_transform_component.transform_activate()


## Llamado por el componente de transformación cuando el modo se activa.
## Las subclases pueden sobreescribir _on_transform_activated() para
## efectos visuales o de audio adicionales.
func notify_transform_activated() -> void:
	_is_transformed = true
	transform_activated.emit()
	EventBus.transform_activated.emit(self)
	_on_transform_activated()


## Llamado por el componente de transformación cuando el modo se desactiva.
func notify_transform_deactivated() -> void:
	_is_transformed = false
	transform_deactivated.emit()
	EventBus.transform_deactivated.emit(self)
	_on_transform_deactivated()


## Llamado por el componente cuando el cooldown termina.
func notify_transform_ready() -> void:
	transform_ready.emit()
	EventBus.transform_cooldown_ready.emit(self)


func is_transformed() -> bool:
	return _is_transformed


## Hook visual/audio para subclases al activar transformación.
func _on_transform_activated() -> void:
	pass


## Hook visual/audio para subclases al desactivar transformación.
func _on_transform_deactivated() -> void:
	pass

# ── Sistema de modificadores (árbol de habilidades) ───────────────────────────

## Añade o acumula un modificador de stat por árbol de habilidades.
## [param stat_name] Nombre del stat (debe coincidir con el campo en stats).
## [param delta] Valor a sumar al stat base.
func add_stat_modifier(stat_name: String, delta: float) -> void:
	if _stat_modifiers.has(stat_name):
		_stat_modifiers[stat_name] += delta
	else:
		_stat_modifiers[stat_name] = delta


## Elimina un modificador previamente añadido.
func remove_stat_modifier(stat_name: String, delta: float) -> void:
	if not _stat_modifiers.has(stat_name):
		return
	_stat_modifiers[stat_name] -= delta


## Devuelve el modificador acumulado para un stat, o 0.0 si no existe.
func _get_modifier(stat_name: String) -> float:
	return _stat_modifiers.get(stat_name, 0.0)

# ── Curación ──────────────────────────────────────────────────────────────────

## Cura al personaje en [param amount] puntos de HP, sin superar el máximo.
func heal(amount: float) -> void:
	if not _is_alive:
		return
	_current_hp = minf(_current_hp + amount, get_max_hp())
	hp_changed.emit(_current_hp, get_max_hp())

# ── Privados ──────────────────────────────────────────────────────────────────

func _try_dodge() -> bool:
	var chance: float = stats.dodge_chance + _get_modifier("dodge_chance")
	return randf() < chance


func _calculate_damage_reduction(amount: float) -> float:
	var reduction: float = stats.damage_reduction
	if _is_transformed:
		reduction *= stats.transform_defense_multiplier
	reduction += _get_modifier("damage_reduction")
	reduction = clampf(reduction, 0.0, 0.9)
	return amount * (1.0 - reduction)


func _die() -> void:
	_is_alive = false
	_is_transformed = false
	died.emit()
	EventBus.character_died.emit(self)
	_on_died()


## Hook para que las subclases reaccionen a la muerte
## (animación, efectos, etc.) sin modificar la lógica base.
func _on_died() -> void:
	pass


func _on_regen_tick() -> void:
	if not _is_alive:
		return
	if _current_hp >= get_max_hp():
		return
	heal(stats.hp_regen_per_second)
