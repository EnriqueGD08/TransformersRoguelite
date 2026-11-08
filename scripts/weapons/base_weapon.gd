# base_weapon.gd
# Clase base de todas las armas del juego.
# SRP: gestiona el cooldown de disparo y expone los datos del arma.
#      La lógica concreta de disparo (proyectil vs hitbox) va en las subclases.
# OCP: nuevas armas extienden esta clase sin modificarla.
# LSP: cualquier subclase puede usarse donde se espere BaseWeapon.
# DIP: recibe WeaponStats como Resource, no hardcodea valores.

class_name BaseWeapon
extends Node2D

# ── Dependencias ──────────────────────────────────────────────────────────────

## Resource con los datos del arma. Asignado desde el Inspector.
@export var stats: WeaponStats

## Segundos entre pulsar y que salga el disparo, para que el proyectil aparezca
## con el fogonazo de la animación. Solo en modo robot: transformado es inmediato.
@export_range(0.0, 1.0, 0.01) var windup_seconds: float = 0.0

## Referencia al personaje propietario.
## Se asigna automáticamente en _ready() buscando el padre BaseCharacter.
var _owner_character: BaseCharacter = null

# ── Señales ───────────────────────────────────────────────────────────────────

## Emitida cada vez que el arma dispara o golpea.
signal fired()

## Emitida cuando el arma impacta a un enemigo.
## [param target] Nodo del enemigo impactado.
## [param damage] Daño aplicado.
signal hit(target: Node, damage: float)

# ── Estado interno ────────────────────────────────────────────────────────────

var _can_fire: bool = true

@onready var _fire_timer: Timer = $FireTimer

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	assert(stats != null, "BaseWeapon: stats no asignado en " + name)
	# Copia propia: upgrade_stat no debe modificar el .tres compartido.
	stats = stats.duplicate()

	_owner_character = _find_owner_character()

	_fire_timer.one_shot = true
	_fire_timer.wait_time = stats.fire_rate
	_fire_timer.timeout.connect(_on_fire_timer_expired)

	_on_weapon_ready()


## Hook para inicialización adicional en subclases.
func _on_weapon_ready() -> void:
	pass


## Busca el BaseCharacter más cercano en el árbol de padres.
func _find_owner_character() -> BaseCharacter:
	var node: Node = get_parent()
	while node != null:
		if node is BaseCharacter:
			return node
		node = node.get_parent()
	push_error("BaseWeapon: no se encontró BaseCharacter en los padres de " + name)
	return null

# ── IWeapon ───────────────────────────────────────────────────────────────────

## Dispara el arma si está disponible.
## Inicia el cooldown y delega la lógica concreta a _perform_attack().
func fire() -> void:
	if not _can_fire:
		return

	_can_fire = false
	_fire_timer.start(stats.fire_rate)

	_perform_attack()
	fired.emit()
	EventBus.play_sfx.emit(stats.weapon_id + "_fire")


## Devuelve true si el arma puede disparar en este momento.
func can_fire() -> bool:
	return _can_fire


## Devuelve el Resource de estadísticas del arma.
func get_stats() -> Resource:
	return stats


## Aplica una mejora a un stat del arma en tiempo de ejecución.
## Modifica el Resource directamente (cada arma tiene su propia instancia).
func upgrade_stat(stat_name: String, value: float) -> void:
	if not stat_name in stats:
		push_error("BaseWeapon: stat '%s' no existe en WeaponStats" % stat_name)
		return
	var new_value: float = stats.get(stat_name) + value
	# Límites razonables para que las mejoras no rompan el juego.
	match stat_name:
		"fire_rate":
			new_value = maxf(new_value, 0.08)
		"crit_chance":
			new_value = minf(new_value, 1.0)
	stats.set(stat_name, new_value)

# ── Cálculo de daño ───────────────────────────────────────────────────────────

## Calcula el daño final de un ataque, incluyendo críticos y modificadores
## del personaje propietario.
func _calculate_damage() -> float:
	var base: float = stats.damage
	if _owner_character:
		base += _owner_character.get_damage() - _owner_character.stats.base_damage

	if randf() < stats.crit_chance:
		base *= stats.crit_multiplier

	return base

# ── Hook de ataque ────────────────────────────────────────────────────────────

## Las subclases implementan aquí su lógica concreta de ataque.
## Melee: activa el hitbox. Ranged: instancia un proyectil.
func _perform_attack() -> void:
	push_error("_perform_attack() no implementado en: " + get_script().resource_path)


## Espera el tiempo de preparación del disparo.
## Devuelve false si el personaje ha muerto entretanto (el disparo se cancela).
func _wait_windup() -> bool:
	if windup_seconds <= 0.0 or _owner_character == null or _owner_character.is_transformed():
		return true
	await get_tree().create_timer(windup_seconds, false).timeout
	return is_instance_valid(_owner_character) and _owner_character.is_alive()

# ── Callbacks ─────────────────────────────────────────────────────────────────

func _on_fire_timer_expired() -> void:
	_can_fire = true
