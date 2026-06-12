# damage_calculator.gd
# Centraliza toda la lógica de cálculo de daño del juego.
# SRP: única responsabilidad es calcular cuánto daño aplica un ataque,
#      teniendo en cuenta stats del atacante, del defensor y modificadores.
#      No aplica el daño — eso lo hace IDamageable.take_damage().
# DIP: recibe interfaces IDamageable/IAttackable; no conoce clases concretas.
# Stateless: todos los métodos son estáticos para no requerir instancia.

class_name DamageCalculator
extends Node

# ── Cálculo principal ─────────────────────────────────────────────────────────

## Calcula el daño final que un atacante inflige a un defensor.
## Aplica: daño base + modificadores del atacante - reducción del defensor.
## [param raw_damage] Daño base antes de cualquier modificador.
## [param attacker] Nodo atacante (puede ser null si es un sistema).
## [param defender] Nodo defensor que recibirá el daño.
## Devuelve el daño final ya ajustado, mínimo 1.0.
static func calculate(raw_damage: float, attacker: Node, defender: Node) -> float:
	var damage: float = raw_damage

	# Aplica bonificaciones del atacante si las expone.
	if attacker and attacker.has_method("get_damage"):
		# El atacante ya aplicó sus modificadores en get_damage();
		# raw_damage viene de ahí, así que no lo aplicamos dos veces.
		pass

	# Aplica reducción de daño del defensor.
	damage = _apply_defense(damage, defender)

	# El daño mínimo siempre es 1.0 para que siempre haya consecuencia.
	return maxf(damage, 1.0)


## Calcula el daño de un golpe crítico sobre un daño base ya calculado.
## [param base_damage] Daño antes del crítico.
## [param crit_multiplier] Multiplicador de crítico (ej: 1.5, 2.0).
static func apply_crit(base_damage: float, crit_multiplier: float) -> float:
	return base_damage * crit_multiplier


## Calcula el daño de área con caída por distancia (falloff).
## El daño máximo se aplica en el centro; cae linealmente hasta el borde.
## [param base_damage] Daño en el centro de la explosión.
## [param distance] Distancia del objetivo al centro.
## [param max_radius] Radio máximo del área.
## [param min_damage_ratio] Porcentaje mínimo del daño en el borde (0.0-1.0).
static func calculate_aoe_falloff(
	base_damage: float,
	distance: float,
	max_radius: float,
	min_damage_ratio: float = 0.3
) -> float:
	if max_radius <= 0.0:
		return base_damage
	var t: float = clampf(distance / max_radius, 0.0, 1.0)
	var ratio: float = lerpf(1.0, min_damage_ratio, t)
	return base_damage * ratio


## Calcula el daño de un efecto de estado por tick.
## [param base_hp] HP máximo del defensor (para efectos porcentuales).
## [param effect] Tipo de efecto ("burn", "bleed", "poison").
## [param tick_interval] Intervalo del tick en segundos.
static func calculate_status_tick(
	base_hp: float,
	effect: String,
	tick_interval: float
) -> float:
	match effect:
		"burn":
			return base_hp * 0.02 * tick_interval
		"bleed":
			return base_hp * 0.01 * tick_interval
		"poison":
			return base_hp * 0.015 * tick_interval
	return 0.0

# ── Defensa ───────────────────────────────────────────────────────────────────

static func _apply_defense(damage: float, defender: Node) -> float:
	if defender == null:
		return damage

	# Intenta leer la reducción de daño del defensor.
	var reduction: float = 0.0
	if defender.has_method("get_damage_reduction"):
		reduction = defender.get_damage_reduction()
	elif defender is BaseCharacter:
		reduction = defender.stats.damage_reduction
		if defender.is_transformed():
			reduction *= defender.stats.transform_defense_multiplier
		reduction += defender._get_modifier("damage_reduction")

	reduction = clampf(reduction, 0.0, 0.9)
	return damage * (1.0 - reduction)
