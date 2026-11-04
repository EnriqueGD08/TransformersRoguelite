# audio_manager.gd
# Gestiona toda la reproducción de audio del juego.
# SRP: única responsabilidad es reproducir SFX y música en respuesta
#      a señales del EventBus. No conoce qué sistema emitió la señal.
# ISP: implementa IAudioEmitter.
# DIP: escucha EventBus.play_sfx y EventBus.play_music; no recibe
#      llamadas directas de ningún sistema de juego.

extends Node

# ── Configuración ─────────────────────────────────────────────────────────────

## Ruta base donde residen los archivos de SFX.
const SFX_BASE_PATH: String = "res://assets/audio/sfx/"

## Ruta base donde residen los archivos de música.
const MUSIC_BASE_PATH: String = "res://assets/audio/music/"

## Extensión de los archivos de audio.
const AUDIO_EXT: String = ".ogg"

## Número de reproductores de SFX en el pool (para sonidos simultáneos).
const SFX_POOL_SIZE: int = 8

## Volumen maestro de SFX en dB (0.0 = sin atenuación).
@export_range(-40.0, 0.0, 1.0) var sfx_volume_db: float = 0.0

## Volumen maestro de música en dB.
@export_range(-40.0, 0.0, 1.0) var music_volume_db: float = -6.0

# ── Nodos de audio ────────────────────────────────────────────────────────────

## Pool de reproductores para SFX (permite varios sonidos simultáneos).
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0

## Reproductor dedicado a la música (uno a la vez con crossfade).
var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer

## Caché de streams ya cargados para no releer el disco.
var _stream_cache: Dictionary = {}

## ID de la pista de música actual.
var _current_track_id: String = ""

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_sfx_pool()
	_build_music_players()
	_connect_signals()


func _build_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)


func _build_music_players() -> void:
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.bus = "Music"
	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.bus = "Music"
	add_child(_music_player_a)
	add_child(_music_player_b)
	_active_music_player = _music_player_a


func _connect_signals() -> void:
	EventBus.play_sfx.connect(play_sfx)
	EventBus.play_music.connect(play_music)
	EventBus.stop_music.connect(stop_music)

# ── IAudioEmitter ─────────────────────────────────────────────────────────────

## Reproduce un SFX por su ID. Usa el pool circular para simultaneidad.
## [param sfx_id] Identificador del sonido (ej: "optimus_transform").
## [param volume_db] Ajuste de volumen relativo al maestro.
func play_sfx(sfx_id: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _load_stream(SFX_BASE_PATH + sfx_id + AUDIO_EXT)
	if stream == null:
		return

	var player: AudioStreamPlayer = _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE

	player.stream = stream
	player.volume_db = sfx_volume_db + volume_db
	player.play()


func stop_sfx(_sfx_id: String) -> void:
	# El pool circular no permite detener un SFX específico fácilmente.
	# Para SFX con duración larga o en bucle, usar un AudioStreamPlayer
	# dedicado fuera del pool y parar con su referencia directa.
	pass


## Reproduce una pista de música con crossfade hacia la nueva pista.
## Si ya suena la misma pista, no hace nada.
## [param track_id] Identificador de la pista (ej: "battle_wave_1", "menu").
## [param loop] Si la pista debe repetirse en bucle.
func play_music(track_id: String, loop: bool = true) -> void:
	if track_id == _current_track_id:
		return

	var stream: AudioStream = _load_stream(MUSIC_BASE_PATH + track_id + AUDIO_EXT)
	if stream == null:
		return

	_current_track_id = track_id

	# Crossfade: el player inactivo toma la nueva pista.
	var next_player: AudioStreamPlayer = \
		_music_player_b if _active_music_player == _music_player_a else _music_player_a

	if stream is AudioStreamOggVorbis:
		stream.loop = loop

	next_player.stream = stream
	next_player.volume_db = -80.0
	next_player.play()

	_crossfade(_active_music_player, next_player)
	_active_music_player = next_player


## Detiene la música activa con un fade opcional.
## [param fade_duration] Duración del fade en segundos.
func stop_music(fade_duration: float = 0.0) -> void:
	_current_track_id = ""
	if fade_duration <= 0.0:
		_active_music_player.stop()
		return

	var tween: Tween = create_tween()
	tween.tween_property(_active_music_player, "volume_db", -80.0, fade_duration)
	tween.tween_callback(_active_music_player.stop)

# ── Privados ──────────────────────────────────────────────────────────────────

## Carga un AudioStream desde disco con caché para no releer el mismo archivo.
func _load_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]

	if not ResourceLoader.exists(path):
		# Se avisa una sola vez por archivo y se cachea null para no repetir
		# la comprobación (aún no hay audio real: es lo esperado en desarrollo).
		push_warning("AudioManager: archivo no encontrado — %s" % path)
		_stream_cache[path] = null
		return null

	var stream: AudioStream = load(path)
	_stream_cache[path] = stream
	return stream


## Realiza el crossfade entre dos reproductores de música.
func _crossfade(from: AudioStreamPlayer, to: AudioStreamPlayer) -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(from, "volume_db", -80.0, 1.5)
	tween.tween_property(to, "volume_db", music_volume_db, 1.5)
	tween.tween_callback(from.stop).set_delay(1.6)
