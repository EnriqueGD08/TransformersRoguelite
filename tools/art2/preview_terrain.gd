# preview_terrain.gd — hoja de revisión del terreno: ambas capas repetidas 2×2 y juntas.
# Uso: godot --headless --path . -s tools/art2/preview_terrain.gd
extends SceneTree

const T := preload("res://tools/art2/terrain_cel.gd")


func _init() -> void:
	var floor_img: Image = T.floor_tile()
	var decal_img: Image = T.decals()
	floor_img.convert(Image.FORMAT_RGBA8)
	decal_img.convert(Image.FORMAT_RGBA8)
	# Zona de 1536×1024 px (3×2 bloques de suelo) con las manchas encima, repetidas.
	var w := floor_img.get_width()
	var out := Image.create(w * 2, w * 2, false, Image.FORMAT_RGBA8)
	for y in 2:
		for x in 2:
			out.blit_rect(floor_img, Rect2i(0, 0, w, w), Vector2i(x * w, y * w))
	# Las manchas se escalan a la resolución del suelo (en el juego lo hace la escala del sprite).
	var ratio: float = T.K / T.DECAL_K
	decal_img.resize(int(decal_img.get_width() * ratio), int(decal_img.get_height() * ratio), Image.INTERPOLATE_LANCZOS)
	var dw := decal_img.get_width()
	for y in 2:
		for x in 2:
			out.blend_rect(decal_img, Rect2i(0, 0, dw, dw), Vector2i(x * dw, y * dw))
	out.resize(out.get_width() / 2, out.get_height() / 2, Image.INTERPOLATE_LANCZOS)
	out.save_png(ProjectSettings.globalize_path("res://tools/preview/terrain_cel.png"))
	quit()
