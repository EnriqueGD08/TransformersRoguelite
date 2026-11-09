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

## Extensiones que se buscan, por orden: si algún día añades audio grabado en .ogg, tiene
## prioridad sobre el sintetizado (.wav) sin tocar nada más.
const AUDIO_EXTENSIONS: PackedStringArray = [".ogg", ".wav"]

## Pistas que suenan una sola vez (el resto va en bucle).
const ONE_SHOT_TRACKS: PackedStringArray = ["victory", "game_over"]

## Segundos mínimos entre dos reproducciones del mismo sonido: evita que los muy
## frecuentes (golpes, clics) se amontonen en una ametralladora de ruido.
const MIN_REPEAT_SECONDS: float = 0.06

## Sonidos que el audio dispara por su cuenta al oír una señal del EventBus
## (nadie pide estos sonidos explícitamente).
const SIGNAL_SOUNDS: Dictionary = {
	"skill_unlocked": "skill_unlock",
	"wave_started": "wave_start",
	"wave_completed": "wave_complete",
	"boss_spawned": "boss_phase2",
}

## Número de reproductores de SFX en el pool (para sonidos simultáneos).
const SFX_POOL_SIZE: int = 8

## Volumen maestro de SFX en dB (0.0 = sin atenuación).
@export_range(-40.0, 0.0, 1.0) var sfx_volume_db: float = -4.0

## Volumen maestro de música en dB.
@export_range(-40.0, 0.0, 1.0) var music_volume_db: float = -11.0

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

## Instante (ms) de la última reproducción de cada sonido, para limitar la frecuencia.
var _last_played_ms: Dictionary = {}

## Vida del jugador en la última señal, para detectar cuándo recibe daño.
var _last_player_hp: float = -1.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	# El audio debe seguir sonando con el juego pausado (tienda, árbol de habilidades).
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	for signal_name in SIGNAL_SOUNDS:
		var sound: String = SIGNAL_SOUNDS[signal_name]
		# Cada señal tiene una firma distinta: la función acepta y descarta sus argumentos.
		var emitter: Signal = EventBus.get(signal_name)
		emitter.connect(func(_a = null, _b = null, _c = null) -> void: play_sfx(sound))
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	# Todos los botones del juego hacen "clic" sin que cada uno lo pida.
	get_tree().node_added.connect(_on_node_added)


func _on_player_hp_changed(current: float, _maximum: float) -> void:
	if _last_player_hp >= 0.0 and current < _last_player_hp:
		play_sfx("player_hit")
	_last_player_hp = current


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play_sfx.bind("ui_click"))

# ── IAudioEmitter ─────────────────────────────────────────────────────────────

## Reproduce un SFX por su ID. Usa el pool circular para simultaneidad.
## [param sfx_id] Identificador del sonido (ej: "optimus_transform").
## [param volume_db] Ajuste de volumen relativo al maestro.
func play_sfx(sfx_id: String, volume_db: float = 0.0) -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_played_ms.get(sfx_id, -1000000) < MIN_REPEAT_SECONDS * 1000.0:
		return
	var stream: AudioStream = _load_stream(SFX_BASE_PATH + sfx_id)
	if stream == null:
		return
	_last_played_ms[sfx_id] = now

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

	var stream: AudioStream = _load_stream(MUSIC_BASE_PATH + track_id)
	if stream == null:
		return
	if track_id in ONE_SHOT_TRACKS:
		loop = false

	_current_track_id = track_id

	# Crossfade: el player inactivo toma la nueva pista.
	var next_player: AudioStreamPlayer = \
		_music_player_b if _active_music_player == _music_player_a else _music_player_a

	if stream is AudioStreamOggVorbis:
		stream.loop = loop
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
		stream.loop_begin = 0
		# Godot comprime los WAV al importarlos, así que el tamaño de los datos no sirve:
		# el fin del bucle se calcula con la duración real.
		stream.loop_end = int(round(stream.get_length() * stream.mix_rate))

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
## [param base_path] es la ruta SIN extensión: se prueba cada una de AUDIO_EXTENSIONS.
func _load_stream(base_path: String) -> AudioStream:
	if _stream_cache.has(base_path):
		return _stream_cache[base_path]

	for extension in AUDIO_EXTENSIONS:
		if ResourceLoader.exists(base_path + extension):
			var stream: AudioStream = load(base_path + extension)
			_stream_cache[base_path] = stream
			return stream

	# Se avisa una sola vez por archivo y se cachea null para no repetir la comprobación.
	push_warning("AudioManager: archivo no encontrado — %s" % base_path)
	_stream_cache[base_path] = null
	return null


## Realiza el crossfade entre dos reproductores de música.
func _crossfade(from: AudioStreamPlayer, to: AudioStreamPlayer) -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(from, "volume_db", -80.0, 1.5)
	tween.tween_property(to, "volume_db", music_volume_db, 1.5)
	tween.tween_callback(from.stop).set_delay(1.6)
