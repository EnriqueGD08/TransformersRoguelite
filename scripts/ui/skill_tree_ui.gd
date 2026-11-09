# skill_tree_ui.gd
# Pantalla del árbol de habilidades que se abre entre oleadas.
# SRP: dibuja el árbol, deja seleccionar y desbloquear nodos y avisa cuando se continúa.
#      No aplica efectos ni gestiona puntos: eso lo hace SkillTreeManager (se le pide).
# DIP: comunica por EventBus (skill_tree_opened / skill_tree_closed) y usa el manager inyectado.
# Mientras está abierta el juego se pausa; esta pantalla sigue funcionando (PROCESS_MODE_ALWAYS).

class_name SkillTreeUI
extends CanvasLayer

const BRANCH_COLORS := {
	"ataque": Color("ff6b5a"),
	"transformación": Color("ffc83d"),
	"defensa": Color("4fb3ff"),
}
const NODE_SIZE: float = 56.0

## En pantalla táctil los nodos son más grandes (un dedo necesita más que un puntero) y el
## árbol se amplía lo justo para que no se solapen; como ya no cabe entero, se arrastra
## con el dedo para recorrerlo.
const TOUCH_NODE_SIZE: float = 86.0
const TOUCH_ZOOM: float = 1.5

## Altura de los botones de la ficha (Desbloquear, Continuar) en pantalla táctil.
const TOUCH_BUTTON_HEIGHT: float = 68.0

## El árbol puede ampliarse hasta este factor para aprovechar el espacio disponible.
const MAX_ZOOM: float = 1.3

# ── Nodos ─────────────────────────────────────────────────────────────────────

@onready var _root: Control = $Root
@onready var _title: Label = %TitleLabel
@onready var _points_label: Label = %PointsLabel
@onready var _scroll: TouchScrollContainer = %TreeScroll
@onready var _tree_area: Control = %TreeArea
@onready var _detail_name: Label = %DetailName
@onready var _detail_branch: Label = %DetailBranch
@onready var _detail_cost: Label = %DetailCost
@onready var _detail_desc: Label = %DetailDesc
@onready var _detail_req: Label = %DetailReq
@onready var _detail_state: Label = %DetailState
@onready var _unlock_button: Button = %UnlockButton
@onready var _continue_button: Button = %ContinueButton

# ── Estado ────────────────────────────────────────────────────────────────────

var _manager: SkillTreeManager = null
var _nodes: Array[SkillNodeData] = []
var _by_id: Dictionary = {}
var _buttons: Dictionary = {}
var _selected_id: String = ""
var _last_wave: int = 0
var _touch: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_touch = TouchUI.is_touch_device()
	_root.hide()
	if _touch:
		_unlock_button.custom_minimum_size.y = TOUCH_BUTTON_HEIGHT
		_continue_button.custom_minimum_size.y = TOUCH_BUTTON_HEIGHT
		_unlock_button.add_theme_font_size_override("font_size", 26)
		_continue_button.add_theme_font_size_override("font_size", 26)
	EventBus.skill_tree_opened.connect(_open)
	EventBus.wave_completed.connect(func(n: int) -> void: _last_wave = n)
	_unlock_button.pressed.connect(_on_unlock_pressed)
	_continue_button.pressed.connect(_close)
	_tree_area.draw.connect(_draw_tree)
	_tree_area.resized.connect(_layout_nodes)


## Inyección del manager y construcción de los botones del árbol.
func setup(manager: SkillTreeManager) -> void:
	_manager = manager
	_nodes = manager.get_all_nodes()
	for node in _nodes:
		_by_id[node.id] = node
		_buttons[node.id] = _make_node_button(node)
	manager.node_unlocked.connect(func(_id: String) -> void: _refresh())
	manager.points_changed.connect(func(_a: int, _s: int) -> void: _refresh())
	if _touch:
		# El área del árbol mide lo que mide el árbol ampliado; el contenedor la recorre.
		_tree_area.custom_minimum_size = _touch_content_size()
	_layout_nodes()


func _make_node_button(node: SkillNodeData) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)
	button.size = Vector2(NODE_SIZE, NODE_SIZE)
	button.icon = node.icon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.focus_mode = Control.FOCUS_NONE
	# PASS: el botón recibe el toque, pero un arrastre también llega al contenedor y desplaza.
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.tooltip_text = node.display_name
	button.add_theme_constant_override("icon_max_width", 36)
	button.pressed.connect(_on_node_pressed.bind(node.id))
	# Insignia con el coste si cuesta más de 1 punto.
	if node.cost > 1:
		var badge := Label.new()
		badge.text = str(node.cost)
		badge.position = Vector2(NODE_SIZE - 17, NODE_SIZE - 25)
		badge.add_theme_font_size_override("font_size", 15)
		badge.add_theme_color_override("font_color", Color("ffe9a0"))
		badge.add_theme_color_override("font_outline_color", Color.BLACK)
		badge.add_theme_constant_override("outline_size", 5)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(badge)
	_tree_area.add_child(button)
	return button

# ── Abrir / cerrar ────────────────────────────────────────────────────────────

func _open() -> void:
	if _manager == null:
		# Sin árbol configurado no hay nada que mostrar: se continúa directamente.
		EventBus.skill_tree_closed.emit.call_deferred()
		return
	_title.text = "¡Oleada %d completada!  ·  Elige tus mejoras" % _last_wave
	_root.show()
	get_tree().paused = true
	_layout_nodes()
	_select(_first_available_id())
	_refresh()
	_continue_button.grab_focus()
	if _touch and _buttons.has(_selected_id):
		# Se enseña el primer nodo disponible: el árbol es más grande que la pantalla.
		await get_tree().process_frame
		_scroll.ensure_control_visible(_buttons[_selected_id])


func _close() -> void:
	_root.hide()
	get_tree().paused = false
	EventBus.skill_tree_closed.emit()


func _first_available_id() -> String:
	for node in _nodes:
		if _manager.can_unlock(node.id):
			return node.id
	return _nodes[0].id if not _nodes.is_empty() else ""

# ── Selección y acciones ──────────────────────────────────────────────────────

## Un arrastre que empieza sobre un nodo desplaza el árbol; no lo selecciona.
func _on_node_pressed(node_id: String) -> void:
	if _scroll.just_dragged():
		return
	_select(node_id)


func _select(node_id: String) -> void:
	_selected_id = node_id
	_refresh()


func _on_unlock_pressed() -> void:
	if _selected_id != "":
		_manager.unlock_node(_selected_id)

# ── Refresco visual ───────────────────────────────────────────────────────────

func _refresh() -> void:
	if _manager == null:
		return
	_points_label.text = "Puntos: %d" % _manager.get_available_points()
	for node in _nodes:
		_style_button(_buttons[node.id], node)
	_update_detail()
	_tree_area.queue_redraw()


func _node_state(node: SkillNodeData) -> String:
	if _manager.is_unlocked(node.id):
		return "unlocked"
	if _manager.can_unlock(node.id):
		return "available"
	# ¿Cumple los requisitos aunque falten puntos?
	for req in node.required_ids:
		if not _manager.is_unlocked(req):
			return "locked"
	return "unaffordable"


func _style_button(button: Button, node: SkillNodeData) -> void:
	var color: Color = BRANCH_COLORS[node.branch]
	var state: String = _node_state(node)
	var bg: Color
	var border: Color
	var icon_color: Color
	var width: int = 2
	match state:
		"unlocked":
			bg = color.darkened(0.55)
			border = color.lightened(0.2)
			icon_color = Color.WHITE
			width = 3
		"available":
			bg = Color(0.1, 0.12, 0.18)
			border = color
			icon_color = color.lightened(0.25)
			width = 3
		"unaffordable":
			bg = Color(0.08, 0.1, 0.15)
			border = color.darkened(0.45)
			icon_color = color.darkened(0.2)
		_:
			bg = Color(0.06, 0.07, 0.1)
			border = Color(0.22, 0.25, 0.32)
			icon_color = Color(0.4, 0.43, 0.5)
	if node.id == _selected_id:
		border = Color.WHITE
		width = 4
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(8)
	for state_name in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		button.add_theme_stylebox_override(state_name, style)
	for color_name in ["icon_normal_color", "icon_hover_color", "icon_pressed_color",
			"icon_focus_color", "icon_disabled_color", "icon_hover_pressed_color"]:
		button.add_theme_color_override(color_name, icon_color)


func _update_detail() -> void:
	if _selected_id == "" or not _by_id.has(_selected_id):
		return
	var node: SkillNodeData = _by_id[_selected_id]
	var color: Color = BRANCH_COLORS[node.branch]
	_detail_name.text = node.display_name
	_detail_branch.text = node.branch.to_upper()
	_detail_branch.add_theme_color_override("font_color", color)
	_detail_cost.text = "Coste: %d %s" % [node.cost, "punto" if node.cost == 1 else "puntos"]
	_detail_desc.text = node.description

	var missing: Array[String] = []
	for req in node.required_ids:
		if not _manager.is_unlocked(req):
			missing.append(_by_id[req].display_name)
	_detail_req.text = "Requiere: " + ", ".join(missing) if not missing.is_empty() else ""

	var unlocked: bool = _manager.is_unlocked(node.id)
	var state: String = _node_state(node)
	match state:
		"unlocked":
			_detail_state.text = "✔ Desbloqueada"
			_detail_state.add_theme_color_override("font_color", Color("7be38a"))
		"available":
			_detail_state.text = "Disponible"
			_detail_state.add_theme_color_override("font_color", Color("ffe9a0"))
		"unaffordable":
			var lacking: int = node.cost - _manager.get_available_points()
			_detail_state.text = "Te faltan %d %s" % [lacking, "punto" if lacking == 1 else "puntos"]
			_detail_state.add_theme_color_override("font_color", Color("ff9a8a"))
		_:
			_detail_state.text = "Bloqueada"
			_detail_state.add_theme_color_override("font_color", Color("8a90a3"))
	_unlock_button.disabled = unlocked or state != "available"
	_unlock_button.text = "✔ DESBLOQUEADA" if unlocked else "DESBLOQUEAR  (%d)" % node.cost

# ── Disposición y dibujo del árbol ────────────────────────────────────────────

## Calcula escala y desplazamiento para que todo el árbol quepa centrado.
func _fit() -> Dictionary:
	if _nodes.is_empty():
		return {"scale": 1.0, "offset": Vector2.ZERO}
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for node in _nodes:
		min_p = min_p.min(node.tree_position)
		max_p = max_p.max(node.tree_position)
	var area: Vector2 = _tree_area.size
	var scale_f: float
	if _touch:
		scale_f = TOUCH_ZOOM
	else:
		var margin: float = NODE_SIZE * 0.5 + 16.0
		var size: Vector2 = (max_p - min_p) + Vector2(margin, margin) * 2.0
		scale_f = minf(minf(area.x / size.x, area.y / size.y), MAX_ZOOM)
	var offset: Vector2 = (area - (max_p - min_p) * scale_f) * 0.5 - min_p * scale_f
	return {"scale": scale_f, "offset": offset}


## Tamaño que ocupa el árbol ampliado para pantalla táctil (con margen alrededor).
func _touch_content_size() -> Vector2:
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for node in _nodes:
		min_p = min_p.min(node.tree_position)
		max_p = max_p.max(node.tree_position)
	var margin: float = TOUCH_NODE_SIZE * 0.5 + 24.0
	return (max_p - min_p) * TOUCH_ZOOM + Vector2(margin, margin) * 2.0


## Lado de un nodo en pantalla, según el modo y el zoom del árbol.
func _node_px(fit: Dictionary) -> float:
	return TOUCH_NODE_SIZE if _touch else NODE_SIZE * clampf(fit.scale, 0.8, 1.2)


func _center_of(node: SkillNodeData, fit: Dictionary) -> Vector2:
	return fit.offset + node.tree_position * fit.scale


func _layout_nodes() -> void:
	if _nodes.is_empty():
		return
	var fit: Dictionary = _fit()
	# Los botones crecen un poco con el zoom (sin pasarse) para que el árbol no se vea vacío.
	var node_px: float = _node_px(fit)
	var k: float = node_px / NODE_SIZE
	for node in _nodes:
		var button: Button = _buttons[node.id]
		# Insignia con el coste: sigue al tamaño del botón.
		if button.get_child_count() > 0:
			var badge: Label = button.get_child(0)
			badge.position = Vector2(node_px - 17.0 * k, node_px - 25.0 * k)
			badge.add_theme_font_size_override("font_size", int(15.0 * k))
		button.custom_minimum_size = Vector2(node_px, node_px)
		button.size = Vector2(node_px, node_px)
		button.add_theme_constant_override("icon_max_width", int(node_px * 0.64))
		button.position = _center_of(node, fit) - Vector2(node_px, node_px) * 0.5
	_tree_area.queue_redraw()


func _draw_tree() -> void:
	if _manager == null or _nodes.is_empty():
		return
	var fit: Dictionary = _fit()
	# Conexiones: más vivas cuanto más avanzado está el camino.
	for node in _nodes:
		var color: Color = BRANCH_COLORS[node.branch]
		for req_id in node.required_ids:
			var a: Vector2 = _center_of(_by_id[req_id], fit)
			var b: Vector2 = _center_of(node, fit)
			var req_done: bool = _manager.is_unlocked(req_id)
			var self_done: bool = _manager.is_unlocked(node.id)
			if req_done and self_done:
				_tree_area.draw_line(a, b, color.lightened(0.15), 5.0)
			elif req_done:
				_tree_area.draw_line(a, b, Color(color.r, color.g, color.b, 0.65), 3.0)
			else:
				_tree_area.draw_line(a, b, Color(0.25, 0.28, 0.36), 2.0)
	# Título de cada rama, sobre su primer nodo.
	var font: Font = ThemeDB.fallback_font
	for branch in BRANCH_COLORS:
		var first: SkillNodeData = null
		for node in _nodes:
			if node.branch == branch and (first == null or node.tree_position.x < first.tree_position.x):
				first = node
		if first != null:
			var half: float = _node_px(fit) * 0.5
			var pos: Vector2 = _center_of(first, fit) + Vector2(-half, -half - 8.0)
			_tree_area.draw_string(font, pos, branch.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20 if _touch else 15, BRANCH_COLORS[branch])
