extends Area2D
class_name Boss

var max_hp := 260
var hp := 260
var level := 1

var _t := 0.0
var _entered := false
var _dying := false
var _die_t := 0.0
var _fire_cd := 1.2
var _sweep_cd := 4.0
var _sprite: Sprite2D
var _flash_sprite: Sprite2D
var _flash := 0.0
var _fires: Array[Sprite2D] = []
var _center_x := G.SW * 0.5


func configure(lv: int) -> void:
	level = lv
	max_hp = 220 + (lv - 1) * 150
	hp = max_hp


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	position = Vector2(G.SW * 0.5, -140.0)

	_sprite = Sprite2D.new()
	_sprite.texture = Art.tex("boss")
	_sprite.scale = Vector2(G.PIX, G.PIX)
	add_child(_sprite)

	_flash_sprite = Sprite2D.new()
	_flash_sprite.texture = _sprite.texture
	_flash_sprite.scale = _sprite.scale
	_flash_sprite.modulate = Color(1, 1, 1, 0)
	_flash_sprite.z_index = 3
	add_child(_flash_sprite)

	# damage fires, revealed as health drops
	for p in [Vector2(-58, -6), Vector2(58, -6), Vector2(0, 34)]:
		var f := Sprite2D.new()
		f.texture = Art.explosion_frames[3]
		f.scale = Vector2(G.PIX, G.PIX) * 0.7
		f.position = p
		f.visible = false
		f.z_index = 4
		add_child(f)
		_fires.append(f)

	_add_box(Vector2(0, -10.5), Vector2(186, 36)) # wings
	_add_box(Vector2(0, -6), Vector2(45, 150)) # fuselage
	_add_box(Vector2(0, 57), Vector2(111, 27)) # tail

	collision_layer = G.L_ENEMY
	collision_mask = 0
	set_deferred("monitoring", false)
	z_index = 12
	G.boss = self


func _add_box(offset: Vector2, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = offset
	add_child(shape)


func _process(delta: float) -> void:
	_t += delta
	if _dying:
		_process_death(delta)
		return

	if not _entered:
		position.y = move_toward(position.y, 120.0, 90.0 * delta)
		if is_equal_approx(position.y, 120.0):
			_entered = true
		return

	var frac := float(hp) / float(max_hp)
	var phase := 3 if frac < 0.3 else (2 if frac < 0.62 else 1)
	var sway_speed: float = 0.5 + 0.16 * phase + 0.04 * level
	position.x = _center_x + sin(_t * sway_speed) * (G.SW * 0.5 - 100.0)
	position.y = 120.0 + sin(_t * 0.8) * 16.0

	_fires[0].visible = phase >= 2
	_fires[1].visible = phase >= 2
	_fires[2].visible = phase >= 3
	for f in _fires:
		if f.visible:
			f.texture = Art.explosion_frames[2 + (int(_t * 14.0) % 3)]
			f.rotation = randf() * TAU

	if _flash > 0.0:
		_flash = maxf(_flash - delta * 6.0, 0.0)
		_flash_sprite.modulate.a = _flash

	if G.state != G.State.PLAYING:
		return

	_fire_cd -= delta
	if _fire_cd <= 0.0:
		_fire_cd = lerpf(1.15, 0.55, (phase - 1) / 2.0) * randf_range(0.85, 1.15)
		_attack(phase)

	_sweep_cd -= delta
	if _sweep_cd <= 0.0:
		_sweep_cd = 6.5 - phase * 0.8
		_ring(phase)


func _attack(phase: int) -> void:
	var speed := 210.0 + 20.0 * phase + 8.0 * level
	var guns := [Vector2(-84, 20), Vector2(-40, 30), Vector2(40, 30), Vector2(84, 20)]
	if G.player != null and is_instance_valid(G.player):
		var aim := (G.player.global_position - global_position).normalized()
		for g in guns:
			var a := aim.rotated(deg_to_rad(randf_range(-6.0, 6.0)))
			G.enemy_bullet(global_position + g, a * speed)
	if phase >= 2:
		for i in range(-2, 3):
			G.enemy_bullet(global_position + Vector2(0, 60), Vector2(0, 1).rotated(deg_to_rad(i * 15.0)) * speed * 0.9)
	Sfx.play("shoot", -14.0, 0.6)


func _ring(phase: int) -> void:
	var count := 10 + phase * 4
	var speed := 165.0 + 12.0 * level
	for i in count:
		var a := TAU * i / count + _t
		G.enemy_bullet(global_position + Vector2(0, 20), Vector2(cos(a), sin(a)) * speed)
	Sfx.play("ehit", -12.0, 0.7)


func damage(n: int, _from: Vector2 = Vector2.ZERO) -> void:
	if _dying:
		return
	hp -= n
	_flash = 1.0
	Sfx.play("hit", -22.0, randf_range(0.8, 1.0))
	if hp <= 0:
		hp = 0
		_start_death()


func _start_death() -> void:
	_dying = true
	_die_t = 0.0
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	G.add_score(3000 + level * 1500)
	Sfx.play("warn", -6.0, 0.5)
	for b in get_tree().get_nodes_in_group("ebullet"):
		b.queue_free()


func _process_death(delta: float) -> void:
	_die_t += delta
	position.y += 24.0 * delta
	_sprite.position = Vector2(randf_range(-3, 3), randf_range(-3, 3))
	if fmod(_die_t, 0.12) < delta:
		G.boom(global_position + Vector2(randf_range(-85, 85), randf_range(-60, 60)), randf_range(1.0, 2.0))
	if _die_t > 2.0:
		G.boom(global_position, 4.0, true)
		G.spawn_pickup(global_position + Vector2(-50, 0), "power")
		G.spawn_pickup(global_position + Vector2(0, 0), "life")
		G.spawn_pickup(global_position + Vector2(50, 0), "bomb")
		G.boss = null
		if G.world.has_method("on_boss_dead"):
			G.world.on_boss_dead()
		queue_free()
