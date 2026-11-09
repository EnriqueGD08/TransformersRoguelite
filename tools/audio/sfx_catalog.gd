# sfx_catalog.gd
# Herramienta de desarrollo: recetas de todos los efectos de sonido del juego.
# SRP: solo describe CÓMO suena cada identificador (usando synth.gd). No escribe archivos.
# Los identificadores son los que el juego pide por EventBus.play_sfx (más algunos nuevos:
# enemy_hit, player_hit, ui_click, skill_unlock, wave_start, wave_complete).

extends RefCounted

const S := preload("res://tools/audio/synth.gd")

## Cada personaje suena distinto: tono base (Hz), onda y brillo extra.
const PROFILES := {
	"optimus": {"base": 92.0, "kind": "saw", "color": 0.0},
	"bumblebee": {"base": 230.0, "kind": "square", "color": 0.6},
	"megatron": {"base": 66.0, "kind": "saw", "color": 0.0},
	"starscream": {"base": 300.0, "kind": "saw", "color": 1.0},
	"arcee": {"base": 190.0, "kind": "tri", "color": 0.8},
	"shockwave": {"base": 58.0, "kind": "square", "color": 0.3},
}

const CHARACTER_EVENTS := ["transform", "revert", "death"]

const OTHER := [
	"starscream_bomb", "megatron_charged_shot", "arcee_dash", "arcee_swap", "revive",
	"energon_pickup", "shop_buy", "boss_shot", "boss_phase2", "boss_death", "constructicon_fury",
	"vehicon_death", "seeker_death", "constructicon_death",
	"axe_optimus_fire", "stingers_bee_fire", "fusion_cannon_fire", "null_ray_fire",
	"shockwave_cannon_fire", "photon_pistols_fire", "twin_blades_fire",
	"vehicon_attack", "seeker_attack", "constructicon_attack", "boss_brawl_attack",
	"boss_devastator_attack", "boss_soundwave_attack", "boss_galvatron_attack",
	"enemy_hit", "player_hit", "ui_click", "skill_unlock", "wave_start", "wave_complete",
]


static func ids() -> Array:
	var out: Array = []
	for who in PROFILES:
		for event in CHARACTER_EVENTS:
			out.append("%s_%s" % [who, event])
	out.append_array(OTHER)
	return out


## Volumen relativo del sonido (1 = el más fuerte): lo frecuente suena más bajo.
static func level(id: String) -> float:
	if id in ["enemy_hit", "ui_click", "energon_pickup"]:
		return 0.45
	if id.ends_with("_fire") or id.ends_with("_attack") or id in ["player_hit", "arcee_swap", "boss_shot"]:
		return 0.65
	return 0.9


static func make(id: String) -> PackedFloat32Array:
	S.seed_with(hash(id))
	var buffer: PackedFloat32Array = _recipe(id)
	return S.fade(S.normalize(buffer, level(id)))

# ── Recetas ───────────────────────────────────────────────────────────────────

static func _recipe(id: String) -> PackedFloat32Array:
	for who in PROFILES:
		if id.begins_with(who + "_"):
			match id.trim_prefix(who + "_"):
				"transform":
					return _transform(PROFILES[who])
				"revert":
					return S.reverse(_transform(PROFILES[who]))
				"death":
					return _character_death(PROFILES[who])
	match id:
		"starscream_bomb":
			var b: PackedFloat32Array = S.sweep(0.6, 2600.0, 380.0, "sine", 0.4, 1.0, 1.5)
			return S.mix(b, _explosion(1.3, 2.0), 0.55)
		"megatron_charged_shot":
			var c: PackedFloat32Array = S.sweep(0.45, 80.0, 700.0, "saw", 0.5, 2.0, 0.0)
			c = S.mix(c, S.sweep(0.45, 160.0, 1400.0, "square", 0.2, 2.0, 0.0))
			return S.mix(c, _boom(0.7, 1.4), 0.45)
		"arcee_dash":
			var d: PackedFloat32Array = S.noise(0.32, 400.0, 7000.0, 200.0, 0.9, 6.0)
			return S.mix(d, S.sweep(0.25, 400.0, 1300.0, "tri", 0.3, 1.0, 8.0), 0.0)
		"arcee_swap":
			var a: PackedFloat32Array = S.sweep(0.05, 1500.0, 1400.0, "square", 0.5, 1.0, 55.0)
			return S.mix(a, S.sweep(0.05, 2100.0, 2000.0, "square", 0.5, 1.0, 55.0), 0.08)
		"revive":
			return _arpeggio([72, 76, 79, 84, 88], "sine", 0.09, 0.45, true)
		"energon_pickup":
			var e: PackedFloat32Array = S.sweep(0.13, 900.0, 1800.0, "sine", 0.6, 1.0, 12.0)
			return S.mix(e, S.sweep(0.11, 1350.0, 2700.0, "sine", 0.3, 1.0, 14.0), 0.04)
		"shop_buy":
			var p: PackedFloat32Array = S.note(0.2, 1568.0, "sine", 0.6, 12.0)
			p = S.mix(p, S.note(0.45, 2093.0, "sine", 0.6, 8.0), 0.08)
			return S.mix(p, S.note(0.4, 4186.0, "sine", 0.15, 10.0), 0.08)
		"boss_shot":
			return S.sweep(0.2, 1500.0, 380.0, "saw", 0.5, 1.5, 12.0)
		"boss_phase2":
			return _roar(1.3)
		"constructicon_fury":
			return _roar(0.7)
		"boss_death":
			var big: PackedFloat32Array = _explosion(2.4, 3.0)
			big = S.mix(big, _explosion(1.2, 2.0), 0.5)
			big = S.mix(big, _explosion(1.0, 2.0), 1.0)
			return S.mix(big, S.noise(2.0, 600.0, 120.0, 0.0, 0.5, 1.2), 0.3)
		"vehicon_death":
			return _explosion(0.45, 1.0)
		"seeker_death":
			var s: PackedFloat32Array = S.noise(0.3, 7000.0, 1200.0, 800.0, 0.6, 9.0)
			s = S.mix(s, S.sweep(0.3, 1200.0, 200.0, "saw", 0.4, 1.5, 9.0))
			return S.mix(s, _explosion(0.35, 1.0), 0.22)
		"constructicon_death":
			var k: PackedFloat32Array = _explosion(0.9, 2.0)
			return S.mix(k, S.noise(0.5, 500.0, 120.0, 0.0, 0.5, 5.0), 0.3)
		"axe_optimus_fire":
			var x: PackedFloat32Array = S.noise(0.24, 600.0, 5200.0, 300.0, 0.8, 8.0, 0.02)
			return S.mix(x, S.sweep(0.12, 200.0, 70.0, "sine", 0.7, 1.0, 14.0), 0.1)
		"stingers_bee_fire":
			var z: PackedFloat32Array = S.sweep(0.08, 950.0, 300.0, "square", 0.5, 1.0, 30.0)
			return S.mix(z, S.noise(0.05, 3500.0, 3500.0, 1500.0, 0.4, 35.0))
		"fusion_cannon_fire":
			var f: PackedFloat32Array = S.saturate(S.sweep(0.4, 320.0, 40.0, "saw", 0.8, 0.6, 6.0), 2.0)
			return S.mix(f, S.noise(0.22, 3200.0, 300.0, 0.0, 0.5, 12.0))
		"null_ray_fire":
			var n: PackedFloat32Array = S.sweep(0.26, 1900.0, 300.0, "saw", 0.5, 2.0, 8.0)
			return S.mix(n, S.sweep(0.26, 950.0, 200.0, "sine", 0.5, 2.0, 8.0))
		"shockwave_cannon_fire":
			var w: PackedFloat32Array = S.sweep(0.55, 130.0, 38.0, "sine", 1.0, 0.5, 4.0)
			return S.mix(w, S.noise(0.38, 1500.0, 200.0, 0.0, 0.5, 7.0))
		"photon_pistols_fire":
			return S.sweep(0.13, 2300.0, 700.0, "pulse25", 0.5, 2.0, 18.0)
		"twin_blades_fire":
			var t: PackedFloat32Array = S.noise(0.16, 2000.0, 9000.0, 1500.0, 0.7, 12.0, 0.01)
			return S.mix(t, S.sweep(0.22, 3300.0, 3100.0, "sine", 0.25, 1.0, 13.0))
		"vehicon_attack":
			return S.noise(0.16, 1600.0, 6500.0, 800.0, 0.7, 12.0, 0.012)
		"seeker_attack":
			return S.sweep(0.16, 1150.0, 480.0, "square", 0.4, 1.5, 14.0)
		"constructicon_attack":
			return _thud(0.32, 95.0, 1.0)
		"boss_brawl_attack":
			return S.mix(_thud(0.3, 100.0, 1.0), S.noise(0.18, 1500.0, 5000.0, 600.0, 0.4, 14.0, 0.01), 0.0)
		"boss_devastator_attack":
			return S.mix(_thud(0.55, 70.0, 1.3), S.noise(0.4, 900.0, 150.0, 0.0, 0.5, 6.0), 0.02)
		"boss_soundwave_attack":
			var u: PackedFloat32Array = S.sweep(0.32, 700.0, 200.0, "square", 0.45, 1.0, 6.0)
			return S.mix(u, S.sweep(0.32, 1400.0, 420.0, "pulse25", 0.25, 1.0, 6.0))
		"boss_galvatron_attack":
			var g: PackedFloat32Array = S.saturate(S.sweep(0.42, 620.0, 60.0, "saw", 0.7, 1.0, 5.0), 1.8)
			return S.mix(g, S.noise(0.25, 3000.0, 400.0, 0.0, 0.4, 10.0))
		"enemy_hit":
			var h: PackedFloat32Array = S.noise(0.06, 4200.0, 1000.0, 300.0, 0.8, 38.0)
			return S.mix(h, S.sweep(0.07, 260.0, 100.0, "sine", 0.6, 1.0, 38.0))
		"player_hit":
			var q: PackedFloat32Array = S.sweep(0.2, 230.0, 60.0, "saw", 0.6, 1.0, 12.0)
			return S.mix(q, S.noise(0.13, 2600.0, 400.0, 0.0, 0.5, 20.0))
		"ui_click":
			return S.sweep(0.05, 1250.0, 800.0, "square", 0.4, 1.0, 50.0)
		"skill_unlock":
			return _arpeggio([76, 79, 83, 88], "tri", 0.07, 0.4, true)
		"wave_start":
			var wv: PackedFloat32Array = S.saturate(S.note(0.5, 110.0, "saw", 0.6, 3.0, 0.03, 0.01), 1.6)
			wv = S.mix(wv, S.saturate(S.note(0.7, 165.0, "saw", 0.6, 2.5, 0.03, 0.01), 1.6), 0.25)
			return S.mix(wv, S.noise(0.5, 400.0, 2500.0, 0.0, 0.25, 3.0, 0.2), 0.0)
		"wave_complete":
			return _arpeggio([72, 76, 79, 84], "tri", 0.11, 0.6, false)
	push_error("sfx_catalog: no hay receta para '%s'" % id)
	return S.silence(0.1)

# ── Piezas reutilizables ──────────────────────────────────────────────────────

## Transformación: clics mecánicos, un servo que sube y un acorde final.
static func _transform(p: Dictionary) -> PackedFloat32Array:
	var base: float = p.base
	var kind: String = p.kind
	var out: PackedFloat32Array = S.silence(1.05)
	for i in 8:
		var hz_shift: float = 1.0 + 0.15 * float(i % 3)
		out = S.mix(out, S.noise(0.05, 5200.0 * hz_shift, 1500.0, 800.0, 0.55, 40.0), float(i) * 0.075)
		out = S.mix(out, S.sweep(0.05, base * 4.0 * hz_shift, base * 3.0, "square", 0.12, 1.0, 40.0), float(i) * 0.075)
	out = S.mix(out, S.sweep(0.75, base, base * 4.0, kind, 0.45, 2.0, 1.0), 0.1)
	out = S.mix(out, S.sweep(0.6, base * 0.5, base * 0.8, "square", 0.2, 1.0, 2.0), 0.0)
	if p.color > 0.0:
		out = S.mix(out, S.noise(0.8, 700.0, 6000.0, 400.0, 0.25 * p.color, 2.0, 0.2), 0.05)
	out = S.mix(out, S.note(0.4, base * 4.0, kind, 0.3, 6.0), 0.68)
	out = S.mix(out, S.note(0.4, base * 6.0, kind, 0.2, 6.0), 0.68)
	return S.saturate(out, 1.3)


## Muerte de un personaje: se viene abajo, chatarra y apagado.
static func _character_death(p: Dictionary) -> PackedFloat32Array:
	var base: float = p.base
	var out: PackedFloat32Array = S.sweep(0.95, base * 3.0, base * 0.4, p.kind, 0.6, 1.5, 3.0)
	out = S.mix(out, S.noise(0.9, 4000.0, 300.0, 0.0, 0.7, 4.0))
	for t in [0.15, 0.4, 0.62]:
		out = S.mix(out, S.sweep(0.12, 900.0 + t * 400.0, 500.0, "square", 0.3, 1.0, 20.0), t)
	return S.mix(out, S.sweep(0.7, 200.0, 38.0, "sine", 0.7, 1.0, 3.0), 0.3)


## Explosión: estallido de ruido que se apaga y un golpe grave. 'size' = tamaño (1 = pequeña).
static func _explosion(dur: float, size: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = S.noise(dur, 6500.0, 180.0, 0.0, 1.0, 3.5 / maxf(size * 0.7, 0.5), 0.003)
	return S.mix(out, _boom(dur * 0.85, size), 0.0, 0.9)


static func _boom(dur: float, size: float) -> PackedFloat32Array:
	return S.sweep(dur, 130.0 / maxf(size * 0.6, 0.5), 28.0, "sine", 1.0, 0.5, 3.0)


## Golpe sordo contra el suelo.
static func _thud(dur: float, hz: float, size: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = S.sweep(dur, hz, hz * 0.4, "sine", 1.0, 0.7, 8.0 / size)
	return S.mix(out, S.noise(dur * 0.6, 900.0, 200.0, 0.0, 0.5, 12.0))


## Rugido: gruñido grave que sube con ruido áspero.
static func _roar(dur: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = S.saturate(S.sweep(dur, 80.0, 150.0, "saw", 0.7, 0.8, 1.3, 0.05), 2.4)
	out = S.mix(out, S.noise(dur, 1300.0, 600.0, 100.0, 0.4, 1.3, 0.05))
	return S.mix(out, S.sweep(dur, 200.0, 850.0, "saw", 0.25, 2.0, 1.0, 0.05))


## Arpegio de notas MIDI (campanillas); 'hold' alarga la última.
static func _arpeggio(notes: Array, kind: String, step: float, vol: float, shimmer: bool) -> PackedFloat32Array:
	var out: PackedFloat32Array = S.silence(0.1)
	for i in notes.size():
		var last: bool = i == notes.size() - 1
		var hz: float = S.midi_to_hz(notes[i])
		out = S.mix(out, S.note(0.5 if last else 0.18, hz, kind, vol, 5.0 if last else 9.0), step * i)
		if shimmer:
			out = S.mix(out, S.note(0.4, hz * 2.0, "sine", vol * 0.25, 8.0), step * i + 0.01)
	return out
