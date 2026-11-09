# shop_item_data.gd
# Resource que define un objeto de la tienda.
# SRP: contiene los datos de un objeto (nombre, precio, efecto) y sabe aplicarse al
#      personaje. No gestiona saldo ni compras: eso lo hace ShopManager.
# OCP: un objeto nuevo es una entrada más en el catálogo (.tres); no se toca ningún script.

class_name ShopItemData
extends Resource

# ── Identificación ────────────────────────────────────────────────────────────

## ID único dentro del catálogo (ej: "hp", "lifesteal").
@export var id: String = ""

## Nombre visible en la tienda.
@export var display_name: String = ""

## Descripción del efecto que se muestra al seleccionar el objeto.
@export_multiline var description: String = ""

## Icono del objeto.
@export var icon: Texture2D

# ── Efecto ────────────────────────────────────────────────────────────────────

## "stat": mejora numérica que se puede comprar varias veces.
## "passive": habilidad especial, se compra una sola vez.
@export_enum("stat", "passive") var kind: String = "stat"

## Nombre del modificador de estadística (los mismos que usa el árbol de habilidades:
## max_hp, base_damage, move_speed, dodge_chance...). Solo para kind = "stat".
@export var target_stat: String = ""

## Cantidad que se suma en cada compra (delta, no multiplicador). Solo para "stat".
@export var effect_value: float = 0.0

## ID de la pasiva (lifesteal, last_stand, kill_cdr...). Solo para kind = "passive".
@export var passive_id: String = ""

# ── Precio ────────────────────────────────────────────────────────────────────

## Precio de la primera compra, en energon.
@export_range(1, 2000, 1) var base_price: int = 40

## Lo que sube el precio con cada compra ya hecha (precio = base + paso × compras).
@export_range(0, 500, 1) var price_step: int = 20

## Cuántas veces se puede comprar en una partida.
@export_range(1, 20, 1) var max_purchases: int = 5

# ── API ───────────────────────────────────────────────────────────────────────

## Precio de la siguiente compra, sabiendo cuántas se han hecho ya.
func get_price(purchases: int) -> int:
	return base_price + price_step * purchases


## Aplica el efecto de UNA compra al personaje.
func apply(character: Node) -> void:
	match kind:
		"stat":
			if target_stat.is_empty():
				push_error("ShopItemData: target_stat vacío en '%s'" % id)
			elif character.has_method("add_stat_modifier"):
				character.add_stat_modifier(target_stat, effect_value)
		"passive":
			if passive_id.is_empty():
				push_error("ShopItemData: passive_id vacío en '%s'" % id)
			else:
				# Las pasivas se activan por EventBus; PassiveAbilities las implementa.
				EventBus.passive_activated.emit(passive_id)
