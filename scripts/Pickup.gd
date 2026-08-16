extends Area2D
class_name Pickup

var kind := "power" # "power" | "life" | "bomb"

var _t := 0.0
var _sprite: Sprite2D
var _base_x := 0.0


func _ready() -> void:
	_base_x = position.x
	_sprite = Sprite2D.new()
	_sprite.texture = Art.tex("pickup_" + kind)
	_sprite.scale = Vector2(G.PIX, G.PIX)
	add_child(_sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	add_child(shape)

	add_to_group("pickup")
	collision_layer = G.L_PICKUP
	collision_mask = 0
	set_deferred("monitoring", false)
	z_index = 5


func _process(delta: float) -> void:
	_t += delta
	position.y += 95.0 * delta
	position.x = _base_x + sin(_t * 3.0) * 14.0
	_sprite.scale = Vector2(G.PIX, G.PIX) * (1.0 + 0.08 * sin(_t * 8.0))
	if position.y > G.SH + 40.0:
		queue_free()


func collect() -> void:
	match kind:
		"life":
			G.add_life(1)
		"bomb":
			G.add_bomb(1)
		_:
			G.add_power(1)
			G.add_score(150)
	Sfx.play("pickup", -3.0)
	queue_free()
