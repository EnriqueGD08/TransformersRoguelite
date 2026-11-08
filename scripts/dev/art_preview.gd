# art_preview.gd
# Escena SOLO de desarrollo: enseña el arte nuevo en movimiento, a su velocidad
# real, con las tres skins a la vez. Los fotogramas se generan al arrancar.
# Teclas 1-8: elegir animación. Espacio: alternar el paso automático entre animaciones.

extends Node2D

const A := preload("res://tools/art2/cel_anim.gd")
const DESIGN := preload("res://tools/art2/starscream_cel.gd")

const SKINS := ["g1", "prime", "bay"]
const SKIN_NAMES := ["G1", "Prime", "Bay"]
const ANIMS := ["idle", "walk", "attack", "walk_attack", "transform_activate", "transform_walk", "transform_attack", "death"]
const ANIM_NAMES := ["1  Reposo", "2  Caminar", "3  Disparar", "4  Disparar caminando", "5  Transformación", "6  Vehículo en marcha", "7  Vehículo disparando", "8  Muerte"]

## Segundos por animación en el paso automático.
@export var auto_seconds: float = 3.5

var _sprites: Array[AnimatedSprite2D] = []
var _label: Label
var _index: int = 0
var _auto: bool = true
var _elapsed: float = 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.13, 0.14, 0.18))
	for i in SKINS.size():
		var sprite := AnimatedSprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.sprite_frames = _build_frames(SKINS[i])
		sprite.position = Vector2(215 + i * 425, 350)
		add_child(sprite)
		_sprites.append(sprite)
		var name_label := Label.new()
		name_label.text = SKIN_NAMES[i]
		name_label.position = Vector2(95 + i * 425, 640)
		name_label.size = Vector2(240, 40)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 26)
		add_child(name_label)
	_label = Label.new()
	_label.position = Vector2(24, 16)
	_label.add_theme_font_size_override("font_size", 22)
	add_child(_label)
	_show(0)


func _build_frames(skin: String) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var sets: Dictionary = A.all(DESIGN, skin, 1.0)
	for anim in sets:
		sf.add_animation(anim)
		sf.set_animation_speed(anim, A.FPS)
		for img in sets[anim]:
			sf.add_frame(anim, ImageTexture.create_from_image(img))
	return sf


func _show(index: int) -> void:
	_index = index
	_elapsed = 0.0
	for sprite in _sprites:
		sprite.play(ANIMS[index])
	_label.text = "%s     (teclas 1-8, Espacio: paso automático %s)" % [ANIM_NAMES[index], "SÍ" if _auto else "NO"]


func _process(delta: float) -> void:
	if not _auto:
		return
	_elapsed += delta
	if _elapsed >= auto_seconds:
		_show((_index + 1) % ANIMS.size())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_8:
			_show(event.keycode - KEY_1)
		elif event.keycode == KEY_SPACE:
			_auto = not _auto
			_show(_index)
