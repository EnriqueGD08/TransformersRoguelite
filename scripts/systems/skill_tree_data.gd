# skill_tree_data.gd
# Resource con el árbol de habilidades completo de un personaje.
# SRP: solo agrupa los SkillNodeData. Cada personaje tiene su propio .tres.
# OCP: añadir o quitar habilidades = editar el .tres, sin tocar código.

class_name SkillTreeData
extends Resource

## ID del personaje al que pertenece (coincide con CharacterStats.character_id).
@export var character_id: String = ""

## Todos los nodos del árbol.
@export var nodes: Array[SkillNodeData] = []
