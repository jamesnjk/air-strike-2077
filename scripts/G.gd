extends Node
## Global game state + spawn helpers.

signal score_changed(score: int)
signal lives_changed(lives: int)
signal power_changed(power: int)
signal bombs_changed(bombs: int)
signal state_changed(state: int)

enum State { TITLE, PLAYING, DEAD, GAME_OVER }

# collision layer bits
const L_PLAYER := 1
const L_PBULLET := 2
const L_ENEMY := 4
const L_EBULLET := 8
const L_PICKUP := 16

const SW := 480.0
const SH := 720.0
const PIX := 3.0 # sprite upscale factor
const MAX_POWER := 6
const SAVE_PATH := "user://airstrike.cfg"

var world: Node2D
var player: Node2D
var state: int = State.TITLE
var score := 0
var high_score := 0
var lives := 3
var power := 1
var bombs := 2
var wave := 0
var boss: Node2D
var debug_no_fire := false


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		high_score = int(cfg.get_value("stats", "high_score", 0))


func reset_run() -> void:
	score = 0
	lives = 3
	power = 1
	bombs = 2
	wave = 0
	boss = null
	score_changed.emit(score)
	lives_changed.emit(lives)
	power_changed.emit(power)
	bombs_changed.emit(bombs)


func set_state(s: int) -> void:
	state = s
	state_changed.emit(s)


func add_score(n: int) -> void:
	score += n
	if score > high_score:
		high_score = score
		var cfg := ConfigFile.new()
		cfg.set_value("stats", "high_score", high_score)
		cfg.save(SAVE_PATH)
	score_changed.emit(score)


func add_power(n: int) -> void:
	power = clampi(power + n, 1, MAX_POWER)
	power_changed.emit(power)


func add_life(n: int) -> void:
	lives = clampi(lives + n, 0, 9)
	lives_changed.emit(lives)


func add_bomb(n: int) -> void:
	bombs = clampi(bombs + n, 0, 9)
	bombs_changed.emit(bombs)


# --- spawning ---------------------------------------------------------------

func boom(pos: Vector2, scale_: float = 1.0, big: bool = false) -> void:
	if world == null:
		return
	var e := Explosion.new()
	e.position = pos
	e.pop_scale = scale_
	# deferred: these are often spawned from inside a collision callback
	world.add_child.call_deferred(e)
	Sfx.play("bigboom" if big else "boom", -4.0, randf_range(0.9, 1.15))
	shake(6.0 * scale_ if big else 3.0 * scale_)


func spawn_pickup(pos: Vector2, kind: String) -> void:
	if world == null:
		return
	var p := Pickup.new()
	p.kind = kind
	p.position = pos
	world.add_child.call_deferred(p)


func enemy_bullet(pos: Vector2, vel: Vector2, speed_scale: float = 1.0) -> void:
	if world == null:
		return
	var b := Bullet.new()
	b.setup(false, vel * speed_scale, 1)
	b.position = pos
	world.add_child.call_deferred(b)


func shake(amount: float) -> void:
	if world != null and world.has_method("add_shake"):
		world.add_shake(amount)


func enemies() -> Array:
	return get_tree().get_nodes_in_group("enemy")
