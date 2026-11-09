# shop_manager.gd
# Gestiona las compras de la tienda durante la run.
# SRP: comprueba saldo, cobra, aplica el efecto y recuerda cuántas veces se ha comprado
#      cada objeto. No dibuja nada (eso es ShopUI) ni guarda el saldo (vive en GameState).
# DIP: recibe el personaje y las pasivas por setup(); el catálogo es un Resource.
# OCP: nuevos objetos = nuevas entradas en el catálogo, sin tocar esta clase.

class_name ShopManager
extends Node

## Emitida tras cada compra con éxito (para que la pantalla se refresque).
signal item_bought(item_id: String)

## Catálogo de objetos a la venta.
@export var catalog: ShopCatalog

var _character: Node = null
var _passives: PassiveAbilities = null

## Compras hechas en esta run. Clave: id del objeto. Valor: veces comprado.
var _purchases: Dictionary = {}

# ── Setup ─────────────────────────────────────────────────────────────────────

## Inyección de dependencias. Llamar al empezar la partida.
func setup(character: Node, passives: PassiveAbilities) -> void:
	_character = character
	_passives = passives
	_purchases.clear()

# ── Consultas ─────────────────────────────────────────────────────────────────

func get_items() -> Array[ShopItemData]:
	if catalog == null:
		return []
	return catalog.items


func get_purchases(item: ShopItemData) -> int:
	return _purchases.get(item.id, 0)


## Precio de la próxima compra de [param item].
func get_price(item: ShopItemData) -> int:
	return item.get_price(get_purchases(item))


## True si ya no se puede comprar más: máximo alcanzado o pasiva ya activa
## (por ejemplo, desbloqueada antes en el árbol de habilidades).
func is_sold_out(item: ShopItemData) -> bool:
	if item.kind == "passive" and _passives != null and _passives.is_active(item.passive_id):
		return true
	return get_purchases(item) >= item.max_purchases


func can_afford(item: ShopItemData) -> bool:
	return GameState.current_energon >= get_price(item)


func can_buy(item: ShopItemData) -> bool:
	return not is_sold_out(item) and can_afford(item)

# ── Compra ────────────────────────────────────────────────────────────────────

## Compra el objeto con [param item_id]. Devuelve false, sin cobrar nada, si no existe,
## está agotado o no hay saldo suficiente.
func buy(item_id: String) -> bool:
	var item: ShopItemData = _find(item_id)
	if item == null or _character == null or not can_buy(item):
		return false
	# El precio se calcula antes de contar la compra.
	if not GameState.spend_energon(get_price(item)):
		return false
	_purchases[item.id] = get_purchases(item) + 1
	item.apply(_character)
	EventBus.play_sfx.emit("shop_buy")
	EventBus.shop_item_bought.emit(item.id)
	item_bought.emit(item.id)
	return true


func _find(item_id: String) -> ShopItemData:
	for item in get_items():
		if item.id == item_id:
			return item
	return null
