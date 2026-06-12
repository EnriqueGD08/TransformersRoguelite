# skin_manager.gd
# Componente que gestiona las skins visuales de un personaje.
# SRP: única responsabilidad es cambiar el aspecto visual del sprite.
#      No tiene acceso a stats, lógica de combate ni transformación.
# ISP: implementa ISkinProvider.
# DIP: recibe el AnimatedSprite2D por referencia, no lo busca en el árbol.

class_name SkinManager
extends Node

# ── Señales ───────────────────────────────────────────────────────────────────

## Emitida cuando la skin cambia correctamente.
## [param skin_id] ID de la nueva skin activa.
signal skin_changed(skin_id: String)

# ── Estado interno ────────────────────────────────────────────────────────────

var _current_skin: String = ""
var _available_skins: Array[String] = []

## Referencia al AnimatedSprite2D del personaje.
## Se asigna desde base_character.gd mediante setup().
var _sprite: AnimatedSprite2D = null

## Diccionario de SpriteFrames por skin_id.
## Clave: "g1" | "prime" | "bay"
## Valor: SpriteFrames (asignado desde la escena del personaje).
var _skin_frames: Dictionary = {}

# ── Setup ─────────────────────────────────────────────────────────────────────

## Inicializa el SkinManager con el sprite y los frames disponibles.
## Llamar desde la escena concreta del personaje antes de set_skin().
## [param sprite] AnimatedSprite2D del personaje.
## [param frames] Dictionary { skin_id: SpriteFrames }.
## [param skins] Array con los IDs disponibles (viene de CharacterStats).
func setup(sprite: AnimatedSprite2D, frames: Dictionary, skins: Array[String]) -> void:
	assert(sprite != null, "SkinManager: sprite no puede ser null")
	assert(frames.size() > 0, "SkinManager: frames no puede estar vacío")
	_sprite = sprite
	_skin_frames = frames
	_available_skins = skins

# ── ISkinProvider ─────────────────────────────────────────────────────────────

## Aplica la skin indicada al sprite del personaje.
## Si la skin no existe en _skin_frames, emite un error y no cambia nada.
## [param skin_id] "g1", "prime" o "bay".
func set_skin(skin_id: String) -> void:
	if _sprite == null:
		push_error("SkinManager: setup() no ha sido llamado antes de set_skin()")
		return

	if not _skin_frames.has(skin_id):
		push_error("SkinManager: skin_id '%s' no existe en _skin_frames" % skin_id)
		return

	if skin_id == _current_skin:
		return

	_current_skin = skin_id
	_sprite.sprite_frames = _skin_frames[skin_id]
	_sprite.play("idle")
	skin_changed.emit(_current_skin)


## Devuelve el ID de la skin actualmente activa.
func get_current_skin() -> String:
	return _current_skin


## Devuelve los IDs de todas las skins disponibles para este personaje.
func get_available_skins() -> Array:
	return _available_skins

# ── Utilidades ────────────────────────────────────────────────────────────────

## Cicla a la siguiente skin disponible (útil para botón de preview en menú).
func cycle_skin() -> void:
	if _available_skins.is_empty():
		return
	var idx: int = _available_skins.find(_current_skin)
	var next_idx: int = (idx + 1) % _available_skins.size()
	set_skin(_available_skins[next_idx])


## Devuelve true si la skin indicada está disponible para este personaje.
func has_skin(skin_id: String) -> bool:
	return _available_skins.has(skin_id)
