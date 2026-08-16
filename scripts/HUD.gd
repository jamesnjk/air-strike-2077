extends CanvasLayer
class_name HUD

var _score: Label
var _high: Label
var _lives: Label
var _bombs: Label
var _bomb_btn: Control
var _life_icon: TextureRect
var _power_cells: Array[ColorRect] = []
var _boss_bar_bg: ColorRect
var _boss_bar_fill: ColorRect
var _banner: Label
var _center: VBoxContainer
var _title: Label
var _subtitle: Label
var _hint: Label
var _banner_t := 0.0


func _ready() -> void:
	layer = 10

	_score = _label(Vector2(12, 8), 20, Color("ffffff"))
	_high = _label(Vector2(12, 32), 13, Color("ffd23f"))

	_life_icon = TextureRect.new()
	_life_icon.texture = Art.tex("player")
	_life_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_life_icon.custom_minimum_size = Vector2(22, 24)
	_life_icon.size = Vector2(22, 24)
	_life_icon.position = Vector2(G.SW - 96, 8)
	add_child(_life_icon)

	_lives = _label(Vector2(G.SW - 68, 12), 18, Color("ffffff"))
	_build_bomb_button()

	# power meter
	for i in G.MAX_POWER:
		var c := ColorRect.new()
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.size = Vector2(12, 7)
		c.position = Vector2(G.SW - 110 + i * 16, 60)
		c.color = Color(1, 1, 1, 0.15)
		add_child(c)
		_power_cells.append(c)

	# boss health bar
	_boss_bar_bg = ColorRect.new()
	_boss_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar_bg.size = Vector2(G.SW - 80, 14)
	_boss_bar_bg.position = Vector2(40, G.SH - 34)
	_boss_bar_bg.color = Color(0, 0, 0, 0.6)
	_boss_bar_bg.visible = false
	add_child(_boss_bar_bg)

	_boss_bar_fill = ColorRect.new()
	_boss_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar_fill.size = Vector2(G.SW - 88, 10)
	_boss_bar_fill.position = Vector2(44, G.SH - 32)
	_boss_bar_fill.color = Color("ff3b3b")
	_boss_bar_fill.visible = false
	add_child(_boss_bar_fill)

	_banner = _label(Vector2(0, G.SH * 0.32), 30, Color("ffd23f"))
	_banner.size = Vector2(G.SW, 40)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0

	_center = VBoxContainer.new()
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center.position = Vector2(0, G.SH * 0.34)
	_center.size = Vector2(G.SW, 200)
	_center.alignment = BoxContainer.ALIGNMENT_CENTER
	_center.add_theme_constant_override("separation", 14)
	add_child(_center)

	_title = _make_label(40, Color("ffd23f"))
	_subtitle = _make_label(16, Color("ffffff"))
	_hint = _make_label(15, Color("8fe3ff"))
	_center.add_child(_title)
	_center.add_child(_subtitle)
	_center.add_child(_hint)

	G.score_changed.connect(func(_s): _refresh())
	G.lives_changed.connect(func(_s): _refresh())
	G.power_changed.connect(func(_s): _refresh())
	G.bombs_changed.connect(func(_s): _refresh())
	G.state_changed.connect(_on_state)
	_refresh()
	_on_state(G.state)


## Tappable bomb button for touch devices; the Space key does the same thing.
func _build_bomb_button() -> void:
	_bomb_btn = Control.new()
	_bomb_btn.position = Vector2(14, G.SH - 122)
	_bomb_btn.size = Vector2(78, 78)
	_bomb_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_bomb_btn.gui_input.connect(_on_bomb_input)
	add_child(_bomb_btn)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.32)
	style.border_color = Color(1, 1, 1, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(39)
	var panel := Panel.new()
	panel.size = _bomb_btn.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", style)
	_bomb_btn.add_child(panel)

	var icon := TextureRect.new()
	icon.texture = Art.tex("pickup_bomb")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	icon.size = Vector2(44, 44)
	icon.position = Vector2(17, 12)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bomb_btn.add_child(icon)

	_bombs = _make_label(15, Color("ffd23f"))
	_bombs.position = Vector2(0, 52)
	_bombs.size = Vector2(78, 20)
	_bombs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bomb_btn.add_child(_bombs)


func _on_bomb_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed
	if not pressed:
		return
	_bomb_btn.accept_event() # don't let the tap drag the plane
	if G.state == G.State.PLAYING and G.player != null and is_instance_valid(G.player):
		G.player.use_bomb()


func _make_label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	return l


func _label(pos: Vector2, size: int, color: Color) -> Label:
	var l := _make_label(size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.position = pos
	add_child(l)
	return l


func _refresh() -> void:
	_score.text = "%07d" % G.score
	_high.text = "HI %07d" % G.high_score
	_lives.text = "× %d" % G.lives
	_bombs.text = "× %d" % G.bombs
	_bomb_btn.modulate = Color(1, 1, 1, 1.0 if G.bombs > 0 else 0.35)
	for i in _power_cells.size():
		_power_cells[i].color = Color("ffd23f") if i < G.power else Color(1, 1, 1, 0.15)


func _on_state(state: int) -> void:
	_bomb_btn.visible = state == G.State.PLAYING
	match state:
		G.State.TITLE:
			_center.visible = true
			_title.text = "AIR STRIKE 2077"
			_subtitle.text = "Drag to fly  •  guns fire automatically\nTap the bomb button (or SPACE) to clear the screen"
			_hint.text = "— PRESS ENTER OR CLICK TO START —"
		G.State.GAME_OVER:
			_center.visible = true
			_title.text = "GAME OVER"
			_subtitle.text = "SCORE %d\nBEST %d" % [G.score, G.high_score]
			_hint.text = "— PRESS ENTER OR CLICK TO RETRY —"
		_:
			_center.visible = false


func show_banner(text: String, seconds: float = 1.6) -> void:
	_banner.text = text
	_banner_t = seconds
	if _banner.get_parent() == null:
		add_child(_banner)


func _process(delta: float) -> void:
	if _banner_t > 0.0:
		_banner_t -= delta
		_banner.modulate.a = clampf(_banner_t * 2.0, 0.0, 1.0)
		_banner.scale = Vector2.ONE
	else:
		_banner.modulate.a = 0.0

	var boss: Node = G.boss
	var show_bar: bool = boss != null and is_instance_valid(boss)
	_boss_bar_bg.visible = show_bar
	_boss_bar_fill.visible = show_bar
	if show_bar:
		var frac: float = clampf(float(boss.hp) / float(boss.max_hp), 0.0, 1.0)
		_boss_bar_fill.size.x = (G.SW - 88) * frac
		_boss_bar_fill.color = Color("ff3b3b") if frac > 0.3 else Color("ff9d2e")

	if _hint != null and _center.visible:
		_hint.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 260.0)
