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

## Árbol de habilidades del personaje.
@export var skill_tree: SkillTreeData

## Caché de las rutas de SpriteFrames por skin (se calcula una sola vez).
var _skin_paths_cache: Dictionary = {}


## Devuelve { skin_id: ruta } leyendo los exports del propio personaje, así la vista previa
## usa exactamente los mismos sprites que la partida (sin duplicar rutas en este Resource).
## Solo son rutas: no carga texturas.
func get_skin_paths() -> Dictionary:
	if not _skin_paths_cache.is_empty() or scene == null:
		return _skin_paths_cache
	var instance: Node = scene.instantiate()
	for skin_id in ["g1", "prime", "bay"]:
		var path: String = instance.get("skin_frames_" + skin_id)
		if not path.is_empty():
			_skin_paths_cache[skin_id] = path
	instance.free()
	return _skin_paths_cache


## Carga los SpriteFrames de una skin (null si no existe). Cada skin pesa decenas de MB:
## quien la pida debe soltarla al dejar de usarla.
func load_skin(skin_id: String) -> SpriteFrames:
	var paths: Dictionary = get_skin_paths()
	return load(paths[skin_id]) if paths.has(skin_id) else null


## Primer fotograma de reposo como textura suelta (para iconos), sin cargar la skin entera.
## Convención: resources/frames/<personaje>_<skin>.tres → assets/sprites/<personaje>/<skin>/.
func get_icon_texture(skin_id: String = "g1") -> Texture2D:
	var paths: Dictionary = get_skin_paths()
	if not paths.has(skin_id):
		return null
	var character: String = String(paths[skin_id]).get_file().get_basename().trim_suffix("_" + skin_id)
	return load("res://assets/sprites/%s/%s/idle_0.png" % [character, skin_id])


## Deja este personaje y la skin elegidos en GameState, listos para empezar o continuar una run.
func select_for_run(skin_id: String) -> void:
	GameState.selected_character_id = id
	GameState.selected_character_scene = scene
	GameState.selected_character_stats = stats
	GameState.selected_skill_tree = skill_tree.nodes if skill_tree != null else []
	GameState.selected_skin_id = skin_id


## Altura en pantalla (antes de base_scale) del personaje en las vistas previas.
const PREVIEW_HEIGHT := 78.0


## Ajusta un sprite de vista previa al tamaño de [param base_scale] sea cual sea la
## resolución de su arte (el arte nuevo tiene más resolución y se ve mejor suavizado).
static func fit_preview(sprite: CanvasItem, frames: SpriteFrames, base_scale: float) -> void:
	var texture: Texture2D = frames.get_frame_texture("idle", 0)
	var height: int = texture.get_height()
	# Se mide lo dibujado, no el lienzo: cada personaje tiene un margen distinto
	# (Optimus deja hueco para el hachazo) y todos deben verse del mismo tamaño.
	var drawn: int = texture.get_image().get_used_rect().size.y
	sprite.scale = Vector2.ONE * base_scale * (PREVIEW_HEIGHT / maxf(drawn, 1.0))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if height > 96 else CanvasItem.TEXTURE_FILTER_NEAREST
