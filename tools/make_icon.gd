extends SceneTree
## Builds the Android launcher icons from the in-game pixel art.
##   godot --headless --path . --script tools/make_icon.gd

func _init() -> void:
	var art = load("res://scripts/Art.gd").new()
	art._ready()

	_compose(art, 192, true).save_png("res://icon_192.png")
	_compose(art, 432, false).save_png("res://icon_adaptive_fg.png")

	var bg := Image.create_empty(432, 432, false, Image.FORMAT_RGBA8)
	bg.fill(Color("1668a8"))
	bg.save_png("res://icon_adaptive_bg.png")

	print("icons written")
	quit()


## Plane on water (or on transparent, for the adaptive foreground layer).
func _compose(art, size: int, with_water: bool) -> Image:
	var out := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	if with_water:
		var tile: Image = art.tex("ocean").get_image()
		for y in size:
			for x in size:
				out.set_pixel(x, y, tile.get_pixel(x % tile.get_width(), y % tile.get_height()))

	var plane: Image = art.tex("player").get_image()
	# adaptive icons get cropped to a circle, so keep the plane well inside
	var scale := int(floor(size * (0.62 if with_water else 0.42) / plane.get_height()))
	var pw := plane.get_width() * scale
	var ph := plane.get_height() * scale
	var ox := (size - pw) / 2
	var oy := (size - ph) / 2
	for y in ph:
		for x in pw:
			var c := plane.get_pixel(x / scale, y / scale)
			if c.a > 0.0:
				out.set_pixel(ox + x, oy + y, c)
	return out
