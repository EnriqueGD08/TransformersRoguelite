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

## Rutas de los SpriteFrames de cada skin. Son rutas (no recursos) para cargar solo la
## skin que se usa: cada una ocupa decenas de MB de textura.
@export_file("*.tres") var skin_frames_g1: String
@export_file("*.tres") var skin_frames_prime: String
@export_file("*.tres") var skin_frames_bay: String

## Skin con la que empieza. Vacío = la de CharacterStats. Asignar antes de añadir al árbol.
var initial_skin: String = ""

## Multiplicador de velocidad de la animación de caminar, para que los pies no parezcan
## resbalar con la velocidad a la que se desplaza el personaje.
@export_range(0.5, 3.0, 0.05) var walk_speed_scale: float = 1.0

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

## Veces que puede revivir al morir (la pasiva "last_stand" suma una).
var _revive_charges: int = 0

## Referencia al componente de transformación (ITransformable).
## Se asigna en _ready() de cada subclase mediante _setup_transform_component().
var _transform_component: Node = null

## Referencia al componente de skin (ISkinProvider).
var _skin_manager: Node = null

## Si es true el personaje no se desplaza (ej: Shockwave como cañón láser),
## pero sigue vivo, apuntando y recibiendo daño.
var _movement_locked: bool = false

## Referencia al AnimatedSprite2D del personaje.
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

## Timer de regeneración de HP.
@onready var _regen_timer: Timer = $RegenTimer

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	assert(stats != null, "BaseCharacter: stats no asignado en " + name)
	# Copia propia: las mejoras del árbol no deben modificar el .tres compartido.
	stats = stats.duplicate()
	_current_hp = stats.max_hp
	_setup_components()
	_setup_regen_timer()
	_on_ready()
	_emit_hp_changed()
	if _transform_component != null:
		EventBus.transform_cooldown_updated.emit(0.0, _transform_component.get_cooldown_duration())


## Hook para que las subclases ejecuten lógica adicional en _ready()
## sin necesidad de llamar a super._ready() explícitamente.
## OCP: la base no se modifica; las subclases extienden mediante este hook.
func _on_ready() -> void:
	pass


func _process(_delta: float) -> void:
	# El HUD muestra el cooldown de la transformación mientras se recarga.
	if _transform_component != null and _transform_component.on_cooldown():
		EventBus.transform_cooldown_updated.emit(
			_transform_component.get_cooldown_remaining(),
			_transform_component.get_cooldown_duration()
		)


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

# ── API visual pública ────────────────────────────────────────────────────────
# Las armas y componentes usan estos métodos en lugar de tocar _sprite (privado).

## Cambia la skin visual (g1, prime, bay). No afecta a la lógica de juego.
func set_skin(skin_id: String) -> void:
	if _skin_manager != null:
		_skin_manager.set_skin(skin_id)


## Reproduce una animación del sprite si existe en la skin actual.
## En modo transformado prefiere la variante "transform_<nombre>" (camión, moto...).
## [param backwards] reproduce la animación al revés (ej: volver a modo robot).
func play_animation(anim_name: StringName, backwards: bool = false) -> void:
	# Atacar no corta la transformación: si no, con el botón pulsado nunca se vería.
	if String(anim_name).begins_with("attack") and _sprite.animation == &"transform_activate" and _sprite.is_playing():
		return
	var resolved: StringName = _resolve_animation(anim_name)
	if resolved == &"":
		return
	_sprite.speed_scale = 1.0
	if backwards:
		_sprite.play_backwards(resolved)
	else:
		# Si ya sonaba (disparos más rápidos que la animación), vuelve a empezar.
		if _sprite.animation == resolved:
			_sprite.frame = 0
		_sprite.play(resolved)


## Devuelve la animación a usar para [param base_name] según el modo actual.
## Si no existe ni la variante ni la base devuelve "" (no se reproduce nada).
func _resolve_animation(base_name: StringName) -> StringName:
	if _sprite.sprite_frames == null:
		return &""
	var frames: SpriteFrames = _sprite.sprite_frames
	# Atacar en movimiento: si existe, usa la variante con las piernas caminando.
	if String(base_name).begins_with("attack") and not _is_transformed and velocity.length() > 1.0 \
			and frames.has_animation("walk_" + base_name):
		return StringName("walk_" + base_name)
	if _is_transformed:
		if frames.has_animation("transform_" + base_name):
			return StringName("transform_" + base_name)
		# Variantes (ej: "attack_finisher") caen en la animación general del modo.
		var family: String = String(base_name).get_slice("_", 0)
		if frames.has_animation("transform_" + family):
			return StringName("transform_" + family)
	if frames.has_animation(base_name):
		return base_name
	return &""


## Alterna idle/walk (y sus variantes transformadas) según el movimiento.
## No interrumpe animaciones puntuales (ataque, transformación, muerte).
func _update_move_animation(direction: Vector2) -> void:
	if not _is_alive:
		return
	var current: String = String(_sprite.animation)
	# Solo alterna entre variantes de reposo/caminar (idle, ranged_walk, transform_idle...).
	if not (current.ends_with("idle") or current.ends_with("walk")):
		return
	var target: StringName = _resolve_animation(&"walk" if direction != Vector2.ZERO else &"idle")
	if target != &"" and target != _sprite.animation:
		_sprite.play(target)
		_sprite.speed_scale = walk_speed_scale if String(target).ends_with("walk") else 1.0


## Suma cargas de resurrección (pasiva "Última resistencia").
func add_revive_charge(amount: int = 1) -> void:
	_revive_charges += amount


## Imágenes (SpriteFrames) de la skin actual, para pantallas que muestran al personaje.
func get_skin_frames() -> SpriteFrames:
	return _sprite.sprite_frames if _sprite != null else null


## True si el personaje tiene dos armas entre las que cambiar (la interfaz táctil muestra
## el botón de cambio solo entonces). Por defecto no; Arcee lo sobrescribe.
func supports_weapon_swap() -> bool:
	return false


## Devuelve el componente de transformación (para mejoras específicas de cada una).
func get_transform_component() -> Node:
	return _transform_component


## Reduce el cooldown de la transformación (pasiva: cada baja acorta la recarga).
func reduce_transform_cooldown(seconds: float) -> void:
	if _transform_component != null and _transform_component.has_method("reduce_cooldown"):
		_transform_component.reduce_cooldown(seconds)


## Bloquea o libera el desplazamiento del personaje.
func set_movement_locked(locked: bool) -> void:
	_movement_locked = locked


func is_movement_locked() -> bool:
	return _movement_locked


## Rotación actual del sprite (radianes). Los componentes que dependen de la
## orientación visual (ej: la boca del cañón de Shockwave) la consultan aquí.
func get_visual_rotation() -> float:
	return _sprite.rotation


## True si el personaje mira a la izquierda.
func is_facing_left() -> bool:
	return _sprite.flip_h


func _on_animation_finished() -> void:
	if _is_alive:
		play_animation(&"idle")

# ── Configuración de componentes ──────────────────────────────────────────────

## Inicializa los componentes del personaje.
## Cada subclase debe llamar a _setup_transform_component() y
## _setup_skin_manager() con sus implementaciones concretas.
func _setup_components() -> void:
	_skin_manager = $SkinManager
	var paths: Dictionary = {}
	for skin_id: String in ["g1", "prime", "bay"]:
		var path: String = get("skin_frames_" + skin_id)
		if not path.is_empty():
			paths[skin_id] = path
	_skin_manager.setup(_sprite, paths, stats.available_skins)
	_skin_manager.set_skin(initial_skin if not initial_skin.is_empty() else stats.default_skin)
	# Al terminar una animación puntual (ataque, transformación) vuelve a idle.
	_sprite.animation_finished.connect(_on_animation_finished)


## Asigna el componente de transformación concreto.
## Llamar desde _on_ready() en cada subclase.
## DIP: recibe un Node que implementa ITransformable.
func _setup_transform_component(component: Node) -> void:
	_transform_component = component


func _setup_regen_timer() -> void:
	# El temporizador siempre corre: la regeneración puede activarla una habilidad
	# del árbol aunque el personaje no regenere de base.
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
	_emit_hp_changed()

	if _current_hp <= 0.0:
		# Pasiva "Última resistencia": revive una vez con la mitad de la vida.
		if _revive_charges > 0:
			_revive_charges -= 1
			_current_hp = get_max_hp() * 0.5
			_emit_hp_changed()
			EventBus.play_sfx.emit("revive")
			return
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

## Radio de atracción del energon (base + mejoras del árbol).
func get_pickup_radius() -> float:
	return stats.pickup_radius + _get_modifier("pickup_radius")


## Regeneración de vida por segundo (base + mejoras del árbol).
func get_regen() -> float:
	return stats.hp_regen_per_second + _get_modifier("hp_regen_per_second")


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
	EventBus.transform_cooldown_updated.emit(0.0, _transform_component.get_cooldown_duration())


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
	# Subir la vida máxima también cura esa cantidad (si no, la barra quedaría "vacía").
	if stat_name == "max_hp" and delta > 0.0 and _is_alive:
		_current_hp += delta
		_emit_hp_changed()


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
	_emit_hp_changed()

# ── Privados ──────────────────────────────────────────────────────────────────

## Emite el cambio de HP localmente y por EventBus (lo escucha el HUD).
func _emit_hp_changed() -> void:
	hp_changed.emit(_current_hp, get_max_hp())
	EventBus.player_hp_changed.emit(_current_hp, get_max_hp())


func _try_dodge() -> bool:
	var chance: float = minf(stats.dodge_chance + _get_modifier("dodge_chance"), 0.75)
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
	var regen: float = get_regen()
	if regen > 0.0:
		heal(regen)
