# generate_art.gd
# Herramienta de desarrollo (no forma parte del juego).
# Genera TODO el arte (personajes, enemigos, efectos e iconos) con el dibujo vectorial
# estilo cel (tools/art2/*) y construye los SpriteFrames de cada skin.
#
# Uso (desde la raíz del proyecto):
#   godot --headless -s tools/generate_art.gd -- png      # dibuja PNG + hojas de previsualización
#   godot --headless --import                              # importa los PNG en Godot
#   godot --headless -s tools/generate_art.gd -- frames   # crea resources/frames/*.tres
#
# Cuando haya arte definitivo basta con sustituir los SpriteFrames de cada skin.

extends SceneTree

const MegaCel := preload("res://tools/art2/megatron_cel.gd")
const StarCel := preload("res://tools/art2/starscream_cel.gd")
const OptimusCel := preload("res://tools/art2/optimus_cel.gd")
const BeeCel := preload("res://tools/art2/bumblebee_cel.gd")
const VehiconCel := preload("res://tools/art2/vehicon_cel.gd")
const SeekerCel := preload("res://tools/art2/seeker_cel.gd")
const ConstructiconCel := preload("res://tools/art2/constructicon_cel.gd")
const BossCel := preload("res://tools/art2/boss_cel.gd")
const ShockCel := preload("res://tools/art2/shockwave_cel.gd")
const ArceeCel := preload("res://tools/art2/arcee_cel.gd")
const ArceePistols := preload("res://tools/art2/arcee_pistols_cel.gd")
const CelAnim := preload("res://tools/art2/cel_anim.gd")

## Escala de render del arte nuevo: 1 unidad de diseño = 0,72 px (a 0,5 de escala en el juego).
const CEL_RENDER_SCALE := 0.72

## Personajes ya migrados al arte nuevo: animan a 24 fps y no generan hoja de revisión.
const CEL_CHARACTERS := ["megatron", "starscream", "optimus", "bumblebee", "arcee", "shockwave",
	"vehicon", "seeker", "constructicon", "boss_brawl", "boss_devastator", "boss_soundwave", "boss_galvatron"]

## Los enemigos se ven más pequeños que los jugables y hay muchos a la vez: se generan
## a menos resolución para gastar menos memoria (la escena compensa con su escala).
const CEL_ENEMY_SCALE := 0.5
const CEL_BIG_ENEMY_SCALE := 0.6

## Jefes: ataque de cada uno (el tamaño en el juego lo da la escala de su escena).
const BOSS_ATTACKS := {"brawl": "punch", "devastator": "smash", "soundwave": "fire", "galvatron": "fire"}
const FxCel := preload("res://tools/art2/fx_cel.gd")
const TerrainCel := preload("res://tools/art2/terrain_cel.gd")

const OUT_ROOT := "res://assets/sprites/"

## Archivo (junto a los PNG) con el recorte de cada fotograma.
const CROP_FILE := "crop.cropdata"
const FRAMES_DIR := "res://resources/frames/"
const PREVIEW_DIR := "res://tools/preview/"

# Animación -> [fps, loop]
const ANIM_META := {
	"idle": [5.0, true],
	"walk": [10.0, true],
	"attack": [16.0, false],
	"walk_attack": [24.0, false],
	"attack_cross": [24.0, false],
	"walk_attack_cross": [24.0, false],
	"attack_finisher": [12.0, false],
	"walk_attack_finisher": [24.0, false],
	"ranged_idle": [5.0, true],
	"ranged_walk": [10.0, true],
	"ranged_attack": [16.0, false],
	"ranged_walk_attack": [24.0, false],
	"transform_activate": [10.0, false],
	"transform_idle": [8.0, true],
	"transform_walk": [14.0, true],
	"transform_attack": [14.0, false],
	"death": [8.0, false],
	"fly": [14.0, true],
	"explode": [16.0, false],
	"phase2_intro": [8.0, false],
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
	for skin in OptimusCel.SKINS:
		out["optimus/" + skin] = CelAnim.all_melee(OptimusCel, skin, CEL_RENDER_SCALE)
	for skin in BeeCel.SKINS:
		out["bumblebee/" + skin] = CelAnim.all_puncher(BeeCel, skin, CEL_RENDER_SCALE)
	for skin in MegaCel.SKINS:
		out["megatron/" + skin] = CelAnim.all(MegaCel, skin, CEL_RENDER_SCALE)
	for skin in ArceeCel.SKINS:
		out["arcee/" + skin] = CelAnim.all_hybrid(ArceeCel, ArceePistols, skin, CEL_RENDER_SCALE)
	for skin in ShockCel.SKINS:
		out["shockwave/" + skin] = CelAnim.all_turret(ShockCel, skin, CEL_RENDER_SCALE)
	out["fx/shock_wave"] = {"fly": [FxCel.shock_wave(0), FxCel.shock_wave(1), FxCel.shock_wave(2), FxCel.shock_wave(3)]}
	out["fx/photon"] = {"fly": [FxCel.photon(0), FxCel.photon(1), FxCel.photon(2), FxCel.photon(3)]}
	for skin in StarCel.SKINS:
		out["starscream/" + skin] = CelAnim.all(StarCel, skin, CEL_RENDER_SCALE)
	out["fx/null_ray"] = {"fly": [FxCel.null_ray(0), FxCel.null_ray(1), FxCel.null_ray(2), FxCel.null_ray(3)]}
	var rh: Array = []
	for i in 6:
		rh.append(FxCel.ray_hit(i))
	out["fx/ray_hit"] = {"explode": rh}
	out["fx/fusion_bolt"] = {"fly": [FxCel.fusion_bolt(0), FxCel.fusion_bolt(1), FxCel.fusion_bolt(2), FxCel.fusion_bolt(3)]}
	out["fx/charged_shell"] = {"fly": [FxCel.charged_shell(0), FxCel.charged_shell(1), FxCel.charged_shell(2), FxCel.charged_shell(3)]}
	var ex: Array = []
	for i in 8:
		ex.append(FxCel.explosion(i))
	out["fx/explosion"] = {"explode": ex}
	out["seeker/base"] = CelAnim.enemy_flyer(SeekerCel, "base", CEL_ENEMY_SCALE)
	out["constructicon/base"] = CelAnim.enemy_melee(ConstructiconCel, "base", CEL_BIG_ENEMY_SCALE, true)
	for boss_name in BOSS_ATTACKS:
		out["boss_" + boss_name + "/base"] = CelAnim.boss_set(BossCel, boss_name, CEL_ENEMY_SCALE, BOSS_ATTACKS[boss_name])
	var cube: Array = []
	for i in 6:
		cube.append(FxCel.energon_cube(i))
	out["fx/energon_cube"] = {"idle": cube}
	var spark: Array = []
	for i in 5:
		spark.append(FxCel.energon_spark(i))
	out["fx/energon_spark"] = {"explode": spark}
	out["fx/enemy_bolt"] = {"fly": [FxCel.enemy_bolt(0), FxCel.enemy_bolt(1), FxCel.enemy_bolt(2), FxCel.enemy_bolt(3)]}
	out["fx/boss_orb"] = {"fly": [FxCel.boss_orb(0), FxCel.boss_orb(1), FxCel.boss_orb(2), FxCel.boss_orb(3)]}
	out["vehicon/base"] = CelAnim.enemy_melee(VehiconCel, "base", CEL_ENEMY_SCALE)
	return out


# ── Escritura de PNG + hojas de previsualización ──────────────────────────────

func _make_pngs() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))
	var catalog := _catalog()
	for key in catalog:
		var dir: String = OUT_ROOT + key.get_slice("/", 0) + "/" + key.get_slice("/", 1) + "/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		var anims: Dictionary = catalog[key]
		# Los efectos (fx/) se guardan enteros; el resto se recorta (ver _crop_rect).
		var crop_it: bool = key.get_slice("/", 0) != "fx"
		var crop := {}
		for anim in anims:
			for i in anims[anim].size():
				var img: Image = anims[anim][i]
				if crop_it:
					var r: Rect2i = _crop_rect(img)
					crop["%s_%d" % [anim, i]] = [r.position.x, r.position.y, r.size.x, r.size.y, img.get_width(), img.get_height()]
					img = img.get_region(r)
				img.save_png(ProjectSettings.globalize_path(dir + "%s_%d.png" % [anim, i]))
		if crop_it:
			var file := FileAccess.open(ProjectSettings.globalize_path(dir + CROP_FILE), FileAccess.WRITE)
			file.store_string(JSON.stringify(crop))
		if not key.get_slice("/", 0) in CEL_CHARACTERS:
			_save_sheet(key.replace("/", "_"), anims)
	_make_ui_pngs()
	_make_skill_icons()
	_make_terrain_pngs()
	print("PNG generados: ", catalog.keys())


## Rectángulo que contiene lo dibujado (con 1 px de margen para que el filtro lineal no corte
## el borde). Un fotograma vacío se queda en 1×1.
func _crop_rect(img: Image) -> Rect2i:
	var r: Rect2i = img.get_used_rect()
	if r.size == Vector2i.ZERO:
		return Rect2i(0, 0, 1, 1)
	return r.grow(1).intersection(Rect2i(Vector2i.ZERO, img.get_size()))


## Lee los recortes guardados al generar los PNG: { "anim_i": [x, y, w, h, ancho, alto] }.
func _read_crop(dir: String) -> Dictionary:
	var path: String = dir + CROP_FILE
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


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


## Texturas del terreno (se repiten en el juego) en assets/terrain/.
func _make_terrain_pngs() -> void:
	var dir := ProjectSettings.globalize_path("res://assets/terrain/")
	DirAccess.make_dir_recursive_absolute(dir)
	TerrainCel.floor_tile().save_png(dir + "floor.png")
	TerrainCel.decals().save_png(dir + "decals.png")


func _make_ui_pngs() -> void:
	var dir := ProjectSettings.globalize_path("res://assets/ui/")
	DirAccess.make_dir_recursive_absolute(dir)
	var under := Image.create(200, 16, false, Image.FORMAT_RGBA8)
	under.fill(Color(0.1, 0.1, 0.1, 0.8))
	under.save_png(dir + "bar_under.png")
	FxCel.energon_cube(0).save_png(dir + "energon_icon.png")
	var fill := Image.create(200, 16, false, Image.FORMAT_RGBA8)
	fill.fill(Color.WHITE)
	fill.save_png(dir + "bar_fill.png")

## Iconos del árbol de habilidades en assets/ui/skills/ (tonos neutros: la interfaz los tiñe).
func _make_skill_icons() -> void:
	var dir := ProjectSettings.globalize_path("res://assets/ui/skills/")
	DirAccess.make_dir_recursive_absolute(dir)
	var cell: int = int(32 * FxCel.FX_K) + 4
	var sheet := Image.create(FxCel.ICONS.size() * cell, cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("3a3f4d"))
	for i in FxCel.ICONS.size():
		var img: Image = FxCel.icon(FxCel.ICONS[i])
		img.save_png(dir + FxCel.ICONS[i] + ".png")
		sheet.blend_rect(img, Rect2i(0, 0, img.get_width(), img.get_height()), Vector2i(i * cell + 2, 2))
	sheet.save_png(ProjectSettings.globalize_path(PREVIEW_DIR + "skill_icons.png"))


# ── SpriteFrames ──────────────────────────────────────────────────────────────

func _make_frames() -> void:
	var catalog := _catalog()
	for key in catalog:
		var character: String = key.get_slice("/", 0)
		var skin: String = key.get_slice("/", 1)
		var dir: String = OUT_ROOT + character + "/" + skin + "/"
		var crop: Dictionary = _read_crop(dir)
		var sf := SpriteFrames.new()
		sf.remove_animation("default")
		var anims: Dictionary = catalog[key]
		for anim in anims:
			sf.add_animation(anim)
			sf.set_animation_speed(anim, CelAnim.FPS if character in CEL_CHARACTERS else ANIM_META[anim][0])
			sf.set_animation_loop(anim, ANIM_META[anim][1])
			for i in anims[anim].size():
				var tex: Texture2D = load(dir + "%s_%d.png" % [anim, i])
				var info = crop.get("%s_%d" % [anim, i])
				if info != null:
					# El PNG está recortado: AtlasTexture le devuelve su tamaño y posición
					# originales con un margen virtual (no ocupa memoria), así que el juego
					# lo ve igual que antes.
					var atlas := AtlasTexture.new()
					atlas.atlas = tex
					atlas.region = Rect2(0, 0, info[2], info[3])
					atlas.margin = Rect2(info[0], info[1], info[4] - info[2], info[5] - info[3])
					tex = atlas
				sf.add_frame(anim, tex)
		var err := ResourceSaver.save(sf, FRAMES_DIR + "%s_%s.tres" % [character, skin])
		print("Guardado ", character, "_", skin, " -> ", error_string(err))


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
