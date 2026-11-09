# shop_catalog.gd
# Resource con la lista de objetos que vende la tienda.
# SRP: solo agrupa datos. Se edita desde el Inspector (resources/shop/shop_catalog.tres).

class_name ShopCatalog
extends Resource

@export var items: Array[ShopItemData] = []
