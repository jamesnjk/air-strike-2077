extends Node2D
## Game root: owns the world, camera shake, wave director and state flow.

const WAVES_PER_BOSS := 4

var _camera: Camera2D
var _hud: HUD
var _flash_rect: ColorRect
var _shake := 0.0
var _flash := 0.0
var _wave_cd := 0.0
var _wave_active := false
var _boss_fight := false
var _respawn_cd := 0.0
var _rng := RandomNumberGenerator.new()
var _auto := false
var _shot := false
var _run_t := 0.0


func _ready() -> void:
	randomize()
	_rng.randomize()
	G.world = self

	add_child(Ocean.new())

	_camera = Camera2D.new()
	_camera.position = Vector2(G.SW * 0.5, G.SH * 0.5)
	_camera.enabled = true
	add_child(_camera)

	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 9
	add_child(flash_layer)
	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.size = Vector2(G.SW, G.SH)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(_flash_rect)

	_hud = HUD.new()
	add_child(_hud)

	G.set_state(G.State.TITLE)
	_spawn_player()

	# debug helpers: `--auto` plays hands-free, `--shot` saves a PNG and quits
	var args := OS.get_cmdline_args()
	_auto = args.has("--auto")
	_shot = args.has("--shot")
	if (_auto or _shot) and not args.has("--title"):
		_start_run()
		G.debug_no_fire = args.has("--peace")
		if args.has("--boss"):
			G.wave = WAVES_PER_BOSS
			G.power = G.MAX_POWER


func _process(delta: float) -> void:
	_update_shake(delta)
	if _auto or _shot:
		_debug_tick(delta)

	if _flash > 0.0:
		_flash = maxf(_flash - delta * 2.4, 0.0)
		_flash_rect.color.a = _flash

	match G.state:
		G.State.TITLE, G.State.GAME_OVER:
			if Input.is_action_just_pressed("start"):
				_start_run()
		G.State.PLAYING:
			_direct_waves(delta)
		G.State.DEAD:
			_respawn_cd -= delta
			if _respawn_cd <= 0.0:
				G.set_state(G.State.GAME_OVER)


# --- flow -------------------------------------------------------------------

func _start_run() -> void:
	for n in get_tree().get_nodes_in_group("enemy"):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("ebullet"):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("pickup"):
		n.queue_free()

	G.reset_run()
	_wave_active = false
	_boss_fight = false
	_wave_cd = 1.0
	_spawn_player()
	G.set_state(G.State.PLAYING)
	_hud.show_banner("GO!", 1.2)


func _spawn_player() -> void:
	if G.player != null and is_instance_valid(G.player):
		G.player.queue_free()
	var p := Player.new()
	p.position = Vector2(G.SW * 0.5, G.SH - 120.0)
	add_child(p)
	G.player = p


func on_player_dead() -> void:
	G.set_state(G.State.DEAD)
	_respawn_cd = 1.8
	add_shake(16.0)
	flash(0.4)


func on_boss_dead() -> void:
	_boss_fight = false
	_wave_active = false
	_wave_cd = 2.2
	_hud.show_banner("SECTOR CLEAR", 1.8)


# --- wave director ----------------------------------------------------------

func _direct_waves(delta: float) -> void:
	if _boss_fight:
		return
	if _wave_active:
		if get_tree().get_nodes_in_group("enemy").is_empty():
			_wave_active = false
			_wave_cd = 1.1
		return
	_wave_cd -= delta
	if _wave_cd <= 0.0:
		_next_wave()


func _next_wave() -> void:
	G.wave += 1
	_wave_active = true
	var diff := 1.0 + G.wave * 0.55

	if G.wave % (WAVES_PER_BOSS + 1) == 0:
		_boss_fight = true
		_hud.show_banner("!! WARNING !!", 2.0)
		Sfx.play("warn", -6.0)
		await get_tree().create_timer(1.6).timeout
		if G.state != G.State.PLAYING:
			return
		var b := Boss.new()
		b.configure(int(G.wave / (WAVES_PER_BOSS + 1)))
		add_child(b)
		return

	_hud.show_banner("WAVE %d" % G.wave, 1.1)
	var picks := ["line", "vee", "stream", "helis", "bombers", "rockets", "cross"]
	var pick: String = picks[_rng.randi_range(0, picks.size() - 1)]
	if G.wave <= 2:
		pick = "line" if G.wave == 1 else "vee"
	_spawn_formation(pick, diff)


func _spawn_formation(formation: String, diff: float) -> void:
	var drop_index := _rng.randi_range(0, 4)
	match formation:
		"line":
			for i in 5:
				var e := _make("fighter", "sine", diff)
				e.position = Vector2(60 + i * 90, -40 - i * 6)
				e.amp = 46.0
				e.freq = 1.5
				if i == drop_index:
					e.drop = _drop_kind()
				add_child(e)
		"vee":
			for i in 5:
				var e := _make("fighter", "straight", diff)
				var off: int = absi(i - 2)
				e.position = Vector2(90 + i * 75, -40 - (2 - off) * 34)
				if i == 2:
					e.drop = _drop_kind()
				add_child(e)
		"stream":
			for i in 8:
				_delayed(i * 0.32, func():
					var e := _make("fighter", "swoop", diff)
					var left: bool = i % 2 == 0
					e.position = Vector2(80.0 if left else G.SW - 80.0, -40)
					e._base_x = e.position.x
					e.amp = 150.0 if left else -150.0
					if i == 6:
						e.drop = _drop_kind()
					add_child(e))
		"helis":
			for i in 3:
				var e := _make("heli", "hover", diff)
				e.position = Vector2(90 + i * 150, -60 - i * 30)
				e.hover_y = 150 + i * 55
				e.strafe_dir = 1.0 if i % 2 == 0 else -1.0
				if i == 1:
					e.drop = _drop_kind()
				add_child(e)
		"bombers":
			for i in 2:
				var e := _make("bomber", "straight", diff)
				e.position = Vector2(140 + i * 200, -70 - i * 60)
				if i == 0:
					e.drop = _drop_kind()
				add_child(e)
			for i in 3:
				_delayed(0.8 + i * 0.4, func():
					var e := _make("fighter", "sine", diff)
					e.position = Vector2(90 + i * 150, -40)
					e._base_x = e.position.x
					add_child(e))
		"rockets":
			for i in 6:
				_delayed(i * 0.22, func():
					var e := _make("rocket", "dive", diff)
					e.position = Vector2(_rng.randf_range(50, G.SW - 50), -40)
					add_child(e))
			_delayed(1.9, func():
				var e := _make("heli", "hover", diff)
				e.position = Vector2(G.SW * 0.5, -60)
				e.hover_y = 170
				e.drop = _drop_kind()
				add_child(e))
		"cross":
			for i in 4:
				var e := _make("fighter", "sine", diff)
				e.position = Vector2(70 + i * 40, -40 - i * 25)
				e.amp = 120.0
				e.freq = 1.1
				add_child(e)
			for i in 4:
				var e := _make("fighter", "sine", diff)
				e.position = Vector2(G.SW - 70 - i * 40, -40 - i * 25)
				e.amp = -120.0
				e.freq = 1.1
				if i == 2:
					e.drop = _drop_kind()
				add_child(e)


func _make(kind: String, pattern: String, diff: float) -> Enemy:
	var e := Enemy.new()
	e.configure(kind, pattern, diff)
	return e


func _drop_kind() -> String:
	var r := _rng.randf()
	if r < 0.12:
		return "life"
	if r < 0.3:
		return "bomb"
	return "power"


func _delayed(seconds: float, fn: Callable) -> void:
	var t := get_tree().create_timer(seconds)
	t.timeout.connect(func():
		if G.state == G.State.PLAYING:
			fn.call())


# --- juice ------------------------------------------------------------------

func add_shake(amount: float) -> void:
	_shake = minf(_shake + amount, 26.0)


func flash(amount: float) -> void:
	_flash = maxf(_flash, amount)


## Hands-free play used to smoke-test the game and to grab screenshots.
func _debug_tick(delta: float) -> void:
	_run_t += delta
	if G.player != null and is_instance_valid(G.player):
		if G.debug_no_fire:
			G.player.invuln = 99.0 # keep screenshots free of the hit-blink
		G.player.position.x = G.SW * 0.5 + sin(_run_t * 1.3) * (G.SW * 0.36)
	if _auto and (G.state == G.State.GAME_OVER or G.state == G.State.TITLE):
		_start_run()
	if _shot and _run_t > float(OS.get_environment("SHOT_AT") if OS.has_environment("SHOT_AT") else "6.0"):
		_shot = false
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(OS.get_environment("SHOT_PATH") if OS.has_environment("SHOT_PATH") else "user://shot.png")
		get_tree().quit()


func _update_shake(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(_shake - delta * 40.0, 0.0)
		_camera.offset = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * _shake
	else:
		_camera.offset = Vector2.ZERO
