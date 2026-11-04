# character_info.gd
# Resource con los datos de PRESENTACIÓN de un personaje jugable
# (los que muestra la pantalla de selección). Los números de juego viven en CharacterStats.
# SRP: solo datos. DIP: la UI lee este Resource y no conoce clases de personajes concretos.

class_name CharacterInfo
extends Resource

## Identificador único (coincide con CharacterStats.character_id).
@export var id: String = ""

## Nombre visible.
@export var display_name: String = ""

## Facción: determina el color de acento en la UI.
@export_enum("Autobot", "Decepticon") var faction: String = "Autobot"

## Rol en una frase corta (ej: "Tanque cuerpo a cuerpo").
@export var role: String = ""

## Descripción corta del estilo de juego.
@export_multiline var description: String = ""

## Nombre y explicación del arma.
@export var weapon_name: String = ""
@export_multiline var weapon_description: String = ""

## Nombre y explicación de la transformación.
@export var transform_name: String = ""
@export_multiline var transform_description: String = ""

## Escena jugable del personaje (player_*.tscn).
@export var scene: PackedScene

## Estadísticas de juego (se muestran como barras).
@export var stats: CharacterStats

## Caché de los SpriteFrames por skin (se calcula una sola vez).
var _skin_frames_cache: Dictionary = {}


## Devuelve { skin_id: SpriteFrames } leyendo los exports del propio personaje,
## así la vista previa usa exactamente los mismos sprites que la partida
## (sin duplicar rutas de arte en este Resource).
func get_skin_frames() -> Dictionary:
	if not _skin_frames_cache.is_empty() or scene == null:
		return _skin_frames_cache
	var instance: Node = scene.instantiate()
	for skin_id in ["g1", "prime", "bay"]:
		var frames: SpriteFrames = instance.get("skin_frames_" + skin_id)
		if frames != null:
			_skin_frames_cache[skin_id] = frames
	instance.free()
	return _skin_frames_cache
