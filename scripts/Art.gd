extends Node
## Procedural pixel-art factory.
## Every sprite in the game is generated at startup from ASCII art or from
## code-drawn shapes, so the project ships with zero binary assets.

const PAL := {
	" ": Color(0, 0, 0, 0),
	".": Color(0, 0, 0, 0),
	"X": Color("171a21"), # outline
	"k": Color("0d0f14"),
	"w": Color("ffffff"),
	"n": Color("c8cfd6"),
	"s": Color("9aa6b2"),
	"S": Color("5c6773"),
	"c": Color("8fe3ff"), # canopy glass
	"b": Color("3b7dd8"),
	"B": Color("1f4a8a"),
	"g": Color("5f8f3f"), # enemy green
	"G": Color("3a5c28"),
	"l": Color("86b85e"),
	"y": Color("ffd23f"),
	"h": Color("fff0a8"),
	"o": Color("ff9d2e"),
	"r": Color("e03b3b"),
	"R": Color("8f1d1d"),
	"t": Color("d9a441"), # player tan
	"T": Color("a06a20"),
	"p": Color("ff3fa4"), # enemy bullet magenta
	"m": Color("6b4a1f"),
}

const SPRITES := {
	"player": [
		"       X       ",
		"      XrX      ",
		"  X   XrX   X  ",
		" XsX  XcX  XsX ",
		" XsX  XcX  XsX ",
		" XsX XXtXX XsX ",
		"XXtXXXtytXXXtXX",
		"XtttyXtytXytttX",
		"XTTTTXTtTXTTTTX",
		"XXtXXXTtTXXXtXX",
		" XtX  XtX  XtX ",
		" XtX  XXX  XtX ",
		" XtX   X   XtX ",
		"XXXXX XXX XXXXX",
		"XrrrX  X  XrrrX",
		" XXX   X   XXX ",
	],
	"fighter": [
		"  XX  XXX  XX  ",
		"  XyX XkX XyX  ",
		" XXyXXXkXXXyXX ",
		" XyyyyyXyyyyyX ",
		"XXyyyyyXyyyyyXX",
		"XyhhhhXcXhhhhyX",
		"XXTTTTXcXTTTTXX",
		" XXXXXXcXXXXXX ",
		"     XyXyX     ",
		"     XyyyX     ",
		"      XyX      ",
		"      XoX      ",
		"       X       ",
	],
	"bomber": [
		"     XXX     XXX     ",
		"     XSX     XSX     ",
		"  XXXXSXXXXXXXSXXXX  ",
		"  XggggggXgXggggggX  ",
		"  XllllllXgXllllllX  ",
		"  XGGGGGGXgXGGGGGGX  ",
		"  XXXXXXXXgXXXXXXXX  ",
		"       XXgggXX       ",
		"       XgcccgX       ",
		"       XgcccgX       ",
		"       XXgggXX       ",
		"        XgggX        ",
		"        XgggX        ",
		"     XXXXgggXXXX     ",
		"     XGGGGgGGGGX     ",
		"     XXXXXXXXXXX     ",
		"       XoXoX         ",
	],
	"heli": [
		"      XXX      ",
		"     XSSSX     ",
		"    XXgggXX    ",
		"   XgllcllgX   ",
		"  XglccccclgX  ",
		"  XgllcccllgX  ",
		"  XGgllllllgX  ",
		"  XGGggggggGX  ",
		"   XGGGGGGGX   ",
		"    XGGGGGX    ",
		"     XGGGX     ",
		"     XGGGX     ",
		"   XXXGGGXXX   ",
		"   XXXXXXXXX   ",
		"     XXXXX     ",
	],
	"rotor": [
		"    nnnnnnnnnnnnn    ",
		"nnnnnnnnnnSnnnnnnnnnn",
		"    nnnnnnnnnnnnn    ",
	],
	"rocket": [
		"XX     XX",
		"XXX   XXX",
		"XXXXXXXXX",
		" XXrrrXX ",
		"XXrRrRrXX",
		"XrRrRrRrX",
		"XrRrRrRrX",
		"XrRrRrRrX",
		"XrRrRrRrX",
		"XXrrrrrXX",
		" XXXXXXX ",
		" XbbbbbX ",
		" XbBBBbX ",
		" XbBBBbX ",
		"  XbbbX  ",
		"   XXX   ",
	],
	"bullet": [
		" X ",
		"XwX",
		"XhX",
		"XhX",
		"XyX",
		"XoX",
		" X ",
	],
	"ebullet": [
		"  XXX  ",
		" XpppX ",
		"XpwwppX",
		"XpwpppX",
		"XpppppX",
		" XpppX ",
		"  XXX  ",
	],
	"pickup_power": [
		"  XXXXXXX  ",
		" XbbbbbbbX ",
		"XbbbbwbbbbX",
		"XbbbwwwbbbX",
		"XbbwwwwwbbX",
		"XbwwwwwwwbX",
		"XbbbwwwbbbX",
		"XbbbwwwbbbX",
		"XbbbwwwbbbX",
		" XBBBBBBBX ",
		"  XXXXXXX  ",
	],
	"pickup_bomb": [
		"  XXXXXXX  ",
		" XyyyyyyyX ",
		"XyyyykyyyyX",
		"XyyykkkyyyX",
		"XyykkkkkyyX",
		"XykkkkkkkyX",
		"XyykkkkkyyX",
		"XyyykkkyyyX",
		"XyyyykyyyyX",
		" XTTTTTTTX ",
		"  XXXXXXX  ",
	],
	"pickup_life": [
		"  XXXXXXX  ",
		" XrrrrrrrX ",
		"XrrrrwrrrrX",
		"XrrrrwrrrrX",
		"XrwwwwwwwrX",
		"XrwwwwwwwrX",
		"XrrrrwrrrrX",
		"XrrrrwrrrrX",
		"XrrrrrrrrrX",
		" XRRRRRRRX ",
		"  XXXXXXX  ",
	],
}

var _cache: Dictionary = {}
var explosion_frames: Array[Texture2D] = []


func _ready() -> void:
	for key in SPRITES.keys():
		_cache[key] = _from_rows(SPRITES[key])
	_cache["boss"] = _make_boss()
	_cache["ocean"] = _make_ocean_tile()
	_cache["foam"] = _make_foam_tile()
	_cache["px"] = _solid(Color.WHITE)
	explosion_frames = _make_explosion_frames()


func tex(name: String) -> Texture2D:
	return _cache.get(name)


func size_of(name: String) -> Vector2:
	var t: Texture2D = _cache.get(name)
	return Vector2(t.get_size()) if t else Vector2.ZERO


# --- builders ---------------------------------------------------------------

func _from_rows(rows: Array) -> ImageTexture:
	var w := 0
	for r in rows:
		w = maxi(w, (r as String).length())
	var h := rows.size()
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			var col: Color = PAL.get(ch, Color(0, 0, 0, 0))
			if col.a > 0.0:
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


func _solid(c: Color) -> ImageTexture:
	var img := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, c)
	return ImageTexture.create_from_image(img)


func _fill(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var iw := img.get_width()
	var ih := img.get_height()
	for py in range(maxi(y, 0), mini(y + h, ih)):
		for px in range(maxi(x, 0), mini(x + w, iw)):
			img.set_pixel(px, py, c)


## Fills a rect and its horizontal mirror, so big sprites stay symmetric.
func _sym(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	_fill(img, x, y, w, h, c)
	_fill(img, img.get_width() - x - w, y, w, h, c)


## Adds a 1px dark outline around the silhouette.
func _outline(img: Image, c: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var edges: Array[Vector2i] = []
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.0:
				continue
			var touching := false
			var neighbours: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			for d in neighbours:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				if img.get_pixel(nx, ny).a > 0.0:
					touching = true
					break
			if touching:
				edges.append(Vector2i(x, y))
	for e in edges:
		img.set_pixel(e.x, e.y, c)


## Draws a tapered aerofoil: straight leading edge, swept trailing edge.
func _wing(img: Image, cx: int, half_span: int, top: int, chord: int, sweep: float,
		body: Color, lead: Color, trail: Color) -> void:
	for x in range(cx - half_span, cx + half_span + 1):
		if x < 0 or x >= img.get_width():
			continue
		var d := absf(x - cx) / float(half_span)
		var y0 := top + int(d * 2.0)
		var y1 := top + chord - int(pow(d, 1.7) * sweep)
		if y1 <= y0 + 1:
			continue
		for y in range(y0, y1):
			var c := body
			if y < y0 + 2:
				c = lead
			elif y > y1 - 3:
				c = trail
			if y >= 0 and y < img.get_height():
				img.set_pixel(x, y, c)


## The stage boss: a huge four-engine bomber.
func _make_boss() -> ImageTexture:
	var w := 63
	var h := 56
	var cx := 31
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var green: Color = PAL["g"]
	var dark: Color = PAL["G"]
	var light: Color = PAL["l"]
	var steel: Color = PAL["S"]
	var glass: Color = PAL["c"]

	# fuselage, nose first
	_fill(img, cx - 3, 0, 7, 5, dark)
	_fill(img, cx - 5, 3, 11, 14, green)
	_fill(img, cx - 7, 14, 15, 26, green)
	_fill(img, cx - 5, 38, 11, 14, green)
	# fuselage shading + spine
	_fill(img, cx - 7, 16, 3, 24, light)
	_fill(img, cx + 4, 16, 3, 24, dark)
	_fill(img, cx - 1, 5, 2, 46, light)
	# glass: cockpit and belly turret
	_fill(img, cx - 3, 4, 7, 6, glass)
	_fill(img, cx - 2, 32, 5, 6, glass)

	# main wing and tail plane
	_wing(img, cx, 31, 18, 14, 9.0, green, light, dark)
	_wing(img, cx, 16, 43, 8, 5.0, green, light, dark)

	# engine nacelles, two per side
	for ex in [9, 19]:
		_sym(img, ex, 14, 7, 23, steel)
		_sym(img, ex + 1, 16, 5, 18, green)
		_sym(img, ex + 1, 14, 5, 3, dark)
		_sym(img, ex + 2, 34, 3, 4, PAL["o"])

	# tail fins and red squadron stripes
	_sym(img, 22, 36, 4, 11, dark)
	_sym(img, 23, 36, 2, 11, steel)
	_sym(img, 2, 20, 5, 2, PAL["r"])
	_sym(img, 15, 20, 3, 2, PAL["r"])

	_outline(img, PAL["X"])
	return ImageTexture.create_from_image(img)


## Chunky mosaic ocean, in the spirit of the reference screenshot.
func _make_ocean_tile() -> ImageTexture:
	var s := 64
	var img := Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	var base := Color("1668a8")
	var shades := [Color("1668a8"), Color("1a74b6"), Color("125e99"), Color("1f80c4")]
	_fill(img, 0, 0, s, s, base)
	# 4x4 mosaic blocks
	for by in range(0, s, 4):
		for bx in range(0, s, 4):
			var c: Color = shades[rng.randi_range(0, shades.size() - 1)]
			_fill(img, bx, by, 4, 4, c)
	# a few brighter wave crests
	for i in 14:
		var x := rng.randi_range(0, s - 1)
		var y := rng.randi_range(0, s - 1)
		var len_ := rng.randi_range(6, 16)
		for k in len_:
			var px := (x + k) % s
			img.set_pixel(px, y, Color("2f92d2"))
			if k % 3 == 0:
				img.set_pixel(px, (y + 1) % s, Color("2a89c8"))
	return ImageTexture.create_from_image(img)


## Sparse white streaks scrolling faster than the water, for parallax.
func _make_foam_tile() -> ImageTexture:
	var s := 128
	var img := Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	for i in 26:
		var x := rng.randi_range(0, s - 1)
		var y := rng.randi_range(0, s - 1)
		var len_ := rng.randi_range(4, 14)
		var a := rng.randf_range(0.12, 0.32)
		for k in len_:
			img.set_pixel((x + k) % s, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _make_explosion_frames() -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	var n := 8
	var size := 40
	var c := (size - 1) * 0.5
	for i in n:
		var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
		var t := float(i) / float(n - 1)
		var rad: float = lerp(5.0, 19.0, sqrt(t))
		for y in size:
			for x in size:
				var dx := x - c
				var dy := y - c
				var d := sqrt(dx * dx + dy * dy)
				var ang := atan2(dy, dx)
				var wobble := 1.0 + 0.20 * sin(ang * 5.0 + i * 1.3) + 0.10 * sin(ang * 9.0 - i)
				var rr: float = rad * wobble
				if d > rr:
					continue
				var f := d / maxf(rr, 0.001)
				var col: Color
				if t > 0.6 and f > 0.5:
					col = Color(0.22, 0.20, 0.19, 1.0)
				elif f < 0.32:
					col = Color("fff6d0")
				elif f < 0.58:
					col = Color("ffd23f")
				elif f < 0.82:
					col = Color("ff8a1e")
				else:
					col = Color("d93b17")
				col.a *= clampf(1.5 - t * 1.2, 0.2, 1.0)
				img.set_pixel(x, y, col)
		frames.append(ImageTexture.create_from_image(img))
	return frames
