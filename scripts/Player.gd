extends Area2D
class_name Player

const SPEED := 340.0
const BULLET_SPEED := 820.0
const FIRE_RATE := 0.105
const HALF_W := 24.0
const HALF_H := 26.0

var invuln := 2.0
var alive := true

var _fire_cd := 0.0
var _sprite: Sprite2D
var _flames: Array[Sprite2D] = []
var _drag := false
var _drag_offset := Vector2.ZERO
var _t := 0.0
var _bank := 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = Art.tex("player")
	_sprite.scale = Vector2(G.PIX, G.PIX)
	add_child(_sprite)

	for sx in [-1.0, 1.0]:
		var f := Sprite2D.new()
		f.texture = Art.tex("px")
		f.modulate = Color("ffb03a")
		f.position = Vector2(sx * 11.0, 27.0)
		f.scale = Vector2(4, 10)
		add_child(f)
		_flames.append(f)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	add_child(shape)

	collision_layer = G.L_PLAYER
	collision_mask = G.L_ENEMY | G.L_EBULLET | G.L_PICKUP
	area_entered.connect(_on_area)
	z_index = 20


func _process(delta: float) -> void:
	_t += delta
	if not alive:
		return
	_move(delta)
	_flicker(delta)

	if invuln > 0.0:
		invuln -= delta

	_fire_cd -= delta
	if _fire_cd <= 0.0 and G.state == G.State.PLAYING and not G.debug_no_fire:
		_fire_cd = FIRE_RATE
		_shoot()

	if Input.is_action_just_pressed("bomb") and G.state == G.State.PLAYING:
		use_bomb()


func _move(delta: float) -> void:
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir != Vector2.ZERO:
		_drag = false
		position += dir.normalized() * SPEED * delta
		_bank = lerpf(_bank, dir.x, delta * 8.0)
	elif _drag:
		var target := get_global_mouse_position() + _drag_offset
		var prev := position.x
		position = position.lerp(target, clampf(delta * 22.0, 0.0, 1.0))
		_bank = lerpf(_bank, clampf((position.x - prev) * 0.25, -1.0, 1.0), delta * 8.0)
	else:
		_bank = lerpf(_bank, 0.0, delta * 6.0)

	position.x = clampf(position.x, HALF_W, G.SW - HALF_W)
	position.y = clampf(position.y, HALF_H, G.SH - HALF_H)
	_sprite.skew = -_bank * 0.18
	_sprite.scale.x = G.PIX * (1.0 - absf(_bank) * 0.18)


func _flicker(delta: float) -> void:
	var flame_h: float = 8.0 + 5.0 * sin(_t * 40.0)
	for f in _flames:
		f.scale.y = flame_h
		f.position.y = 24.0 + flame_h * 0.5
		f.modulate.a = 0.75 + 0.25 * sin(_t * 33.0)
	if invuln > 0.0 and invuln < 90.0:
		_sprite.modulate.a = 0.35 if int(_t * 14.0) % 2 == 0 else 1.0
	else:
		_sprite.modulate.a = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and G.state == G.State.PLAYING:
			_drag = true
			var off := position - get_global_mouse_position()
			# grabbing far from the plane snaps it under the cursor
			_drag_offset = off if off.length() < 120.0 else Vector2.ZERO
		else:
			_drag = false
	elif event is InputEventScreenTouch:
		_drag = event.pressed
		if event.pressed:
			_drag_offset = Vector2.ZERO


func _shoot() -> void:
	var p := G.power
	var lanes: Array = []
	match p:
		1:
			lanes = [Vector2(-6, 0), Vector2(6, 0)]
		2:
			lanes = [Vector2(-13, 0), Vector2(0, -4), Vector2(13, 0)]
		3:
			lanes = [Vector2(-18, 0), Vector2(-6, -4), Vector2(6, -4), Vector2(18, 0)]
		4:
			lanes = [Vector2(-18, 0), Vector2(-6, -4), Vector2(6, -4), Vector2(18, 0)]
		5:
			lanes = [Vector2(-22, 2), Vector2(-11, -2), Vector2(0, -6), Vector2(11, -2), Vector2(22, 2)]
		_:
			lanes = [Vector2(-22, 2), Vector2(-11, -2), Vector2(0, -6), Vector2(11, -2), Vector2(22, 2)]

	var dmg := 1 if p < 5 else 2
	for off in lanes:
		_spawn_bullet(off, Vector2(0, -BULLET_SPEED), dmg)

	if p >= 4:
		var spread := 14.0 if p == 4 else 20.0
		_spawn_bullet(Vector2(-20, 6), Vector2(0, -BULLET_SPEED).rotated(deg_to_rad(-spread)), 1)
		_spawn_bullet(Vector2(20, 6), Vector2(0, -BULLET_SPEED).rotated(deg_to_rad(spread)), 1)
	if p >= 6:
		_spawn_bullet(Vector2(-24, 10), Vector2(0, -BULLET_SPEED).rotated(deg_to_rad(-38)), 1)
		_spawn_bullet(Vector2(24, 10), Vector2(0, -BULLET_SPEED).rotated(deg_to_rad(38)), 1)

	Sfx.play("shoot", -16.0, randf_range(0.95, 1.06))


func _spawn_bullet(offset: Vector2, vel: Vector2, dmg: int) -> void:
	var b := Bullet.new()
	b.setup(true, vel, dmg)
	b.position = position + offset + Vector2(0, -18)
	G.world.add_child(b)


func use_bomb() -> void:
	if G.bombs <= 0:
		return
	G.add_bomb(-1)
	Sfx.play("bigboom", 0.0, 0.8)
	G.shake(18.0)
	if G.world.has_method("flash"):
		G.world.flash(0.55)
	for b in get_tree().get_nodes_in_group("ebullet"):
		b.queue_free()
	for e in G.enemies():
		if e.has_method("damage"):
			e.damage(8, e.global_position)
	for i in 6:
		G.boom(Vector2(randf_range(40, G.SW - 40), randf_range(80, G.SH - 120)), 1.6)


func _on_area(area: Area2D) -> void:
	if area is Pickup:
		area.collect()
		return
	if invuln > 0.0 or not alive:
		return
	if area is Bullet and not area.from_player:
		area.queue_free()
		hit()
	elif area.is_in_group("enemy"):
		if area.has_method("damage"):
			area.damage(3, global_position)
		hit()


func hit() -> void:
	if invuln > 0.0 or not alive:
		return
	G.add_life(-1)
	G.add_power(-2)
	G.boom(position, 1.4, true)
	invuln = 2.6
	if G.lives <= 0:
		alive = false
		visible = false
		set_deferred("monitoring", false)
		if G.world.has_method("on_player_dead"):
			G.world.on_player_dead()
