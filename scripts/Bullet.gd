extends Area2D
class_name Bullet

var velocity := Vector2(0, -700)
var damage := 1
var from_player := true
var spin := false

var _sprite: Sprite2D


func setup(is_player: bool, vel: Vector2, dmg: int = 1) -> void:
	from_player = is_player
	velocity = vel
	damage = dmg


func _ready() -> void:
	var art := "bullet" if from_player else "ebullet"
	_sprite = Sprite2D.new()
	_sprite.texture = Art.tex(art)
	_sprite.scale = Vector2(G.PIX, G.PIX) * (1.0 if from_player else 0.9)
	if from_player:
		_sprite.rotation = velocity.angle() + PI * 0.5
	add_child(_sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = (7.0 if from_player else 8.0)
	shape.shape = circle
	add_child(shape)

	if from_player:
		collision_layer = G.L_PBULLET
		collision_mask = G.L_ENEMY
		area_entered.connect(_on_hit_enemy)
	else:
		collision_layer = G.L_EBULLET
		collision_mask = 0
		set_deferred("monitoring", false)
		add_to_group("ebullet")


func _physics_process(delta: float) -> void:
	position += velocity * delta
	if not from_player:
		_sprite.rotation += delta * 6.0
	var m := 60.0
	if position.y < -m or position.y > G.SH + m or position.x < -m or position.x > G.SW + m:
		queue_free()


func _on_hit_enemy(area: Area2D) -> void:
	if area.has_method("damage"):
		area.damage(damage, global_position)
		queue_free()
