# hud_controller.gd
# Controla todos los elementos visuales del HUD durante el juego.
# SRP: única responsabilidad es actualizar la UI en respuesta a señales.
#      No tiene lógica de juego — solo traduce datos a elementos visuales.
# ISP: implementa IHudUpdatable.
# DIP: escucha señales del EventBus; no conoce clases de juego concretas.

class_name HudController
extends CanvasLayer

# ── Nodos del HUD (asignados en hud.tscn) ────────────────────────────────────

## Barra de HP del jugador.
@onready var _hp_bar: TextureProgressBar = $HPBar
@onready var _hp_label: Label = $HPBar/HPLabel

## Indicador de cooldown de transformación.
@onready var _transform_bar: TextureProgressBar = $TransformBar
@onready var _transform_icon: TextureRect = $TransformBar/TransformIcon
@onready var _transform_label: Label = $TransformBar/CooldownLabel

## Contador de energon.
@onready var _energon_label: Label = $EnergonPanel/EnergonLabel
@onready var _energon_icon: TextureRect = $EnergonPanel/EnergonIcon

## Indicador de oleada.
@onready var _wave_label: Label = $WavePanel/WaveLabel

## Panel de HP del jefe (oculto cuando no hay jefe).
@onready var _boss_panel: Control = $BossPanel
@onready var _boss_hp_bar: TextureProgressBar = $BossPanel/BossHPBar
@onready var _boss_name_label: Label = $BossPanel/BossNameLabel

## Indicador de arma activa de Arcee (oculto para otros personajes).
@onready var _weapon_swap_panel: Control = $WeaponSwapPanel
@onready var _weapon_label: Label = $WeaponSwapPanel/WeaponLabel

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_connect_signals()
	_boss_panel.hide()
	_weapon_swap_panel.hide()


func _connect_signals() -> void:
	EventBus.player_hp_changed.connect(update_hp)
	EventBus.transform_cooldown_updated.connect(update_cooldown)
	EventBus.player_energon_changed.connect(update_energon)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.transform_activated.connect(_on_transform_activated)
	EventBus.transform_deactivated.connect(_on_transform_deactivated)
	EventBus.transform_cooldown_ready.connect(_on_transform_ready)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	EventBus.boss_hp_changed.connect(_on_boss_hp_changed)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	EventBus.weapon_swapped.connect(_on_weapon_swapped)

# ── IHudUpdatable ─────────────────────────────────────────────────────────────

func update_hp(current: float, maximum: float) -> void:
	if maximum <= 0.0:
		return
	_hp_bar.max_value = maximum
	_hp_bar.value = current
	_hp_label.text = "%d / %d" % [int(current), int(maximum)]

	# La barra cambia de color según el HP restante.
	var ratio: float = current / maximum
	if ratio > 0.5:
		_hp_bar.modulate = Color.GREEN
	elif ratio > 0.25:
		_hp_bar.modulate = Color.YELLOW
	else:
		_hp_bar.modulate = Color.RED


func update_cooldown(remaining: float, total: float) -> void:
	if total <= 0.0:
		_transform_bar.value = _transform_bar.max_value
		_transform_label.text = ""
		return

	_transform_bar.max_value = total
	_transform_bar.value = total - remaining

	if remaining > 0.0:
		_transform_label.text = "%.1fs" % remaining
	else:
		_transform_label.text = "LISTO"


func update_energon(amount: int) -> void:
	_energon_label.text = str(amount)


func update_wave(wave_number: int, total_waves: int) -> void:
	_wave_label.text = "OLEADA %d / %d" % [wave_number, total_waves]


func update_transform_indicator(is_active: bool) -> void:
	if is_active:
		_transform_icon.modulate = Color.CYAN
		_transform_bar.modulate = Color.CYAN
	else:
		_transform_icon.modulate = Color.WHITE
		_transform_bar.modulate = Color.WHITE

# ── Callbacks del EventBus ────────────────────────────────────────────────────

func _on_wave_started(wave_number: int, total_waves: int) -> void:
	update_wave(wave_number, total_waves)


func _on_transform_activated(_character: Node) -> void:
	update_transform_indicator(true)


func _on_transform_deactivated(_character: Node) -> void:
	update_transform_indicator(false)


func _on_transform_ready(_character: Node) -> void:
	_transform_label.text = "LISTO"
	_transform_bar.modulate = Color.GREEN
	# Efecto de pulso para avisar al jugador.
	var tween: Tween = create_tween()
	tween.tween_property(_transform_bar, "modulate", Color.WHITE, 0.5)


func _on_boss_spawned(boss: Node) -> void:
	_boss_panel.show()
	_boss_hp_bar.max_value = boss.stats.max_hp
	_boss_hp_bar.value = boss.stats.max_hp
	_boss_name_label.text = boss.stats.enemy_name.to_upper()


func _on_boss_hp_changed(_boss: Node, current_hp: float, max_hp: float) -> void:
	_boss_hp_bar.max_value = max_hp
	_boss_hp_bar.value = current_hp


func _on_boss_defeated(_boss: Node) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_boss_panel, "modulate:a", 0.0, 0.8)
	tween.tween_callback(_boss_panel.hide)
	tween.tween_callback(func(): _boss_panel.modulate.a = 1.0)


func _on_weapon_swapped(weapon_type: String) -> void:
	_weapon_swap_panel.show()
	_weapon_label.text = "ARMA: %s" % weapon_type.to_upper()
