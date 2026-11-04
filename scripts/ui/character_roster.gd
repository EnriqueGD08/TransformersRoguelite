# character_roster.gd
# Lista ordenada de los personajes jugables.
# SRP: solo agrupa CharacterInfo. Añadir un personaje = añadir una entrada, sin tocar código.

class_name CharacterRoster
extends Resource

@export var entries: Array[CharacterInfo] = []
