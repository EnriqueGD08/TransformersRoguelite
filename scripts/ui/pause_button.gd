# pause_button.gd
# Botón redondo de pausa (dos barras) para la esquina de la pantalla.
# SRP: solo se dibuja a sí mismo; lo que hace al pulsarlo lo decide PauseMenu.
# Es un Button normal, así que funciona igual con ratón que con el dedo (el dedo emula el ratón).

class_name PauseButton
extends Button

const OUTLINE := Color("14161f")


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.12, 0.18, 0.85) if state != "hover" else Color(0.18, 0.21, 0.3, 0.92)
		style.border_color = Color(0.85, 0.89, 1.0, 0.75)
		style.set_border_width_all(3)
		style.set_corner_radius_all(40)
		add_theme_stylebox_override(state, style)


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var h: float = size.y * 0.3
	var w: float = size.x * 0.1
	for dx in [-0.17, 0.17]:
		var bar := Rect2(c.x + size.x * dx - w * 0.5, c.y - h, w, h * 2.0)
		draw_rect(bar.grow(2.0), OUTLINE)
		draw_rect(bar, Color.WHITE)
