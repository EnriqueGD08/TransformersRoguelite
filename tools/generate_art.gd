# generate_art.gd
# Herramienta de desarrollo (no forma parte del juego).
# Genera TODOS los fotogramas pixel art de los personajes/enemigos con el pintor
# procedural (tools/art/*) y construye los SpriteFrames de cada skin.
#
# Uso (desde la raíz del proyecto):
#   godot --headless -s tools/generate_art.gd -- png      # dibuja PNG + hojas de previsualización
#   godot --headless --import                              # importa los PNG en Godot
#   godot --headless -s tools/generate_art.gd -- frames   # crea resources/frames/*.tres
#
# Cuando haya arte definitivo basta con sustituir los SpriteFrames de cada skin.

extends SceneTree

const P := preload("res://tools/art/painter.gd")
const OptimusArt := preload("res://tools/art/optimus_art.gd")
const VehiconArt := preload("res://tools/art/vehicon_art.gd")
const BeeArt := preload("res://tools/art/bumblebee_art.gd")
const MegaArt := preload("res://tools/art/megatron_art.gd")
const FxArt := preload("res://tools/art/fx_art.gd")
const StarArt := preload("res://tools/art/starscream_art.gd")
const ArceeArt := preload("res://tools/art/arcee_art.gd")
const ShockArt := preload("res://tools/art/shockwave_art.gd")

const OUT_ROOT := "res://assets/sprites/"
const FRAMES_DIR := "res://resources/frames/"
const PREVIEW_DIR := "res://tools/preview/"

# Animación -> [fps, loop]
const ANIM_META := {
	"idle": [5.0, true],
	"walk": [10.0, true],
	"attack": [16.0, false],
	"attack_finisher": [12.0, false],
	"ranged_idle": [5.0, true],
	"ranged_walk": [10.0, true],
	"ranged_attack": [16.0, false],
	"transform_activate": [10.0, false],
	"transform_idle": [8.0, true],
	"transform_walk": [14.0, true],
	"transform_attack": [14.0, false],
	"death": [8.0, false],
	"fly": [14.0, true],
	"explode": [16.0, false],
}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else ""
	match mode:
		"png": _make_pngs()
		"frames": _make_frames()
		"zoom": _zoom(args)
		_: push_error("Uso: -- png | frames")
	quit()

# ── Catálogo de sprites ───────────────────────────────────────────────────────

## Devuelve { "personaje/skin": { anim: [Image] } }.
func _catalog() -> Dictionary:
	var out := {}
	for skin in OptimusArt.SKINS:
		out["optimus/" + skin] = _optimus(OptimusArt.SKINS[skin])
	for skin in BeeArt.SKINS:
		out["bumblebee/" + skin] = _bumblebee(BeeArt.SKINS[skin])
	for skin in MegaArt.SKINS:
		out["megatron/" + skin] = _megatron(MegaArt.SKINS[skin])
	for skin in ArceeArt.SKINS:
		out["arcee/" + skin] = _arcee(ArceeArt.SKINS[skin])
	for skin in ShockArt.SKINS:
		out["shockwave/" + skin] = _shockwave(ShockArt.SKINS[skin])
	out["fx/shock_wave"] = {"fly": [FxArt.wave(0), FxArt.wave(1), FxArt.wave(2), FxArt.wave(3)]}
	out["fx/photon"] = {"fly": [FxArt.photon(0), FxArt.photon(1), FxArt.photon(2), FxArt.photon(3)]}
	for skin in StarArt.SKINS:
		out["starscream/" + skin] = _starscream(StarArt.SKINS[skin])
	out["fx/null_ray"] = {"fly": [FxArt.ray(0), FxArt.ray(1), FxArt.ray(2), FxArt.ray(3)]}
	var rh: Array = []
	for i in 6:
		rh.append(FxArt.ray_hit(i))
	out["fx/ray_hit"] = {"explode": rh}
	out["fx/fusion_bolt"] = {"fly": [FxArt.bolt(0), FxArt.bolt(1), FxArt.bolt(2), FxArt.bolt(3)]}
	out["fx/charged_shell"] = {"fly": [FxArt.shell(0), FxArt.shell(1), FxArt.shell(2), FxArt.shell(3)]}
	var ex: Array = []
	for i in 8:
		ex.append(FxArt.explosion(i))
	out["fx/explosion"] = {"explode": ex}
	out["vehicon/base"] = VehiconArt.all_anims()
	return out


func _wrap(image: Image) -> RefCounted:
	var p = P.new(image.get_width(), image.get_height())
	p.img = image
	return p


func _optimus(pal: Dictionary) -> Dictionary:
	var A := OptimusArt
	var anims := {}

	# Reposo: respira y el hacha oscila.
	var idle: Array = []
	for i in 4:
		var bob: int = [0, -1, -1, 0][i]
		idle.append(A.robot(pal, {"bob": bob, "axe": -70.0 + [0, -2, -4, -2][i]}).img)
	anims["idle"] = idle

	# Caminar.
	var walk: Array = []
	var strides := [1, 1, 0, -1, -1, 0]
	var bobs := [0, -1, 0, 0, -1, 0]
	for i in 6:
		walk.append(A.robot(pal, {"stride": strides[i], "bob": bobs[i], "axe": -72.0}).img)
	anims["walk"] = walk

	# Hachazo.
	var attack: Array = []
	var atk := [
		{"axe": -140.0, "hand": Vector2(-5, -10), "lean": -2},
		{"axe": -105.0, "hand": Vector2(-1, -13), "lean": -2},
		{"axe": -42.0, "hand": Vector2(5, -6), "lean": 2, "trail": {"from": -105.0, "to": -42.0}},
		{"axe": 20.0, "hand": Vector2(8, -2), "lean": 3, "trail": {"from": -42.0, "to": 28.0}},
		{"axe": -5.0, "hand": Vector2(4, 0), "lean": 1},
	]
	for pose in atk:
		attack.append(A.robot(pal, pose).img)
	anims["attack"] = attack

	# Camión.
	var t_idle: Array = []
	for i in 4:
		t_idle.append(A.truck(pal, {"bob": [0, 1, 0, 0][i], "smoke": i, "wheel": 0.0}).img)
	anims["transform_idle"] = t_idle
	var t_walk: Array = []
	for i in 4:
		t_walk.append(A.truck(pal, {"bob": [0, 1, 0, 1][i], "smoke": i * 2, "wheel": i * 40.0}).img)
	anims["transform_walk"] = t_walk
	var t_atk: Array = []
	for i in 4:
		t_atk.append(A.truck(pal, {"lunge": [0, 5, 9, 3][i], "burst": i == 1 or i == 2, "wheel": i * 70.0}).img)
	anims["transform_attack"] = t_atk

	# Transformación robot -> camión.
	var robot_img: Image = A.robot(pal, {"axe": -70.0}).img
	var truck_img: Image = A.truck(pal, {"smoke": 1}).img
	var pivot := Vector2(72, 93)
	var tf: Array = []
	var steps := [
		{"src": robot_img, "sx": 1.0, "sy": 1.0, "white": 0.65, "ring": 10.0},
		{"src": robot_img, "sx": 1.12, "sy": 0.86, "white": 0.4, "ring": 20.0},
		{"src": robot_img, "sx": 1.4, "sy": 0.62, "white": 0.5, "ring": 30.0},
		{"src": truck_img, "sx": 0.85, "sy": 0.68, "white": 0.55, "ring": 38.0},
		{"src": truck_img, "sx": 1.06, "sy": 1.1, "white": 0.3, "ring": 46.0},
		{"src": truck_img, "sx": 1.0, "sy": 1.0, "white": 0.0, "ring": 0.0},
	]
	for st in steps:
		var im: Image = P.xform(st.src, st.sx, st.sy, pivot)
		var w = _wrap(im)
		if st.white > 0.0:
			w.tint(Color.WHITE, st.white)
		if st.ring > 0.0:
			w.ring_px(72, 58, st.ring, st.ring * 0.8, Color(0.6, 0.95, 1.0, 0.85), 0.14)
			w.ring_px(72, 58, st.ring * 0.7, st.ring * 0.56, Color(1, 1, 1, 0.55), 0.12)
		tf.append(w.img)
	anims["transform_activate"] = tf

	# Muerte: se tambalea, se arrodilla y cae hacia atrás, apagándose.
	var death: Array = []
	var dpose := [
		{"lean": -2, "axe": -110.0, "hand": Vector2(-3, -6)},
		{"lean": -3, "kneel": 5, "axe": 60.0, "hand": Vector2(2, 4)},
		{"lean": -3, "kneel": 6, "axe": 80.0, "dead": true},
		{"lean": -3, "kneel": 6, "axe": 80.0, "dead": true},
		{"lean": -3, "kneel": 6, "axe": 80.0, "dead": true},
		{"lean": -3, "kneel": 6, "axe": 80.0, "dead": true},
	]
	var rots := [0.0, -6.0, -24.0, -52.0, -80.0, -90.0]
	var whites := [0.55, 0.2, 0.0, 0.0, 0.0, 0.0]
	var grays := [0.0, 0.15, 0.35, 0.5, 0.62, 0.7]
	for i in 6:
		var rp = A.robot(pal, dpose[i])
		if whites[i] > 0.0:
			rp.tint(Color.WHITE, whites[i])
		rp.desaturate(grays[i])
		var im: Image = rp.img
		if rots[i] != 0.0:
			im = P.xform(im, 1.0, 1.0, Vector2(72, 70), rots[i])
			im = P.ground(im, 93, 72)
		var w = _wrap(im)
		_sparks(w, i, 90 + i)
		if i >= 3:
			var smoke_y := 60 - (i - 3) * 6
			w.ellipse_px(62, smoke_y, 5, 4, Color(0.3, 0.3, 0.33, 0.45 - (i - 3) * 0.1))
			w.ellipse_px(68, smoke_y - 6, 4, 3, Color(0.35, 0.35, 0.38, 0.35 - (i - 3) * 0.08))
		death.append(w.img)
	anims["death"] = death
	return anims


func _bumblebee(pal: Dictionary) -> Dictionary:
	var A := BeeArt
	var anims := {}

	var idle: Array = []
	for i in 4:
		idle.append(A.robot(pal, {"bob": [0, -1, -1, 0][i],
			"front": Vector2(67, 49 + [0, 1, 1, 0][i]), "back": Vector2(13, 49 + [0, 1, 1, 0][i])}).img)
	anims["idle"] = idle

	var walk: Array = []
	var strides := [1, 1, 0, -1, -1, 0]
	var bobs := [0, -1, 0, 0, -1, 0]
	for i in 6:
		var sw: int = strides[i] * 3
		walk.append(A.robot(pal, {"stride": strides[i], "bob": bobs[i],
			"front": Vector2(66 - sw, 49), "back": Vector2(14 + sw, 50)}).img)
	anims["walk"] = walk

	# Jab con puño de energon.
	var attack: Array = []
	var atk := [
		{"front": Vector2(58, 50), "back": Vector2(18, 42), "lean": -2, "glow": 0.3},
		{"front": Vector2(78, 38), "back": Vector2(15, 42), "lean": 3, "glow": 1.0, "punch_ring": true},
		{"front": Vector2(80, 40), "back": Vector2(15, 42), "lean": 3, "glow": 0.8, "punch_ring": true},
		{"front": Vector2(67, 48), "back": Vector2(14, 48), "lean": 1, "glow": 0.2},
	]
	for pose in atk:
		attack.append(A.robot(pal, pose).img)
	anims["attack"] = attack

	# Remate: golpe doble contra el suelo con onda de energon.
	var fin: Array = []
	var fp := [
		{"front": Vector2(62, 14), "back": Vector2(22, 14), "bob": -1, "glow": 0.5},
		{"front": Vector2(60, 8), "back": Vector2(24, 8), "bob": -2, "glow": 0.9},
		{"front": Vector2(52, 62), "back": Vector2(36, 62), "kneel": 10, "glow": 1.0, "shock": {"r": 14.0, "a": 0.95}},
		{"front": Vector2(52, 62), "back": Vector2(36, 62), "kneel": 10, "glow": 0.7, "shock": {"r": 30.0, "a": 0.7}},
		{"front": Vector2(60, 50), "back": Vector2(22, 50), "kneel": 3, "glow": 0.2, "shock": {"r": 44.0, "a": 0.35}},
	]
	for pose in fp:
		fin.append(A.robot(pal, pose).img)
	anims["attack_finisher"] = fin

	# Coche.
	var c_idle: Array = []
	for i in 4:
		c_idle.append(A.car(pal, {"bob": [0, 1, 0, 0][i], "underglow": true}).img)
	anims["transform_idle"] = c_idle
	var c_walk: Array = []
	for i in 4:
		c_walk.append(A.car(pal, {"bob": [0, 1, 0, 1][i], "wheel": i * 36.0, "trail": true, "underglow": true}).img)
	anims["transform_walk"] = c_walk
	var c_atk: Array = []
	for i in 4:
		c_atk.append(A.car(pal, {"lunge": [0, 6, 10, 3][i], "burst": i == 1 or i == 2,
			"trail": true, "wheel": i * 60.0, "underglow": true}).img)
	anims["transform_attack"] = c_atk

	# Transformación robot -> coche (con escudo de invulnerabilidad al final).
	var robot_img: Image = A.robot(pal, {}).img
	var car_img: Image = A.car(pal, {"underglow": true}).img
	var car_shield: Image = A.car(pal, {"underglow": true, "shield": 0.8}).img
	var pivot := Vector2(72, 93)
	var tf: Array = []
	var steps := [
		{"src": robot_img, "sx": 1.0, "sy": 1.0, "white": 0.65, "ring": 10.0},
		{"src": robot_img, "sx": 1.12, "sy": 0.84, "white": 0.4, "ring": 20.0},
		{"src": robot_img, "sx": 1.5, "sy": 0.58, "white": 0.5, "ring": 30.0},
		{"src": car_img, "sx": 0.85, "sy": 0.7, "white": 0.55, "ring": 38.0},
		{"src": car_shield, "sx": 1.06, "sy": 1.1, "white": 0.3, "ring": 46.0},
		{"src": car_shield, "sx": 1.0, "sy": 1.0, "white": 0.0, "ring": 0.0},
	]
	for st in steps:
		var im: Image = P.xform(st.src, st.sx, st.sy, pivot)
		var w = _wrap(im)
		if st.white > 0.0:
			w.tint(Color.WHITE, st.white)
		if st.ring > 0.0:
			w.ring_px(72, 58, st.ring, st.ring * 0.8, Color(0.6, 0.95, 1.0, 0.85), 0.14)
			w.ring_px(72, 58, st.ring * 0.7, st.ring * 0.56, Color(1, 1, 1, 0.55), 0.12)
		tf.append(w.img)
	anims["transform_activate"] = tf

	# Muerte.
	var death: Array = []
	var dpose := [
		{"lean": -2, "front": Vector2(66, 40), "back": Vector2(14, 40)},
		{"lean": -3, "kneel": 5, "front": Vector2(62, 56), "back": Vector2(16, 54)},
		{"lean": -3, "kneel": 6, "front": Vector2(62, 58), "back": Vector2(16, 56), "dead": true},
		{"lean": -3, "kneel": 6, "front": Vector2(62, 58), "back": Vector2(16, 56), "dead": true},
		{"lean": -3, "kneel": 6, "front": Vector2(62, 58), "back": Vector2(16, 56), "dead": true},
		{"lean": -3, "kneel": 6, "front": Vector2(62, 58), "back": Vector2(16, 56), "dead": true},
	]
	var rots := [0.0, -6.0, -24.0, -52.0, -80.0, -90.0]
	var whites := [0.55, 0.2, 0.0, 0.0, 0.0, 0.0]
	var grays := [0.0, 0.15, 0.35, 0.5, 0.62, 0.7]
	for i in 6:
		var rp = A.robot(pal, dpose[i])
		if whites[i] > 0.0:
			rp.tint(Color.WHITE, whites[i])
		rp.desaturate(grays[i])
		var im: Image = rp.img
		if rots[i] != 0.0:
			im = P.xform(im, 1.0, 1.0, Vector2(72, 70), rots[i])
			im = P.ground(im, 93, 72)
		var w = _wrap(im)
		_sparks(w, i, 140 + i)
		if i >= 3:
			var smoke_y := 60 - (i - 3) * 6
			w.ellipse_px(62, smoke_y, 5, 4, Color(0.3, 0.3, 0.33, 0.45 - (i - 3) * 0.1))
			w.ellipse_px(68, smoke_y - 6, 4, 3, Color(0.35, 0.35, 0.38, 0.35 - (i - 3) * 0.08))
		death.append(w.img)
	anims["death"] = death
	return anims


func _megatron(pal: Dictionary) -> Dictionary:
	var A := MegaArt
	var anims := {}

	var idle: Array = []
	for i in 4:
		idle.append(A.robot(pal, {"bob": [0, -1, -1, 0][i], "charge": [0.2, 0.4, 0.5, 0.4][i]}).img)
	anims["idle"] = idle

	var walk: Array = []
	var strides := [1, 1, 0, -1, -1, 0]
	var bobs := [0, -1, 0, 0, -1, 0]
	for i in 6:
		walk.append(A.robot(pal, {"stride": strides[i], "bob": bobs[i]}).img)
	anims["walk"] = walk

	var attack: Array = []
	var atk := [
		{"charge": 1.0, "lean": -1},
		{"charge": 1.0, "recoil": 5, "flash": 1.0, "lean": -2},
		{"charge": 0.6, "recoil": 3, "flash": 0.5, "lean": -1},
		{"charge": 0.3, "recoil": 1},
	]
	for pose in atk:
		attack.append(A.robot(pal, pose).img)
	anims["attack"] = attack

	var t_idle: Array = []
	for i in 4:
		t_idle.append(A.tank(pal, {"bob": [0, 1, 0, 0][i], "charge": [0.4, 0.7, 1.0, 0.7][i], "smoke": i}).img)
	anims["transform_idle"] = t_idle
	var t_walk: Array = []
	for i in 4:
		t_walk.append(A.tank(pal, {"bob": [0, 1, 0, 1][i], "tread": i, "charge": 0.7, "smoke": i * 2}).img)
	anims["transform_walk"] = t_walk
	var t_atk: Array = []
	var tpose := [
		{"charge": 1.0},
		{"charge": 1.0, "recoil": 6, "flash": 1.0},
		{"charge": 0.6, "recoil": 4, "flash": 0.6},
		{"charge": 0.3, "recoil": 1},
	]
	for pose in tpose:
		t_atk.append(A.tank(pal, pose).img)
	anims["transform_attack"] = t_atk

	var robot_img: Image = A.robot(pal, {}).img
	var tank_img: Image = A.tank(pal, {"smoke": 1}).img
	var pivot := Vector2(72, 93)
	var tf: Array = []
	var steps := [
		{"src": robot_img, "sx": 1.0, "sy": 1.0, "white": 0.65, "ring": 10.0},
		{"src": robot_img, "sx": 1.12, "sy": 0.86, "white": 0.4, "ring": 20.0},
		{"src": robot_img, "sx": 1.4, "sy": 0.62, "white": 0.5, "ring": 30.0},
		{"src": tank_img, "sx": 0.85, "sy": 0.68, "white": 0.55, "ring": 38.0},
		{"src": tank_img, "sx": 1.06, "sy": 1.1, "white": 0.3, "ring": 46.0},
		{"src": tank_img, "sx": 1.0, "sy": 1.0, "white": 0.0, "ring": 0.0},
	]
	for st in steps:
		var im: Image = P.xform(st.src, st.sx, st.sy, pivot)
		var w = _wrap(im)
		if st.white > 0.0:
			w.tint(Color.WHITE, st.white)
		if st.ring > 0.0:
			w.ring_px(72, 58, st.ring, st.ring * 0.8, Color(1.0, 0.6, 0.35, 0.85), 0.14)
			w.ring_px(72, 58, st.ring * 0.7, st.ring * 0.56, Color(1, 0.9, 0.7, 0.55), 0.12)
		tf.append(w.img)
	anims["transform_activate"] = tf

	var death: Array = []
	var dpose := [
		{"lean": -2},
		{"lean": -3, "kneel": 5},
		{"lean": -3, "kneel": 6, "dead": true, "charge": 0.0},
		{"lean": -3, "kneel": 6, "dead": true, "charge": 0.0},
		{"lean": -3, "kneel": 6, "dead": true, "charge": 0.0},
		{"lean": -3, "kneel": 6, "dead": true, "charge": 0.0},
	]
	var rots := [0.0, -6.0, -24.0, -52.0, -80.0, -90.0]
	var whites := [0.55, 0.2, 0.0, 0.0, 0.0, 0.0]
	var grays := [0.0, 0.15, 0.35, 0.5, 0.62, 0.7]
	for i in 6:
		var rp = A.robot(pal, dpose[i])
		if whites[i] > 0.0:
			rp.tint(Color.WHITE, whites[i])
		rp.desaturate(grays[i])
		var im: Image = rp.img
		if rots[i] != 0.0:
			im = P.xform(im, 1.0, 1.0, Vector2(72, 70), rots[i])
			im = P.ground(im, 93, 72)
		var w = _wrap(im)
		_sparks(w, i, 190 + i)
		if i >= 3:
			var smoke_y := 60 - (i - 3) * 6
			w.ellipse_px(62, smoke_y, 5, 4, Color(0.3, 0.3, 0.33, 0.45 - (i - 3) * 0.1))
			w.ellipse_px(68, smoke_y - 6, 4, 3, Color(0.35, 0.35, 0.38, 0.35 - (i - 3) * 0.08))
		death.append(w.img)
	anims["death"] = death
	return anims


func _shockwave(pal: Dictionary) -> Dictionary:
	var A := ShockArt
	var anims := {}

	var idle: Array = []
	for i in 4:
		idle.append(A.robot(pal, {"bob": [0, -1, -1, 0][i], "charge": [0.2, 0.4, 0.5, 0.4][i]}).img)
	anims["idle"] = idle

	var walk: Array = []
	var strides := [1, 1, 0, -1, -1, 0]
	var bobs := [0, -1, 0, 0, -1, 0]
	for i in 6:
		walk.append(A.robot(pal, {"stride": strides[i], "bob": bobs[i]}).img)
	anims["walk"] = walk

	var attack: Array = []
	var atk := [
		{"charge": 1.0, "lean": -1},
		{"charge": 1.0, "recoil": 5, "flash": 1.0, "lean": -2},
		{"charge": 0.6, "recoil": 3, "flash": 0.5, "lean": -1},
		{"charge": 0.3, "recoil": 1},
	]
	for pose in atk:
		attack.append(A.robot(pal, pose).img)
	anims["attack"] = attack

	# Cañón láser (inmóvil, rayo activo)
	var c_idle: Array = []
	for i in 4:
		c_idle.append(A.cannon(pal, {"bob": [0, 0, 1, 0][i], "charge": [0.8, 1.0, 0.9, 1.0][i],
			"beam": [0.8, 1.0, 0.9, 1.0][i], "spin": i}).img)
	anims["transform_idle"] = c_idle

	var robot_img: Image = A.robot(pal, {}).img
	var cannon_img: Image = A.cannon(pal, {"charge": 0.6}).img
	var pivot := Vector2(72, 93)
	var tf: Array = []
	var steps := [
		{"src": robot_img, "sx": 1.0, "sy": 1.0, "white": 0.65, "ring": 10.0},
		{"src": robot_img, "sx": 1.12, "sy": 0.86, "white": 0.4, "ring": 20.0},
		{"src": robot_img, "sx": 1.4, "sy": 0.62, "white": 0.5, "ring": 30.0},
		{"src": cannon_img, "sx": 0.85, "sy": 0.68, "white": 0.55, "ring": 38.0},
		{"src": cannon_img, "sx": 1.06, "sy": 1.1, "white": 0.3, "ring": 46.0},
		{"src": cannon_img, "sx": 1.0, "sy": 1.0, "white": 0.0, "ring": 0.0},
	]
	for st in steps:
		var im: Image = P.xform(st.src, st.sx, st.sy, pivot)
		var w = _wrap(im)
		if st.white > 0.0:
			w.tint(Color.WHITE, st.white)
		if st.ring > 0.0:
			w.ring_px(72, 58, st.ring, st.ring * 0.8, Color(0.75, 0.5, 1.0, 0.85), 0.14)
			w.ring_px(72, 58, st.ring * 0.7, st.ring * 0.56, Color(0.95, 0.85, 1, 0.55), 0.12)
		tf.append(w.img)
	anims["transform_activate"] = tf

	var death: Array = []
	var dpose := [
		{"lean": -2},
		{"lean": -3, "kneel": 5},
		{"lean": -3, "kneel": 6, "dead": true, "charge": 0.0},
		{"lean": -3, "kneel": 6, "dead": true, "charge": 0.0},
		{"lean": -3, "kneel": 6, "dead": true, "charge": 0.0},
		{"lean": -3, "kneel": 6, "dead": true, "charge": 0.0},
	]
	var rots := [0.0, -6.0, -24.0, -52.0, -80.0, -90.0]
	var whites := [0.55, 0.2, 0.0, 0.0, 0.0, 0.0]
	var grays := [0.0, 0.15, 0.35, 0.5, 0.62, 0.7]
	for i in 6:
		var rp = A.robot(pal, dpose[i])
		if whites[i] > 0.0:
			rp.tint(Color.WHITE, whites[i])
		rp.desaturate(grays[i])
		var im: Image = rp.img
		if rots[i] != 0.0:
			im = P.xform(im, 1.0, 1.0, Vector2(72, 70), rots[i])
			im = P.ground(im, 93, 72)
		var w = _wrap(im)
		_sparks(w, i, 310 + i)
		if i >= 3:
			var smoke_y := 60 - (i - 3) * 6
			w.ellipse_px(62, smoke_y, 5, 4, Color(0.3, 0.3, 0.33, 0.45 - (i - 3) * 0.1))
			w.ellipse_px(68, smoke_y - 6, 4, 3, Color(0.35, 0.35, 0.38, 0.35 - (i - 3) * 0.08))
		death.append(w.img)
	anims["death"] = death
	return anims


func _arcee(pal: Dictionary) -> Dictionary:
	var A := ArceeArt
	var anims := {}
	var strides := [1, 1, 0, -1, -1, 0]
	var bobs := [0, -1, 0, 0, -1, 0]

	# ── Modo cuerpo a cuerpo (cuchillas) ──
	var idle: Array = []
	for i in 4:
		idle.append(A.robot(pal, {"bob": [0, -1, -1, 0][i]}).img)
	anims["idle"] = idle
	var walk: Array = []
	for i in 6:
		var sw: int = strides[i] * 3
		walk.append(A.robot(pal, {"stride": strides[i], "bob": bobs[i],
			"front": Vector2(61 - sw, 52), "back": Vector2(19 + sw, 53)}).img)
	anims["walk"] = walk
	var attack: Array = []
	var atk := [
		{"front": Vector2(33, 28), "back": Vector2(47, 28), "extend": 0.4, "lean": -2},
		{"front": Vector2(68, 48), "back": Vector2(12, 48), "extend": 1.0, "lean": 2, "slash": 0.55},
		{"front": Vector2(70, 50), "back": Vector2(10, 50), "extend": 1.0, "lean": 3, "slash": 1.0},
		{"front": Vector2(62, 52), "back": Vector2(18, 52), "extend": 0.3, "lean": 1, "slash": 0.3},
	]
	for pose in atk:
		attack.append(A.robot(pal, pose).img)
	anims["attack"] = attack

	# ── Modo distancia (pistolas) ──
	var r_idle: Array = []
	for i in 4:
		r_idle.append(A.robot(pal, {"mode": "ranged", "bob": [0, -1, -1, 0][i]}).img)
	anims["ranged_idle"] = r_idle
	var r_walk: Array = []
	for i in 6:
		r_walk.append(A.robot(pal, {"mode": "ranged", "stride": strides[i], "bob": bobs[i]}).img)
	anims["ranged_walk"] = r_walk
	var r_atk: Array = []
	var ratk := [
		{"mode": "ranged", "lean": -1},
		{"mode": "ranged", "front": Vector2(63, 44), "back": Vector2(55, 48), "flash": 1.0, "lean": -2},
		{"mode": "ranged", "front": Vector2(64, 44), "back": Vector2(56, 48), "flash": 0.5, "lean": -1},
	]
	for pose in ratk:
		r_atk.append(A.robot(pal, pose).img)
	anims["ranged_attack"] = r_atk

	# ── Moto ──
	var b_idle: Array = []
	for i in 4:
		b_idle.append(A.bike(pal, {"bob": [0, 1, 0, 0][i]}).img)
	anims["transform_idle"] = b_idle
	var b_walk: Array = []
	for i in 4:
		b_walk.append(A.bike(pal, {"bob": [0, 1, 0, 1][i], "wheel": i * 30.0, "trail": true}).img)
	anims["transform_walk"] = b_walk
	var b_atk: Array = []
	var bp := [
		{"slash": 0.3},
		{"lunge": 8, "slash": 1.0, "trail": true, "wheel": 40.0},
		{"lunge": 14, "slash": 0.8, "trail": true, "wheel": 80.0},
		{"lunge": 4, "slash": 0.3, "wheel": 120.0},
	]
	for pose in bp:
		b_atk.append(A.bike(pal, pose).img)
	anims["transform_attack"] = b_atk

	var robot_img: Image = A.robot(pal, {}).img
	var bike_img: Image = A.bike(pal, {}).img
	var pivot := Vector2(72, 93)
	var tf: Array = []
	var steps := [
		{"src": robot_img, "sx": 1.0, "sy": 1.0, "white": 0.65, "ring": 10.0},
		{"src": robot_img, "sx": 1.12, "sy": 0.84, "white": 0.4, "ring": 20.0},
		{"src": robot_img, "sx": 1.5, "sy": 0.58, "white": 0.5, "ring": 30.0},
		{"src": bike_img, "sx": 0.85, "sy": 0.7, "white": 0.55, "ring": 38.0},
		{"src": bike_img, "sx": 1.06, "sy": 1.1, "white": 0.3, "ring": 46.0},
		{"src": bike_img, "sx": 1.0, "sy": 1.0, "white": 0.0, "ring": 0.0},
	]
	for st in steps:
		var im: Image = P.xform(st.src, st.sx, st.sy, pivot)
		var w = _wrap(im)
		if st.white > 0.0:
			w.tint(Color.WHITE, st.white)
		if st.ring > 0.0:
			w.ring_px(72, 58, st.ring, st.ring * 0.8, Color(1.0, 0.5, 0.8, 0.85), 0.14)
			w.ring_px(72, 58, st.ring * 0.7, st.ring * 0.56, Color(1, 0.9, 0.96, 0.55), 0.12)
		tf.append(w.img)
	anims["transform_activate"] = tf

	var death: Array = []
	var dpose := [
		{"lean": -2},
		{"lean": -3, "kneel": 5},
		{"lean": -3, "kneel": 6, "dead": true},
		{"lean": -3, "kneel": 6, "dead": true},
		{"lean": -3, "kneel": 6, "dead": true},
		{"lean": -3, "kneel": 6, "dead": true},
	]
	var rots := [0.0, -6.0, -24.0, -52.0, -80.0, -90.0]
	var whites := [0.55, 0.2, 0.0, 0.0, 0.0, 0.0]
	var grays := [0.0, 0.15, 0.35, 0.5, 0.62, 0.7]
	for i in 6:
		var rp = A.robot(pal, dpose[i])
		if whites[i] > 0.0:
			rp.tint(Color.WHITE, whites[i])
		rp.desaturate(grays[i])
		var im: Image = rp.img
		if rots[i] != 0.0:
			im = P.xform(im, 1.0, 1.0, Vector2(72, 70), rots[i])
			im = P.ground(im, 93, 72)
		var w = _wrap(im)
		_sparks(w, i, 270 + i)
		if i >= 3:
			var smoke_y := 60 - (i - 3) * 6
			w.ellipse_px(62, smoke_y, 5, 4, Color(0.3, 0.3, 0.33, 0.45 - (i - 3) * 0.1))
			w.ellipse_px(68, smoke_y - 6, 4, 3, Color(0.35, 0.35, 0.38, 0.35 - (i - 3) * 0.08))
		death.append(w.img)
	anims["death"] = death
	return anims


func _starscream(pal: Dictionary) -> Dictionary:
	var A := StarArt
	var anims := {}

	var idle: Array = []
	for i in 4:
		idle.append(A.robot(pal, {"bob": [0, -1, -1, 0][i], "wing": [0, 1, 1, 0][i]}).img)
	anims["idle"] = idle

	var walk: Array = []
	var strides := [1, 1, 0, -1, -1, 0]
	var bobs := [0, -1, 0, 0, -1, 0]
	for i in 6:
		walk.append(A.robot(pal, {"stride": strides[i], "bob": bobs[i], "wing": i % 2}).img)
	anims["walk"] = walk

	var attack: Array = []
	var atk := [
		{"lean": -1},
		{"recoil": 5, "flash": 1.0, "lean": -2},
		{"recoil": 3, "flash": 0.5, "lean": -1},
		{"recoil": 1},
	]
	for pose in atk:
		attack.append(A.robot(pal, pose).img)
	anims["attack"] = attack

	var j_idle: Array = []
	for i in 4:
		j_idle.append(A.jet(pal, {"bob": [0, 1, 0, -1][i], "flame": [0.4, 0.7, 1.0, 0.7][i]}).img)
	anims["transform_idle"] = j_idle
	var j_walk: Array = []
	for i in 4:
		j_walk.append(A.jet(pal, {"bob": [0, 1, 0, 1][i], "flame": [1.0, 0.8, 1.0, 0.9][i], "lines": true}).img)
	anims["transform_walk"] = j_walk
	var j_atk: Array = []
	var jp := [
		{"flame": 0.8},
		{"flame": 1.0, "recoil": 5, "flash": 1.0},
		{"flame": 0.9, "recoil": 3, "flash": 0.5},
		{"flame": 0.6, "recoil": 1},
	]
	for pose in jp:
		j_atk.append(A.jet(pal, pose).img)
	anims["transform_attack"] = j_atk

	var robot_img: Image = A.robot(pal, {}).img
	var jet_img: Image = A.jet(pal, {"flame": 0.8}).img
	var pivot := Vector2(72, 93)
	var tf: Array = []
	var steps := [
		{"src": robot_img, "sx": 1.0, "sy": 1.0, "white": 0.65, "ring": 10.0},
		{"src": robot_img, "sx": 1.1, "sy": 0.88, "white": 0.4, "ring": 20.0},
		{"src": robot_img, "sx": 1.35, "sy": 0.62, "white": 0.5, "ring": 32.0},
		{"src": jet_img, "sx": 0.85, "sy": 0.7, "white": 0.55, "ring": 42.0},
		{"src": jet_img, "sx": 1.06, "sy": 1.08, "white": 0.3, "ring": 52.0},
		{"src": jet_img, "sx": 1.0, "sy": 1.0, "white": 0.0, "ring": 0.0},
	]
	for st in steps:
		var im: Image = P.xform(st.src, st.sx, st.sy, pivot)
		var w = _wrap(im)
		if st.white > 0.0:
			w.tint(Color.WHITE, st.white)
		if st.ring > 0.0:
			w.ring_px(72, 58, st.ring, st.ring * 0.8, Color(1.0, 0.6, 0.3, 0.85), 0.14)
			w.ring_px(72, 58, st.ring * 0.7, st.ring * 0.56, Color(1, 0.92, 0.7, 0.55), 0.12)
		tf.append(w.img)
	anims["transform_activate"] = tf

	var death: Array = []
	var dpose := [
		{"lean": -2},
		{"lean": -3, "kneel": 5},
		{"lean": -3, "kneel": 6, "dead": true},
		{"lean": -3, "kneel": 6, "dead": true},
		{"lean": -3, "kneel": 6, "dead": true},
		{"lean": -3, "kneel": 6, "dead": true},
	]
	var rots := [0.0, -6.0, -24.0, -52.0, -80.0, -90.0]
	var whites := [0.55, 0.2, 0.0, 0.0, 0.0, 0.0]
	var grays := [0.0, 0.15, 0.35, 0.5, 0.62, 0.7]
	for i in 6:
		var rp = A.robot(pal, dpose[i])
		if whites[i] > 0.0:
			rp.tint(Color.WHITE, whites[i])
		rp.desaturate(grays[i])
		var im: Image = rp.img
		if rots[i] != 0.0:
			im = P.xform(im, 1.0, 1.0, Vector2(72, 70), rots[i])
			im = P.ground(im, 93, 72)
		var w = _wrap(im)
		_sparks(w, i, 230 + i)
		if i >= 3:
			var smoke_y := 60 - (i - 3) * 6
			w.ellipse_px(62, smoke_y, 5, 4, Color(0.3, 0.3, 0.33, 0.45 - (i - 3) * 0.1))
			w.ellipse_px(68, smoke_y - 6, 4, 3, Color(0.35, 0.35, 0.38, 0.35 - (i - 3) * 0.08))
		death.append(w.img)
	anims["death"] = death
	return anims


## Chispas de daño alrededor del cuerpo.
func _sparks(w, frame: int, seed_val: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var count: int = [10, 12, 9, 7, 4, 2][frame]
	for i in count:
		var x := rng.randi_range(38, 106)
		var y := rng.randi_range(30, 92)
		var c: Color = [Color("fff6a8"), Color("ffb347"), Color("ffffff")][rng.randi() % 3]
		w.px(x, y, c)
		if rng.randf() < 0.5:
			w.px(x + 1, y, c)

## Amplía x6 un fotograma: -- zoom personaje/skin animación índice
func _zoom(args: PackedStringArray) -> void:
	var catalog := _catalog()
	var img: Image = catalog[args[1]][args[2]][int(args[3])].duplicate()
	img.resize(img.get_width() * 6, img.get_height() * 6, Image.INTERPOLATE_NEAREST)
	var bg := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	bg.fill(Color("3a3f4d"))
	bg.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i.ZERO)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))
	bg.save_png(ProjectSettings.globalize_path(PREVIEW_DIR + "zoom.png"))


# ── Escritura de PNG + hojas de previsualización ──────────────────────────────

func _make_pngs() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))
	var catalog := _catalog()
	for key in catalog:
		var dir: String = OUT_ROOT + key.get_slice("/", 0) + "/" + key.get_slice("/", 1) + "/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		var anims: Dictionary = catalog[key]
		for anim in anims:
			for i in anims[anim].size():
				anims[anim][i].save_png(ProjectSettings.globalize_path(dir + "%s_%d.png" % [anim, i]))
		_save_sheet(key.replace("/", "_"), anims)
	_make_ui_pngs()
	print("PNG generados: ", catalog.keys())


## Hoja con una fila por animación (x2) para revisar el arte a simple vista.
func _save_sheet(name: String, anims: Dictionary) -> void:
	var cols := 0
	for a in anims:
		cols = maxi(cols, anims[a].size())
	var fw: int = anims[anims.keys()[0]][0].get_width()
	var fh: int = anims[anims.keys()[0]][0].get_height()
	var sheet := Image.create(cols * fw, anims.size() * fh, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("3a3f4d"))
	var row := 0
	for a in anims:
		for i in anims[a].size():
			sheet.blend_rect(anims[a][i], Rect2i(0, 0, fw, fh), Vector2i(i * fw, row * fh))
		row += 1
	sheet.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	sheet.save_png(ProjectSettings.globalize_path(PREVIEW_DIR + name + ".png"))


func _make_ui_pngs() -> void:
	var dir := ProjectSettings.globalize_path("res://assets/ui/")
	DirAccess.make_dir_recursive_absolute(dir)
	var under := Image.create(200, 16, false, Image.FORMAT_RGBA8)
	under.fill(Color(0.1, 0.1, 0.1, 0.8))
	under.save_png(dir + "bar_under.png")
	var fill := Image.create(200, 16, false, Image.FORMAT_RGBA8)
	fill.fill(Color.WHITE)
	fill.save_png(dir + "bar_fill.png")

# ── SpriteFrames ──────────────────────────────────────────────────────────────

func _make_frames() -> void:
	var catalog := _catalog()
	for key in catalog:
		var character: String = key.get_slice("/", 0)
		var skin: String = key.get_slice("/", 1)
		var dir: String = OUT_ROOT + character + "/" + skin + "/"
		var sf := SpriteFrames.new()
		sf.remove_animation("default")
		var anims: Dictionary = catalog[key]
		for anim in anims:
			sf.add_animation(anim)
			sf.set_animation_speed(anim, ANIM_META[anim][0])
			sf.set_animation_loop(anim, ANIM_META[anim][1])
			for i in anims[anim].size():
				var tex: Texture2D = load(dir + "%s_%d.png" % [anim, i])
				sf.add_frame(anim, tex)
		var err := ResourceSaver.save(sf, FRAMES_DIR + "%s_%s.tres" % [character, skin])
		print("Guardado ", character, "_", skin, " -> ", error_string(err))
