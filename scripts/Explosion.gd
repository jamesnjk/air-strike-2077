extends Node2D
class_name Explosion

var pop_scale := 1.0
var fps := 22.0

var _sprite: Sprite2D
var _t := 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = Art.explosion_frames[0]
	_sprite.scale = Vector2(G.PIX, G.PIX) * pop_scale
	_sprite.rotation = randf() * TAU
	add_child(_sprite)
	z_index = 40


func _process(delta: float) -> void:
	_t += delta * fps
	var i := int(_t)
	if i >= Art.explosion_frames.size():
		queue_free()
		return
	_sprite.texture = Art.explosion_frames[i]
	_sprite.scale = Vector2(G.PIX, G.PIX) * pop_scale * (1.0 + 0.12 * _t / Art.explosion_frames.size())
