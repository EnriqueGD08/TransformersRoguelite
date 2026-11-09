# shop_ui.gd
# Pantalla de la tienda que se abre entre oleadas, después del árbol de habilidades.
# SRP: dibuja los objetos, deja seleccionarlos y pide la compra. No cobra ni aplica
#      efectos: eso lo hace ShopManager.
# DIP: comunica por EventBus (shop_opened / shop_closed) y usa el manager inyectado.
# Mientras está abierta el juego se pausa; esta pantalla sigue funcionando (PROCESS_MODE_ALWAYS).

class_name ShopUI
extends CanvasLayer

const STAT_COLOR := Color("4fb3ff")
const PASSIVE_COLOR := Color("c58bff")
const SOLD_COLOR := Color("7be38a")
const GOLD := Color("ffe9a0")
const CARD_SIZE := Vector2(150, 116)

# ── Nodos ─────────────────────────────────────────────────────────────────────

@onready var _root: Control = $Root
@onready var _title: Label = %TitleLabel
@onready var _energon_label: Label = %EnergonLabel
@onready var _grid: GridContainer = %ItemGrid
@onready var _detail_kind: Label = %DetailKind
@onready var _detail_name: Label = %DetailName
@onready var _detail_price: Label = %DetailPrice
@onready var _detail_desc: Label = %DetailDesc
@onready var _detail_count: Label = %DetailCount
@onready var _detail_state: Label = %DetailState
@onready var _buy_button: Button = %BuyButton
@onready var _continue_button: Button = %ContinueButton

# ── Estado ────────────────────────────────────────────────────────────────────

var _manager: ShopManager = null
var _items: Array[ShopItemData] = []
var _cards: Dictionary = {}
var _selected_id: String = ""
var _last_wave: int = 0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.hide()
	EventBus.shop_opened.connect(_open)
	EventBus.wave_completed.connect(func(n: int) -> void: _last_wave = n)
	EventBus.player_energon_changed.connect(func(_amount: int) -> void: _refresh())
	_buy_button.pressed.connect(_on_buy_pressed)
	_continue_button.pressed.connect(_close)


## Inyección del manager y construcción de las tarjetas.
func setup(manager: ShopManager) -> void:
	_manager = manager
	_items = manager.get_items()
	for item in _items:
		_cards[item.id] = _make_card(item)
	manager.item_bought.connect(func(_id: String) -> void: _refresh())


## Tarjeta de un objeto: icono, nombre, precio y cuántas veces se lleva comprado.
func _make_card(item: ShopItemData) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.pressed.connect(_select.bind(item.id))

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = item.icon
	icon.custom_minimum_size = Vector2(0, 46)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = item.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)

	var price_label := Label.new()
	price_label.name = "Price"
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 16)
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(price_label)

	var count_label := Label.new()
	count_label.name = "Count"
	count_label.position = Vector2(8, 4)
	count_label.add_theme_font_size_override("font_size", 13)
	count_label.add_theme_color_override("font_color", Color(0.72, 0.77, 0.86))
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(count_label)

	_grid.add_child(card)
	return card

# ── Abrir / cerrar ────────────────────────────────────────────────────────────

func _open() -> void:
	if _manager == null or _items.is_empty():
		# Sin tienda configurada no hay nada que mostrar: se continúa directamente.
		EventBus.shop_closed.emit.call_deferred()
		return
	_title.text = "Tienda  ·  Oleada %d completada" % _last_wave
	_root.show()
	get_tree().paused = true
	_select(_first_buyable_id())
	_continue_button.grab_focus()


func _close() -> void:
	_root.hide()
	get_tree().paused = false
	EventBus.shop_closed.emit()


## Primer objeto que se puede comprar ahora; si no hay ninguno, el primero de la lista.
func _first_buyable_id() -> String:
	for item in _items:
		if _manager.can_buy(item):
			return item.id
	return _items[0].id

# ── Selección y compra ────────────────────────────────────────────────────────

func _select(item_id: String) -> void:
	_selected_id = item_id
	_refresh()


func _on_buy_pressed() -> void:
	if _selected_id != "":
		_manager.buy(_selected_id)

# ── Refresco visual ───────────────────────────────────────────────────────────

func _refresh() -> void:
	if _manager == null:
		return
	_energon_label.text = str(GameState.current_energon)
	for item in _items:
		_update_card(_cards[item.id], item)
	_update_detail()


func _kind_color(item: ShopItemData) -> Color:
	return PASSIVE_COLOR if item.kind == "passive" else STAT_COLOR


func _update_card(card: Button, item: ShopItemData) -> void:
	var sold: bool = _manager.is_sold_out(item)
	var affordable: bool = _manager.can_afford(item)
	var color: Color = _kind_color(item)
	var bg: Color = Color(0.1, 0.12, 0.18)
	var border: Color = color
	var width: int = 3
	var icon_tint: Color = Color.WHITE
	var price_color: Color = GOLD
	if sold:
		bg = SOLD_COLOR.darkened(0.78)
		border = SOLD_COLOR.darkened(0.3)
		icon_tint = Color(0.65, 0.8, 0.68)
		price_color = SOLD_COLOR
	elif not affordable:
		bg = Color(0.08, 0.1, 0.15)
		border = color.darkened(0.5)
		width = 2
		icon_tint = Color(0.5, 0.52, 0.6)
		price_color = Color("ff9a8a")
	if item.id == _selected_id:
		border = Color.WHITE
		width = 4

	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(8)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		card.add_theme_stylebox_override(state_name, style)

	var box: VBoxContainer = card.get_child(0)
	box.get_node("Icon").modulate = icon_tint
	var price: Label = box.get_node("Price")
	price.text = ("✔ Agotado" if item.kind == "stat" else "✔ Comprado") if sold else "%d" % _manager.get_price(item)
	price.add_theme_color_override("font_color", price_color)
	# Contador de compras (solo en las mejoras que se repiten).
	var count: Label = card.get_node("Count")
	count.text = "%d/%d" % [_manager.get_purchases(item), item.max_purchases] if item.max_purchases > 1 else ""


func _update_detail() -> void:
	var item: ShopItemData = _selected_item()
	if item == null:
		return
	var sold: bool = _manager.is_sold_out(item)
	var price: int = _manager.get_price(item)
	_detail_kind.text = "HABILIDAD" if item.kind == "passive" else "MEJORA"
	_detail_kind.add_theme_color_override("font_color", _kind_color(item))
	_detail_name.text = item.display_name
	_detail_price.text = "Precio: %d energon" % price if not sold else "Precio: —"
	_detail_desc.text = item.description
	if item.max_purchases > 1:
		_detail_count.text = "Comprado %d de %d veces" % [_manager.get_purchases(item), item.max_purchases]
	else:
		_detail_count.text = "Se compra una sola vez"

	if sold:
		_detail_state.text = "✔ Agotado" if item.kind == "stat" else "✔ Ya la tienes"
		_detail_state.add_theme_color_override("font_color", SOLD_COLOR)
	elif _manager.can_afford(item):
		_detail_state.text = "Disponible"
		_detail_state.add_theme_color_override("font_color", GOLD)
	else:
		_detail_state.text = "Te faltan %d energon" % (price - GameState.current_energon)
		_detail_state.add_theme_color_override("font_color", Color("ff9a8a"))
	_buy_button.disabled = not _manager.can_buy(item)
	_buy_button.text = "COMPRAR  (%d)" % price if not sold else "✔ AGOTADO"


func _selected_item() -> ShopItemData:
	for item in _items:
		if item.id == _selected_id:
			return item
	return null
