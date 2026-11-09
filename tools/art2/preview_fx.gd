# preview_fx.gd — hoja de revisión de efectos, energon e iconos.
# Uso: godot --headless -s tools/art2/preview_fx.gd
extends SceneTree

const F := preload("res://tools/art2/fx_cel.gd")


func _init() -> void:
	var rows := [
		[F.fusion_bolt, 4], [F.charged_shell, 4], [F.null_ray, 4], [F.shock_wave, 4], [F.photon, 4],
		[F.enemy_bolt, 4], [F.boss_orb, 4], [F.ray_hit, 6], [F.explosion, 8], [F.energon_cube, 6], [F.energon_spark, 5],
	]
	var cell := 140
	var sheet := Image.create(cell * 8, cell * rows.size() + 150, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.3, 0.33, 0.38))
	for r in rows.size():
		for i in rows[r][1]:
			var im: Image = rows[r][0].call(i)
			if im.get_width() > cell:
				im.resize(cell, cell, Image.INTERPOLATE_LANCZOS)
			im.convert(Image.FORMAT_RGBA8)
			sheet.blend_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i(i * cell + 4, r * cell + (cell - im.get_height()) / 2))
	# Iconos sobre el fondo oscuro del árbol, a tamaño de pantalla.
	var strip := Image.create(cell * 8, 150, false, Image.FORMAT_RGBA8)
	strip.fill(Color("1a1d2b"))
	for i in F.ICONS.size():
		var ic: Image = F.icon(F.ICONS[i])
		ic.resize(48, 48, Image.INTERPOLATE_LANCZOS)
		ic.convert(Image.FORMAT_RGBA8)
		var tint := Color("ff6a5a") if i % 3 == 0 else (Color("ffcf4a") if i % 3 == 1 else Color("5ab4ff"))
		for y in 48:
			for x in 48:
				var px: Color = ic.get_pixel(x, y)
				ic.set_pixel(x, y, Color(px.r * tint.r, px.g * tint.g, px.b * tint.b, px.a))
		strip.blend_rect(ic, Rect2i(0, 0, 48, 48), Vector2i((i % 9) * 60 + 8, (i / 9) * 62 + 6))
	sheet.blend_rect(strip, Rect2i(0, 0, strip.get_width(), 150), Vector2i(0, cell * rows.size()))
	sheet.save_png(ProjectSettings.globalize_path("res://tools/preview/fx_cel.png"))
	quit()
