# preview3.gd — hojas de revisión del arte cel. Uso: godot --headless -s tools/art2/preview3.gd -- <megatron|starscream>
extends SceneTree

const C := preload("res://tools/art2/cel_character.gd")
const A := preload("res://tools/art2/cel_anim.gd")
const DESIGNS := {
	"megatron": preload("res://tools/art2/megatron_cel.gd"),
	"starscream": preload("res://tools/art2/starscream_cel.gd"),
	"optimus": preload("res://tools/art2/optimus_cel.gd"),
	"bumblebee": preload("res://tools/art2/bumblebee_cel.gd"),
	"arcee": preload("res://tools/art2/arcee_cel.gd"),
	"shockwave": preload("res://tools/art2/shockwave_cel.gd"),
	"vehicon": preload("res://tools/art2/vehicon_cel.gd"),
	"seeker": preload("res://tools/art2/seeker_cel.gd"),
	"constructicon": preload("res://tools/art2/constructicon_cel.gd"),
	"boss": preload("res://tools/art2/boss_cel.gd"),
}


func _paste(sheet: Image, im: Image, pos: Vector2i) -> void:
	im.convert(Image.FORMAT_RGBA8)
	sheet.blend_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), pos)


## Jefes: una fila por jefe con reposo, ataque, rugido y muerte.
func _boss_sheet(D) -> void:
	var k := 0.5
	var w := int(400 * k)
	var h := int(256 * k)
	var attacks := {"brawl": "punch", "devastator": "smash", "soundwave": "fire", "galvatron": "fire"}
	var sheet := Image.create(w * 8, h * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.3, 0.33, 0.38))
	var row := 0
	for boss in attacks:
		var a: Dictionary = A.boss_set(D, boss, k, attacks[boss])
		var picks := [a.idle[0], a.walk[4], a.attack[3], a.attack[6], a.phase2_intro[4], a.phase2_intro[10], a.death[8], a.death[13]]
		for i in 8:
			_paste(sheet, picks[i], Vector2i(i * w, row * h))
		row += 1
	sheet.save_png(ProjectSettings.globalize_path("res://tools/preview/") + "boss_anim.png")


## Enemigos: una sola apariencia; una fila por animación.
func _enemy_sheet(who: String, D) -> void:
	var k := 0.5
	var w := int(400 * k)
	var h := int(256 * k)
	var anims: Dictionary
	match who:
		"seeker":
			anims = A.enemy_flyer(D, "base", k)
		"constructicon":
			anims = A.enemy_melee(D, "base", k, true)
		_:
			anims = A.enemy_melee(D, "base", k)
	var rows := ["idle", "walk", "attack", "death"]
	var sheet := Image.create(w * 8, h * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.3, 0.33, 0.38))
	for row in rows.size():
		var frames: Array = anims[rows[row]]
		for i in 8:
			_paste(sheet, frames[i * frames.size() / 8], Vector2i(i * w, row * h))
	sheet.save_png(ProjectSettings.globalize_path("res://tools/preview/") + who + "_anim.png")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var who: String = args[0] if args.size() > 0 else "starscream"
	var D = DESIGNS[who]
	var skins := ["g1", "prime", "bay"]
	if who == "boss":
		_boss_sheet(D)
		quit()
		return
	if not D.SKINS.has("g1"):
		_enemy_sheet(who, D)
		quit()
		return
	var dir := ProjectSettings.globalize_path("res://tools/preview/")
	# Hoja de skins: robot y vehículo en grande
	var k := 0.85
	var w := int(400 * k)
	var extra: int = D.get_script_constant_map().get("EXTRA_Y", 0)
	var h := int((256 + extra * 2) * k)
	var sheet := Image.create(w * 3, h * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("eceff3"))
	for i in 3:
		_paste(sheet, C.robot(D, skins[i], {"charge": 0.3, "gun_sh": -16.0, "gun_el": -12.0}, k), Vector2i(i * w, 0))
		_paste(sheet, D.vehicle(D, skins[i], {"boost": 0.6}, k), Vector2i(i * w, h))
	sheet.save_png(dir + who + "_skins.png")
	# Tiras de animación a tamaño de juego
	var k2 := 0.5
	var w2 := int(400 * k2)
	var h2 := int((256 + extra * 2) * k2)
	var strip := Image.create(w2 * 7, h2 * 4, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0.3, 0.33, 0.38))
	var attacks := {"optimus": A.swing(D, "prime", k2) if who == "optimus" else [],
		"bumblebee": A.uppercut(D, "prime", k2) if who == "bumblebee" else []}
	var sets := [A.walk(D, "g1", k2), attacks[who] if attacks.has(who) else A.fire(D, "prime", k2), A.transform(D, "bay", k2), A.punch(D, "g1", k2, "izquierda") if who == "bumblebee" else A.death(D, "g1", k2)]
	if who == "arcee":
		var P = preload("res://tools/art2/arcee_pistols_cel.gd")
		sets = [A.walk(D, "g1", k2), A.cross_slash(D, "prime", k2), A.transform(D, "bay", k2), A.dual_fire(P, "g1", k2)]
	for row in sets.size():
		for i in 7:
			_paste(strip, sets[row][i * sets[row].size() / 7], Vector2i(i * w2, row * h2))
	strip.save_png(dir + who + "_anim.png")
	quit()
