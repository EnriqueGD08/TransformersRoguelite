# touch_ui.gd
# Utilidad: ¿se está jugando en un dispositivo táctil?
# SRP: solo responde esa pregunta, para que todas las pantallas usen el mismo criterio
#      (controles táctiles, árbol de habilidades, tienda...).
# Con --touch-controls se fuerza el modo táctil en el ordenador, para probarlo.

class_name TouchUI
extends RefCounted


static func is_touch_device() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.get_cmdline_user_args().has("--touch-controls")
