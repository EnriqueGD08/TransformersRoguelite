# touch_scroll_container.gd
# Contenedor con desplazamiento arrastrando con el dedo, incluso si el dedo empieza encima de un
# botón. Se usa en el árbol de habilidades y en la tienda.
# SRP: convierte el arrastre de un dedo en desplazamiento y avisa de que hubo arrastre para que
#      los botones no cuenten como "pulsados" ese gesto.
# Por qué no basta el ScrollContainer normal: su desplazamiento táctil depende de que el
# dispositivo declare tener pantalla táctil y no se puede probar sin un móvil. Este solo usa los
# eventos de toque, así que se comprueba igual en el ordenador.
# Los botones de dentro deben tener mouse_filter = PASS para que el toque llegue hasta aquí.

class_name TouchScrollContainer
extends ScrollContainer

## Distancia (px) que debe recorrer el dedo para considerar que arrastra y no que toca.
@export_range(2.0, 60.0, 1.0) var drag_deadzone: float = 14.0

var _finger: int = -1
var _travel: float = 0.0
var _dragging: bool = false
var _remainder: Vector2 = Vector2.ZERO


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _finger == -1:
			_finger = event.index
			_travel = 0.0
			_dragging = false
			_remainder = Vector2.ZERO
			accept_event()
		elif not event.pressed and event.index == _finger:
			_finger = -1
			accept_event()
	elif event is InputEventScreenDrag and event.index == _finger:
		_travel += event.relative.length()
		if _travel > drag_deadzone:
			_dragging = true
		if _dragging:
			# El contenido sigue al dedo: arrastrar hacia arriba desplaza hacia abajo.
			_remainder -= event.relative
			var step := Vector2(roundf(_remainder.x), roundf(_remainder.y))
			_remainder -= step
			scroll_horizontal += int(step.x)
			scroll_vertical += int(step.y)
		accept_event()


## True si el último gesto fue un arrastre. Los botones lo consultan al ser pulsados: un
## arrastre que empieza sobre un botón no debe seleccionarlo ni comprarlo.
func just_dragged() -> bool:
	return _dragging
