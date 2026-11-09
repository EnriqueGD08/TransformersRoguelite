# generate_audio.gd
# Herramienta de desarrollo: sintetiza TODOS los sonidos y la música y los guarda como WAV
# en assets/audio/sfx/ y assets/audio/music/.
# Uso: godot --headless --path . -s tools/generate_audio.gd [-- sfx | music | <id>]
#   sin argumentos genera todo; "sfx" o "music" solo esa parte; un id suelto, solo ese.
# También escribe un informe (duración, pico, nivel medio, recortes) y dibuja las formas de
# onda en tools/preview/audio_overview.png para revisar sin escuchar.

extends SceneTree

const Synth := preload("res://tools/audio/synth.gd")
const Sfx := preload("res://tools/audio/sfx_catalog.gd")
const Music := preload("res://tools/audio/music_catalog.gd")

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"

var _report: Array = []
var _shapes: Array = []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var what: String = args[0] if args.size() > 0 else "all"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SFX_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MUSIC_DIR))
	for id in Sfx.ids():
		if what in ["all", "sfx", id]:
			_save(SFX_DIR, id, Sfx.make(id))
	for id in Music.ids():
		if what in ["all", "music", id]:
			_save(MUSIC_DIR, id, Music.make(id))
	_print_report()
	_draw_overview()
	quit()


func _save(dir: String, id: String, buffer: PackedFloat32Array) -> void:
	var stream: AudioStreamWAV = Synth.to_stream(buffer)
	var err: int = stream.save_to_wav(ProjectSettings.globalize_path(dir + id + ".wav"))
	var peak := 0.0
	var sum_sq := 0.0
	var clipped := 0
	for v in buffer:
		peak = maxf(peak, absf(v))
		sum_sq += v * v
		if absf(v) >= 0.999:
			clipped += 1
	var seam: float = absf(buffer[0] - buffer[buffer.size() - 1]) if Music.is_loop(id) else 0.0
	_report.append([id, buffer.size() / float(Synth.RATE), peak, sqrt(sum_sq / buffer.size()), clipped, seam, err])
	_shapes.append([id, buffer])


func _print_report() -> void:
	print("%-26s %6s %6s %6s %7s %6s" % ["id", "dur s", "pico", "rms", "recorte", "costura"])
	var total_bytes := 0
	for r in _report:
		total_bytes += int(r[1] * Synth.RATE * 2)
		var flag: String = "  <-- ERROR al guardar" if r[6] != OK else ""
		print("%-26s %6.2f %6.2f %6.3f %7d %6.3f%s" % [r[0], r[1], r[2], r[3], r[4], r[5], flag])
	print("Total: %d archivos, %.1f MB" % [_report.size(), total_bytes / 1048576.0])


## Imagen con la envolvente de cada sonido (una fila por sonido): sirve para revisar que
## nada sea silencio, ni se salga de nivel, ni tenga cortes bruscos.
func _draw_overview() -> void:
	var w := 640
	var row := 34
	var img := Image.create(w, row * _shapes.size(), false, Image.FORMAT_RGB8)
	img.fill(Color("14161f"))
	for r in _shapes.size():
		var buffer: PackedFloat32Array = _shapes[r][1]
		var per_px: int = maxi(buffer.size() / w, 1)
		var mid: int = r * row + row / 2
		for x in w:
			var peak := 0.0
			for i in range(x * per_px, mini((x + 1) * per_px, buffer.size())):
				peak = maxf(peak, absf(buffer[i]))
			var h: int = int(peak * (row / 2.0 - 1.0))
			for y in range(mid - h, mid + h + 1):
				img.set_pixel(x, y, Color("5ab4ff") if Music.is_loop(_shapes[r][0]) else Color("ffc83d"))
	img.save_png(ProjectSettings.globalize_path("res://tools/preview/audio_overview.png"))
