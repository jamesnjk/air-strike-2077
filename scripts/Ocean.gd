extends Node2D
class_name Ocean
## Scrolling mosaic sea with a faster foam layer for parallax.

var speed := 90.0

var _water: Sprite2D
var _foam: Sprite2D
var _scroll := 0.0


func _ready() -> void:
	z_index = -100

	_water = Sprite2D.new()
	_water.texture = Art.tex("ocean")
	_water.centered = false
	_water.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_water.region_enabled = true
	_water.scale = Vector2(2, 2)
	_water.region_rect = Rect2(0, 0, G.SW * 0.5 + 64, G.SH * 0.5 + 64)
	add_child(_water)

	_foam = Sprite2D.new()
	_foam.texture = Art.tex("foam")
	_foam.centered = false
	_foam.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_foam.region_enabled = true
	_foam.scale = Vector2(3, 3)
	_foam.region_rect = Rect2(0, 0, G.SW / 3.0 + 64, G.SH / 3.0 + 64)
	_foam.modulate = Color(1, 1, 1, 0.5)
	add_child(_foam)


func _process(delta: float) -> void:
	_scroll += speed * delta
	_water.region_rect.position.y = -_scroll * 0.5
	_foam.region_rect.position.y = -_scroll * 1.1
