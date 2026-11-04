# projectile_container.gd
# Punto único para añadir proyectiles y efectos al mundo.
# SRP: solo decide DÓNDE se cuelgan los proyectiles en el árbol de escena.
# Antes cada arma hacía get_parent().get_parent().add_child(...), que se rompía
# si cambiaba la jerarquía; ahora todas usan el nodo del grupo "projectiles".

class_name ProjectileContainer
extends RefCounted

const GROUP := &"projectiles"


## Añade [param node] al contenedor de proyectiles de la escena.
## [param source] es cualquier nodo del árbol (arma, personaje, enemigo...).
static func add(source: Node, node: Node) -> void:
	var tree: SceneTree = source.get_tree()
	var parent: Node = tree.get_first_node_in_group(GROUP)
	if parent == null:
		parent = tree.current_scene if tree.current_scene != null else source.get_parent()
	parent.add_child(node)
