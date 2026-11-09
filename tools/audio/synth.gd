# synth.gd
# Herramienta de desarrollo: sintetizador mínimo para crear sonidos y música por código.
# SRP: solo genera muestras de audio (osciladores, ruido, filtros, envolventes y mezcla);
#      no sabe qué sonido es cada cosa (eso lo dicen sfx_catalog.gd y music_catalog.gd).
# Todo es mono, a RATE Hz, con muestras entre -1 y 1 en un PackedFloat32Array.

extends RefCounted

const RATE := 22050

## Generador de números aleatorios con semilla fija: el mismo sonido sale igual cada vez.
static var _rng := RandomNumberGenerator.new()


static func seed_with(value: int) -> void:
	_rng.seed = value


static func silence(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	return out

# ── Osciladores ───────────────────────────────────────────────────────────────

## Onda de 'kind' en la fase 'p' (en ciclos): sine, square, pulse25, saw, tri.
static func wave(kind: String, p: float) -> float:
	p -= floorf(p)
	match kind:
		"sine":
			return sin(TAU * p)
		"square":
			return 1.0 if p < 0.5 else -1.0
		"pulse25":
			return 1.0 if p < 0.25 else -1.0
		"saw":
			return 2.0 * p - 1.0
		"tri":
			return 4.0 * absf(p - 0.5) - 1.0
	return 0.0


static func midi_to_hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)


## Tono que se desliza de f0 a f1 Hz durante 'dur' segundos.
## curve > 1 hace el cambio más brusco al principio; decay es la caída de volumen por segundo.
static func sweep(dur: float, f0: float, f1: float, kind: String = "sine", vol: float = 1.0,
		curve: float = 1.0, decay: float = 4.0, attack: float = 0.004) -> PackedFloat32Array:
	var out := silence(dur)
	var phase := 0.0
	var n := out.size()
	for i in n:
		var t: float = float(i) / RATE
		var k: float = pow(t / dur, curve)
		var f: float = f0 * pow(f1 / f0, k)
		phase += f / RATE
		var env: float = minf(t / attack, 1.0) * exp(-t * decay) * minf((dur - t) / 0.01, 1.0)
		out[i] = wave(kind, phase) * env * vol
	return out


## Ruido blanco filtrado: el filtro paso bajo recorre de lp0 a lp1 Hz; hp es un paso alto fijo.
static func noise(dur: float, lp0: float = 8000.0, lp1: float = 8000.0, hp: float = 0.0,
		vol: float = 1.0, decay: float = 6.0, attack: float = 0.002) -> PackedFloat32Array:
	var out := silence(dur)
	var lp := 0.0
	var hp_state := 0.0
	var hp_a: float = 1.0 - exp(-TAU * hp / RATE) if hp > 0.0 else 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		var fc: float = lerpf(lp0, lp1, t / dur)
		var a: float = 1.0 - exp(-TAU * fc / RATE)
		var x: float = _rng.randf_range(-1.0, 1.0)
		lp += a * (x - lp)
		var y: float = lp
		if hp > 0.0:
			hp_state += hp_a * (y - hp_state)
			y -= hp_state
		var env: float = minf(t / attack, 1.0) * exp(-t * decay) * minf((dur - t) / 0.01, 1.0)
		out[i] = y * env * vol
	return out


## Nota con armónicos: 'kind' a la frecuencia 'hz', con ataque corto y caída exponencial.
static func note(dur: float, hz: float, kind: String = "saw", vol: float = 1.0, decay: float = 3.0,
		attack: float = 0.004, detune: float = 0.0) -> PackedFloat32Array:
	var out := silence(dur)
	var p1 := 0.0
	var p2 := 0.0
	for i in out.size():
		var t: float = float(i) / RATE
		p1 += hz / RATE
		p2 += hz * (1.0 + detune) / RATE
		var s: float = wave(kind, p1)
		if detune != 0.0:
			s = (s + wave(kind, p2)) * 0.5
		var env: float = minf(t / attack, 1.0) * exp(-t * decay) * minf((dur - t) / 0.015, 1.0)
		out[i] = s * env * vol
	return out

# ── Efectos sobre un buffer ───────────────────────────────────────────────────

## Filtro paso bajo de un polo (modifica el buffer).
static func lowpass(buffer: PackedFloat32Array, cutoff: float) -> PackedFloat32Array:
	var a: float = 1.0 - exp(-TAU * cutoff / RATE)
	var y := 0.0
	for i in buffer.size():
		y += a * (buffer[i] - y)
		buffer[i] = y
	return buffer


## Eco: repite el sonido cada 'delay' segundos con 'feedback' y lo mezcla con 'wet'.
static func echo(buffer: PackedFloat32Array, delay: float, feedback: float = 0.35, wet: float = 0.35) -> PackedFloat32Array:
	var d: int = int(delay * RATE)
	var out := buffer.duplicate()
	for i in range(d, buffer.size()):
		out[i] += out[i - d] * feedback
	for i in buffer.size():
		out[i] = buffer[i] * (1.0 - wet * 0.5) + (out[i] - buffer[i]) * wet
	return out


## Distorsión suave (tanh): da "mordiente" y evita que se pase de volumen.
static func saturate(buffer: PackedFloat32Array, drive: float = 2.0) -> PackedFloat32Array:
	for i in buffer.size():
		buffer[i] = tanh(buffer[i] * drive) / tanh(drive)
	return buffer


static func reverse(buffer: PackedFloat32Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(buffer.size())
	var n := buffer.size()
	for i in n:
		out[i] = buffer[n - 1 - i]
	return out


## Sube o baja el volumen para que el pico sea 'peak'.
static func normalize(buffer: PackedFloat32Array, peak: float = 0.9) -> PackedFloat32Array:
	var m := 0.0
	for v in buffer:
		m = maxf(m, absf(v))
	if m > 0.0001:
		var g: float = peak / m
		for i in buffer.size():
			buffer[i] *= g
	return buffer


## Entrada y salida suaves (evita clics al empezar y terminar).
static func fade(buffer: PackedFloat32Array, fade_in: float = 0.003, fade_out: float = 0.02) -> PackedFloat32Array:
	var n := buffer.size()
	var a: int = int(fade_in * RATE)
	var b: int = int(fade_out * RATE)
	for i in mini(a, n):
		buffer[i] *= float(i) / maxf(a, 1)
	for i in mini(b, n):
		buffer[n - 1 - i] *= float(i) / maxf(b, 1)
	return buffer

# ── Mezcla ────────────────────────────────────────────────────────────────────

## Suma 'src' en 'dst' a partir de 'at' segundos con ganancia 'gain'. Amplía dst si hace falta.
static func mix(dst: PackedFloat32Array, src: PackedFloat32Array, at: float = 0.0, gain: float = 1.0) -> PackedFloat32Array:
	var start: int = int(at * RATE)
	if dst.size() < start + src.size():
		dst.resize(start + src.size())
	for i in src.size():
		dst[start + i] += src[i] * gain
	return dst

# ── Salida ────────────────────────────────────────────────────────────────────

## Convierte el buffer en un AudioStreamWAV de 16 bits.
static func to_stream(buffer: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buffer.size() * 2)
	for i in buffer.size():
		var v: int = clampi(int(roundf(buffer[i] * 32767.0)), -32768, 32767)
		bytes.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream
