class_name BackgroundView
extends Control

var place := ""
var fade := 1.0
var time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	time += delta
	if fade > 0.0:
		fade = maxf(0.0, fade - delta * 1.8)
	queue_redraw()

func set_place(id: String) -> void:
	if id == place:
		return
	place = id
	fade = 1.0
	queue_redraw()

static func caption(id: String) -> String:
	match id:
		"cover":
			return "ПРИБРЕЖЬЕ"
		"locker":
			return "РАЗДЕВАЛКА"
		"street":
			return "БРОВКА"
		"west":
			return "ЗАПАДНАЯ ТРИБУНА"
		"pitch", "match1", "match2", "match3", "match4", "match_action", "match_mid", "match_goal":
			return "ПОЛЕ"
		"river":
			return "РЕКА"
		"tunnel":
			return "ТОННЕЛЬ"
		"factory":
			return "ЦЕХ · 2002"
		"apartment":
			return "КВАРТИРА"
		"epilogue":
			return "ПОСЛЕ"
		"whistle":
			return "ПОСЛЕДНИЕ МИНУТЫ"
		_:
			return ""

func _kind() -> String:
	match place:
		"locker":
			return "locker"
		"street":
			return "sideline"
		"west":
			return "stands"
		"pitch", "match1", "match2", "match3", "match4", "match_action", "match_mid", "match_goal":
			return "pitch"
		"river":
			return "river"
		"tunnel":
			return "tunnel"
		"factory":
			return "factory"
		"apartment", "epilogue":
			return "room"
		"whistle":
			return "dusk"
		"black":
			return "black"
		_:
			return "cover"

func _colors() -> Array:
	match _kind():
		"locker":
			return [Color.html("#3a2618"), Color.html("#120e0b")]
		"sideline":
			return [Color.html("#31445a"), Color.html("#141910")]
		"stands":
			return [Color.html("#3a404a"), Color.html("#121418")]
		"pitch":
			return [Color.html("#24543a"), Color.html("#101910")]
		"river":
			return [Color.html("#23485f"), Color.html("#0d1418")]
		"tunnel":
			return [Color.html("#241c18"), Color.html("#070605")]
		"factory":
			return [Color.html("#5a341c"), Color.html("#140e0c")]
		"room":
			return [Color.html("#3a3024"), Color.html("#14110e")]
		"dusk":
			return [Color.html("#5a3a2c"), Color.html("#140e0c")]
		"black":
			return [Color.html("#000000"), Color.html("#000000")]
		_:
			return [Color.html("#2a2218"), Color.html("#0c0b09")]

func _draw() -> void:
	var size := get_size()
	if size.x < 2.0:
		return
	var colors: Array = _colors()
	var sky: Color = colors[0]
	var ground: Color = colors[1]
	draw_rect(Rect2(Vector2.ZERO, size), ground)
	var sky_h := size.y * 0.62
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, sky_h)), sky)
	var kind := _kind()
	if kind == "pitch":
		_draw_pitch(size)
	elif kind == "river":
		_draw_river(size)
	elif kind == "locker":
		_draw_locker(size)
	elif kind == "sideline":
		_draw_sideline(size)
	elif kind == "stands":
		_draw_stands(size)
	elif kind == "tunnel":
		_draw_tunnel(size)
	elif kind == "factory":
		_draw_factory(size)
	elif kind == "room":
		_draw_room(size)
	elif kind == "dusk":
		_draw_dusk(size)
	elif kind == "cover":
		_draw_cover(size)
	var vig := Color(0, 0, 0, 0.45)
	draw_rect(Rect2(0, 0, size.x, 80), vig)
	draw_rect(Rect2(0, size.y - 280, size.x, 280), Color(0, 0, 0, 0.25))
	if fade > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, fade))

func _draw_pitch(size: Vector2) -> void:
	var sway := sin(time * 0.15) * 18.0
	draw_rect(Rect2(0, size.y * 0.58, size.x, size.y), Color.html("#1b4a30"))
	draw_line(Vector2(80, size.y * 0.72), Vector2(size.x - 80, size.y * 0.72), Color(1, 1, 1, 0.35), 2.0)
	draw_arc(Vector2(size.x * 0.5 + sway, size.y * 0.78), 70, 0, TAU, 48, Color(1, 1, 1, 0.28), 2.0)
	draw_rect(Rect2(size.x * 0.5 - 90, size.y * 0.58, 180, 46), Color(1, 1, 1, 0.22), false, 2.0)
	var light := Color(1, 0.95, 0.8, 0.08)
	draw_colored_polygon(PackedVector2Array([
		Vector2(120, 40), Vector2(260, 40), Vector2(size.x * 0.42, size.y * 0.62),
	]), light)
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x - 120, 40), Vector2(size.x - 260, 40), Vector2(size.x * 0.58, size.y * 0.62),
	]), light)

func _draw_river(size: Vector2) -> void:
	draw_rect(Rect2(0, size.y * 0.5, size.x, size.y), Color.html("#16384a"))
	for i in 8:
		var y := size.y * 0.56 + i * 22.0
		var shift := sin(time * 0.6 + i) * 24.0
		draw_line(Vector2(40 + shift, y), Vector2(size.x - 40 + shift, y), Color(0.75, 0.86, 0.9, 0.18), 2.0)
	draw_circle(Vector2(size.x * 0.78, size.y * 0.22), 18, Color.html("#e8d7a4"))

func _draw_locker(size: Vector2) -> void:
	draw_rect(Rect2(70, 90, 90, size.y * 0.48), Color.html("#4a3424"))
	draw_rect(Rect2(180, 110, 90, size.y * 0.44), Color.html("#3d2b1e"))
	draw_rect(Rect2(size.x - 280, 100, 160, size.y * 0.42), Color.html("#2e2218"))
	draw_rect(Rect2(120, size.y * 0.62, size.x - 240, 28), Color.html("#6a4a30"))
	draw_circle(Vector2(size.x * 0.7, 120), 36, Color(0.9, 0.72, 0.35, 0.35))

func _draw_sideline(size: Vector2) -> void:
	draw_rect(Rect2(0, size.y * 0.62, size.x, size.y), Color.html("#1d3b28"))
	draw_line(Vector2(0, size.y * 0.66), Vector2(size.x, size.y * 0.66), Color(1, 1, 1, 0.45), 3.0)
	draw_rect(Rect2(size.x * 0.62, 70, 220, 36), Color.html("#c9a227"))
	draw_rect(Rect2(40, 80, size.x * 0.28, size.y * 0.32), Color(0.15, 0.16, 0.18, 0.55))

func _draw_stands(size: Vector2) -> void:
	for i in 6:
		draw_rect(Rect2(80, 90 + i * 36, size.x - 160, 18), Color(0.2, 0.22, 0.26, 0.85))
	draw_rect(Rect2(0, size.y * 0.7, size.x, size.y), Color.html("#1a3a28"))

func _draw_tunnel(size: Vector2) -> void:
	draw_rect(Rect2(size.x * 0.3, 40, size.x * 0.4, size.y * 0.7), Color.html("#100e0c"))
	draw_rect(Rect2(size.x * 0.38, size.y * 0.55, size.x * 0.24, 80), Color(0.85, 0.75, 0.45, 0.15))
	draw_line(Vector2(size.x * 0.36, size.y * 0.4), Vector2(size.x * 0.48, size.y * 0.46), Color.html("#c9a227"), 3.0)

func _draw_factory(size: Vector2) -> void:
	for i in 5:
		draw_line(Vector2(60 + i * 40, 60), Vector2(180 + i * 50, size.y * 0.62), Color(0.45, 0.28, 0.16, 0.7), 4.0)
	draw_rect(Rect2(size.x * 0.55, size.y * 0.42, 220, 160), Color.html("#6a5038"))
	draw_rect(Rect2(size.x * 0.62, size.y * 0.28, 70, 50), Color(0.85, 0.9, 0.95, 0.25))

func _draw_room(size: Vector2) -> void:
	draw_rect(Rect2(0, size.y * 0.72, size.x, size.y), Color.html("#5a4636"))
	draw_rect(Rect2(size.x * 0.35, size.y * 0.48, 280, 18), Color.html("#2a2118"))
	draw_circle(Vector2(size.x * 0.46, size.y * 0.44), 28, Color.html("#d8cbb0"))
	draw_rect(Rect2(80, 70, 160, 220), Color(0.55, 0.32, 0.38, 0.35))

func _draw_dusk(size: Vector2) -> void:
	draw_circle(Vector2(size.x * 0.2, size.y * 0.28), 42, Color.html("#e0a060"))
	draw_rect(Rect2(0, size.y * 0.6, size.x, size.y), Color.html("#1a3218"))
	draw_line(Vector2(0, size.y * 0.6), Vector2(size.x, size.y * 0.6), Color(1, 1, 1, 0.2), 2.0)

func _draw_cover(size: Vector2) -> void:
	draw_rect(Rect2(0, size.y * 0.58, size.x, size.y), Color.html("#173224"))
	draw_line(Vector2(0, size.y * 0.62), Vector2(size.x, size.y * 0.62), Color.html("#c9a227"), 2.0)
	for i in 4:
		var x := size.x * (0.18 + i * 0.2)
		draw_line(Vector2(x, 30), Vector2(x, 90), Color.html("#e8d9a8"), 2.0)
		draw_circle(Vector2(x, 30), 5, Color.html("#e8d9a8"))
	draw_arc(Vector2(size.x * 0.72, size.y * 0.78), 46, 0, TAU, 40, Color(1, 1, 1, 0.2), 2.0)
