extends Area2D
class_name Enemy

## Stats per enemy type: hp, score, radius, base speed, fire interval.
const TYPES := {
	"fighter": {"art": "fighter", "hp": 2, "score": 100, "radius": 20.0, "speed": 165.0, "fire": 1.9},
	"heli": {"art": "heli", "hp": 4, "score": 180, "radius": 22.0, "speed": 110.0, "fire": 1.4},
	"bomber": {"art": "bomber", "hp": 10, "score": 400, "radius": 30.0, "speed": 78.0, "fire": 1.7},
	"rocket": {"art": "rocket", "hp": 3, "score": 150, "radius": 16.0, "speed": 330.0, "fire": 0.0},
}

var kind := "fighter"
var pattern := "sine"
var hp := 2
var speed := 160.0
var amp := 60.0
var freq := 1.6
var hover_y := 180.0
var strafe_dir := 1.0
var drop := "" # pickup kind dropped on death
var difficulty := 1.0

var _t := 0.0
var _base_x := 0.0
var _fire_cd := 0.0
var _fire_every := 2.0
var _score := 100
var _sprite: Sprite2D
var _flash_sprite: Sprite2D
var _flash := 0.0
var _rotor: Sprite2D
var _dead := false


func configure(k: String, pat: String = "sine", diff: float = 1.0) -> void:
	kind = k
	pattern = pat
	difficulty = diff
	var d: Dictionary = TYPES[k]
	hp = int(round(d.hp * lerpf(1.0, 2.2, clampf((diff - 1.0) / 8.0, 0.0, 1.0))))
	speed = d.speed * lerpf(1.0, 1.35, clampf((diff - 1.0) / 10.0, 0.0, 1.0))
	_score = d.score
	_fire_every = d.fire


func _ready() -> void:
	add_to_group("enemy")
	var d: Dictionary = TYPES[kind]
	_base_x = position.x
	_fire_cd = randf_range(0.4, _fire_every)

	if kind == "heli":
		_rotor = Sprite2D.new()
		_rotor.texture = Art.tex("rotor")
		_rotor.scale = Vector2(G.PIX, 2.0)
		_rotor.modulate = Color(1, 1, 1, 0.45)
		_rotor.z_index = 2
		add_child(_rotor)

	_sprite = Sprite2D.new()
	_sprite.texture = Art.tex(d.art)
	_sprite.scale = Vector2(G.PIX, G.PIX)
	add_child(_sprite)

	_flash_sprite = Sprite2D.new()
	_flash_sprite.texture = _sprite.texture
	_flash_sprite.scale = _sprite.scale
	_flash_sprite.modulate = Color(1, 1, 1, 0)
	_flash_sprite.z_index = 3
	add_child(_flash_sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = d.radius
	shape.shape = circle
	add_child(shape)

	collision_layer = G.L_ENEMY
	collision_mask = 0
	set_deferred("monitoring", false)
	z_index = 10


func _process(delta: float) -> void:
	_t += delta
	_move(delta)

	if _flash > 0.0:
		_flash = maxf(_flash - delta * 6.0, 0.0)
		_flash_sprite.modulate.a = _flash

	if _rotor != null:
		_rotor.scale.x = G.PIX * cos(_t * 26.0)

	if _fire_every > 0.0 and G.state == G.State.PLAYING and position.y > 0.0 and position.y < G.SH * 0.82:
		_fire_cd -= delta
		if _fire_cd <= 0.0:
			_fire_cd = _fire_every * randf_range(0.75, 1.25) / clampf(difficulty * 0.35 + 0.7, 0.7, 2.0)
			_fire()

	if position.y > G.SH + 80.0 or position.y < -260.0 or absf(position.x - G.SW * 0.5) > G.SW:
		queue_free()


func _move(delta: float) -> void:
	match pattern:
		"straight":
			position.y += speed * delta
		"sine":
			position.y += speed * delta
			position.x = _base_x + sin(_t * freq) * amp
		"dive":
			position.y += (speed + _t * 220.0) * delta
			position.x += sin(_t * 2.0) * 30.0 * delta
		"hover":
			if position.y < hover_y:
				position.y += speed * delta
			else:
				position.x += strafe_dir * speed * 0.9 * delta
				position.y += sin(_t * 2.2) * 22.0 * delta
				if position.x < 40.0:
					strafe_dir = 1.0
				elif position.x > G.SW - 40.0:
					strafe_dir = -1.0
		"swoop":
			# comes down, curves outward, then leaves
			position.y += speed * delta * (1.0 if _t < 1.6 else 1.6)
			position.x = _base_x + sin(clampf(_t, 0.0, PI) * 1.1) * amp
		_:
			position.y += speed * delta


func _fire() -> void:
	if G.player == null or not is_instance_valid(G.player):
		return
	var to_player := (G.player.global_position - global_position).normalized()
	var bullet_speed: float = lerpf(190.0, 300.0, clampf((difficulty - 1.0) / 9.0, 0.0, 1.0))
	match kind:
		"bomber":
			for a in [-16.0, 0.0, 16.0]:
				G.enemy_bullet(global_position + Vector2(0, 24), to_player.rotated(deg_to_rad(a)) * bullet_speed)
		"heli":
			G.enemy_bullet(global_position + Vector2(-14, 18), to_player * bullet_speed)
			G.enemy_bullet(global_position + Vector2(14, 18), to_player * bullet_speed)
		_:
			var jitter := deg_to_rad(randf_range(-7.0, 7.0))
			G.enemy_bullet(global_position + Vector2(0, 20), to_player.rotated(jitter) * bullet_speed)
	Sfx.play("shoot", -22.0, 0.7)


func damage(n: int, from: Vector2 = Vector2.ZERO) -> void:
	if _dead:
		return
	hp -= n
	_flash = 1.0
	_sprite.position = Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
	if hp <= 0:
		_die()
	else:
		Sfx.play("hit", -20.0, randf_range(0.9, 1.2))


func _die() -> void:
	_dead = true
	G.add_score(_score)
	var big := kind == "bomber"
	G.boom(global_position, 1.6 if big else 1.0, big)
	if drop != "":
		G.spawn_pickup(global_position, drop)
	queue_free()
