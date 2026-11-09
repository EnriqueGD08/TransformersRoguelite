# music_catalog.gd
# Herramienta de desarrollo: pistas de música del juego, compuestas por código.
# SRP: solo describe y renderiza las pistas (usando synth.gd). No escribe archivos.
# Cada pista en bucle es una secuencia de 16 compases con una progresión de 4 acordes:
# bajo, arpegio, acordes de fondo, batería y (en las más intensas) una melodía.
# La segunda mitad (compases 8 a 15) añade capas para que el bucle no aburra.

extends RefCounted

const S := preload("res://tools/audio/synth.gd")

## Pistas en bucle. root = nota MIDI del bajo; prog = (semitonos sobre la raíz, "m" o "M").
## drums: 0 sin batería, 1 base, 2 con hi-hat de semicorcheas. lead: 0 sin melodía, 1 con ella.
const LOOPS := {
	"menu": {"bpm": 92.0, "root": 45, "prog": [[0, "m"], [8, "M"], [3, "M"], [10, "M"]],
		"drums": 0, "lead": 0, "arp": 1, "bass": 0, "drive": 1.0},
	"battle_1": {"bpm": 126.0, "root": 45, "prog": [[0, "m"], [8, "M"], [3, "M"], [10, "M"]],
		"drums": 1, "lead": 0, "arp": 2, "bass": 1, "drive": 1.2},
	"battle_2": {"bpm": 134.0, "root": 50, "prog": [[0, "m"], [10, "M"], [8, "M"], [7, "m"]],
		"drums": 1, "lead": 0, "arp": 2, "bass": 1, "drive": 1.3},
	"battle_3": {"bpm": 142.0, "root": 40, "prog": [[0, "m"], [1, "M"], [0, "m"], [10, "M"]],
		"drums": 2, "lead": 1, "arp": 2, "bass": 2, "drive": 1.5},
	"battle_4": {"bpm": 150.0, "root": 41, "prog": [[0, "m"], [8, "M"], [10, "M"], [7, "M"]],
		"drums": 2, "lead": 1, "arp": 2, "bass": 2, "drive": 1.7},
	"battle_boss": {"bpm": 168.0, "root": 37, "prog": [[0, "m"], [0, "m"], [8, "M"], [1, "M"]],
		"drums": 2, "lead": 1, "arp": 2, "bass": 2, "drive": 2.0},
}

const ONE_SHOTS := ["victory", "game_over"]

const BARS := 16

## Melodía de 2 compases (paso de 16, grado de la escala pentatónica menor, duración en pasos).
const LEAD_RIFF := [[0, 4, 3], [4, 3, 1], [6, 2, 2], [8, 4, 3], [12, 5, 2], [14, 3, 2],
	[16, 4, 3], [20, 2, 1], [22, 3, 2], [24, 5, 3], [28, 4, 2], [30, 2, 2]]
const PENTATONIC := [0, 3, 5, 7, 10, 12, 15, 17]


static func ids() -> Array:
	var out: Array = LOOPS.keys()
	out.append_array(ONE_SHOTS)
	return out


static func is_loop(id: String) -> bool:
	return LOOPS.has(id)


static func make(id: String) -> PackedFloat32Array:
	S.seed_with(hash(id))
	match id:
		"victory":
			return _victory()
		"game_over":
			return _game_over()
	return _loop(LOOPS[id])

# ── Bucles ────────────────────────────────────────────────────────────────────

static func _loop(cfg: Dictionary) -> PackedFloat32Array:
	var beat: float = 60.0 / cfg.bpm
	var step: float = beat / 4.0
	var bar: float = beat * 4.0
	var length: float = bar * BARS
	var tail := 1.5

	var bass: PackedFloat32Array = S.silence(length + tail)
	var arp: PackedFloat32Array = S.silence(length + tail)
	var pad: PackedFloat32Array = S.silence(length + tail)
	var lead: PackedFloat32Array = S.silence(length + tail)
	var drums: PackedFloat32Array = S.silence(length + tail)

	for b in BARS:
		var t0: float = b * bar
		var chord: Array = cfg.prog[b % 4]
		var root: int = cfg.root + chord[0]
		var third: int = 3 if chord[1] == "m" else 4
		var tones: Array = [root, root + third, root + 7]
		var second_half: bool = b >= 8

		# Bajo
		if cfg.bass == 0:
			bass = S.mix(bass, S.note(bar * 0.98, S.midi_to_hz(root), "tri", 0.8, 0.8, 0.02), t0)
		else:
			var hits: Array = [0, 3, 6, 8, 11, 14] if cfg.bass == 1 else [0, 2, 4, 6, 8, 10, 12, 14]
			for s in hits:
				var up: bool = (s % 8) == 6
				var n: float = S.midi_to_hz(root + (12 if up else 0))
				bass = S.mix(bass, S.note(step * 1.6, n, "saw", 0.8, 5.0, 0.003), t0 + s * step)

		# Acordes de fondo
		for n in tones:
			pad = S.mix(pad, S.note(bar * 1.02, S.midi_to_hz(n + 12), "saw", 0.12, 0.3, 0.25, 0.006), t0)

		# Arpegio (más denso en la segunda mitad)
		if cfg.arp > 0:
			var pattern: Array = [0, 1, 2, 3, 2, 1, 2, 1, 0, 1, 2, 3, 2, 1, 2, 3]
			var skip: int = 2 if (cfg.arp == 1 and not second_half) else 1
			for s in range(0, 16, skip):
				var idx: int = pattern[s]
				var midi: int = tones[idx % 3] + 12 + (12 if idx == 3 else 0)
				arp = S.mix(arp, S.note(step * 1.4, S.midi_to_hz(midi), "pulse25", 0.35, 9.0, 0.002), t0 + s * step)

		# Batería
		if cfg.drums > 0:
			for s in [0, 4, 8, 12]:
				drums = S.mix(drums, _kick(), t0 + s * step, 1.0)
			if b >= 2:
				for s in [4, 12]:
					drums = S.mix(drums, _snare(), t0 + s * step, 0.8)
			var hat_steps: Array = [2, 6, 10, 14]
			if cfg.drums == 2 and second_half:
				hat_steps = range(0, 16, 1)
			for s in hat_steps:
				var accent: float = 0.5 if s % 4 == 2 else 0.28
				drums = S.mix(drums, _hat(s % 8 == 6), t0 + s * step, accent)

	# Melodía: el riff de 2 compases en la segunda mitad (y en toda la pista si es la más intensa)
	if cfg.lead > 0:
		var riff_bars: int = BARS / 2
		for r in riff_bars:
			var base_t: float = (8 + r * 2) * bar if r < 4 else 0.0
			if r >= 4:
				break
			var chord: Array = cfg.prog[(8 + r * 2) % 4]
			var root: int = cfg.root + chord[0] + 24
			for ev in LEAD_RIFF:
				var midi: int = root + PENTATONIC[ev[1]]
				lead = S.mix(lead, S.note(step * ev[2] * 1.2, S.midi_to_hz(midi), "square", 0.28, 4.0, 0.005, 0.004), base_t + ev[0] * step)

	bass = S.lowpass(bass, 900.0)
	pad = S.lowpass(pad, 1800.0)
	arp = S.echo(arp, step * 3.0, 0.38, 0.4)
	lead = S.echo(lead, step * 3.0, 0.4, 0.45)
	var out: PackedFloat32Array = S.silence(length + tail)
	out = S.mix(out, bass, 0.0, 0.9)
	out = S.mix(out, pad, 0.0, 0.8)
	out = S.mix(out, arp, 0.0, 0.7)
	out = S.mix(out, lead, 0.0, 0.7)
	out = S.mix(out, drums, 0.0, 0.85)
	out = S.saturate(out, cfg.drive)
	# Se normaliza DESPUÉS de cerrar el bucle: sumar la cola al principio puede subir el pico.
	return S.normalize(_close_loop(out, length), 0.8)


## Para que el bucle no tenga corte: lo que sobra al final (la cola) se suma al principio.
static func _close_loop(buffer: PackedFloat32Array, length: float) -> PackedFloat32Array:
	var n: int = int(length * S.RATE)
	for i in range(n, buffer.size()):
		buffer[i - n] += buffer[i]
	buffer.resize(n)
	return buffer

# ── Batería ───────────────────────────────────────────────────────────────────

static func _kick() -> PackedFloat32Array:
	var k: PackedFloat32Array = S.sweep(0.22, 160.0, 42.0, "sine", 1.0, 0.35, 11.0, 0.001)
	return S.mix(k, S.noise(0.015, 6000.0, 6000.0, 1500.0, 0.4, 80.0))


static func _snare() -> PackedFloat32Array:
	var s: PackedFloat32Array = S.noise(0.18, 8000.0, 3000.0, 1200.0, 0.8, 17.0, 0.001)
	return S.mix(s, S.sweep(0.1, 220.0, 150.0, "tri", 0.5, 1.0, 25.0))


static func _hat(open: bool) -> PackedFloat32Array:
	return S.noise(0.12 if open else 0.04, 11000.0, 11000.0, 6000.0, 0.7, 14.0 if open else 55.0, 0.001)

# ── Fanfarria y derrota ───────────────────────────────────────────────────────

static func _victory() -> PackedFloat32Array:
	var out: PackedFloat32Array = S.silence(6.5)
	var seq: Array = [60, 64, 67, 72, 76, 79, 84]
	for i in seq.size():
		var hz: float = S.midi_to_hz(seq[i])
		out = S.mix(out, S.note(0.35, hz, "square", 0.35, 5.0), i * 0.14)
		out = S.mix(out, S.note(0.35, hz * 0.5, "saw", 0.3, 5.0), i * 0.14)
	# Acorde final sostenido
	for n in [60, 64, 67, 72, 79]:
		out = S.mix(out, S.note(3.8, S.midi_to_hz(n), "saw", 0.28, 0.9, 0.01, 0.004), 1.05)
		out = S.mix(out, S.note(3.8, S.midi_to_hz(n + 12), "sine", 0.18, 0.9), 1.05)
	out = S.mix(out, _kick(), 1.05, 1.0)
	out = S.mix(out, _snare(), 1.05, 0.8)
	out = S.mix(out, S.noise(2.5, 5000.0, 9000.0, 3000.0, 0.15, 1.2, 0.05), 1.05)
	out = S.echo(out, 0.27, 0.35, 0.35)
	return S.fade(S.normalize(S.saturate(out, 1.3), 0.8), 0.003, 0.5)


static func _game_over() -> PackedFloat32Array:
	var out: PackedFloat32Array = S.silence(7.0)
	var seq: Array = [69, 65, 62, 57, 50]
	for i in seq.size():
		var hz: float = S.midi_to_hz(seq[i])
		out = S.mix(out, S.note(1.0 if i < 4 else 2.6, hz, "tri", 0.55, 1.6, 0.01), i * 0.7)
		out = S.mix(out, S.note(1.0 if i < 4 else 2.6, hz * 0.5, "sine", 0.4, 1.4), i * 0.7)
	out = S.mix(out, S.note(6.0, S.midi_to_hz(33), "saw", 0.25, 0.5, 0.4), 0.0)
	out = S.mix(out, S.noise(5.0, 600.0, 120.0, 0.0, 0.25, 0.8, 0.4), 0.0)
	out = S.lowpass(out, 2500.0)
	out = S.echo(out, 0.4, 0.4, 0.4)
	return S.fade(S.normalize(out, 0.75), 0.01, 1.2)
