extends Control

const PAPER := Color(0.965, 0.941, 0.894)
const INK := Color(0.102, 0.086, 0.071)
const GOLD := Color(0.788, 0.635, 0.153)
const MUTED := Color(0.42, 0.38, 0.32)
const EMPTY := Color(0.89, 0.86, 0.8)

const CAPTION_H := 124.0
const PAD := 16.0
const _Frame := preload("res://scripts/manga_frame.gd")
const _Bubble := preload("res://scripts/manga_bubble.gd")

var page_i := 0
var panel_i := 0
var phase := "read"
var choice_line := ""
var turning := false
var _frames: Array = []
var _bubbles: Control

func _pages() -> Array:
	return [
		{
			"panels": [
				{
					"image": "res://assets/bg_cover.png",
					"region": Rect2(0, 40, 1536, 940),
					"poly": [Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.36), Vector2(0, 0.62)],
					"text": "Прибрежье. Стадион «Торпедо». Западная трибуна закрыта три года.",
				},
				{
					"image": "res://assets/bg_cover.png",
					"region": Rect2(1040, 0, 480, 720),
					"poly": [Vector2(0, 0.66), Vector2(0.40, 0.56), Vector2(0.22, 1), Vector2(0, 1)],
					"text": "Ты — Алексей Бардин. Тридцать четыре. Контракт кончается через месяц.",
				},
				{
					"image": "res://assets/bg_west.png",
					"region": Rect2(20, 40, 1100, 960),
					"poly": [Vector2(0.46, 0.54), Vector2(1, 0.40), Vector2(1, 1), Vector2(0.28, 1)],
					"text": "Всё, что у тебя есть — раздевалка, бутсы и запах травы.",
				},
			],
		},
		{
			"panels": [
				{
					"image": "res://assets/bg_locker.png",
					"region": Rect2(80, 80, 1380, 860),
					"poly": [Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.38), Vector2(0.55, 0.50), Vector2(0, 0.42)],
					"text": "Деревянная скамья. Бинты. Запах разогревающей мази.",
				},
				{
					"image": "res://assets/portrait_bardin.png",
					"region": Rect2(160, 40, 720, 860),
					"poly": [Vector2(0, 0.46), Vector2(0.48, 0.54), Vector2(0.30, 1), Vector2(0, 1)],
					"text": "Старые. Потёртые. Как и ты.",
				},
				{
					"image": "res://assets/portrait_coach.png",
					"region": Rect2(140, 20, 760, 900),
					"poly": [Vector2(0.58, 0.46), Vector2(1, 0.42), Vector2(1, 1), Vector2(0.38, 1)],
					"who": "Виктор Семёнович",
					"text": "Бардин, ты — капитан. Сделай что-нибудь.",
				},
			],
			"choice": {
				"prompt": "Бутсы. Два года назад ещё казались дорогими.",
				"options": [
				{
					"label": "Затянуть шнурки.",
					"text": "Кожа скрипит. Узел держит. Ты делаешь вид, что этого достаточно.",
					"oval": Rect2(0.02, 0.16, 0.40, 0.16),
					"tail": Vector2(0.16, 0.62),
				},
				{
					"label": "Ослабить. Дать стопе воздух.",
					"text": "Пальцы гудят. Ты ещё не на поле, а уже торгуешься с болью.",
					"oval": Rect2(0.46, 0.02, 0.52, 0.20),
					"tail": Vector2(0.26, 0.66),
				},
				],
			},
		},
		{
			"panels": [
				{
					"image": "res://assets/bg_whistle.png",
					"region": Rect2(980, 0, 540, 1024),
					"poly": [Vector2(0, 0), Vector2(0.48, 0), Vector2(0.34, 1), Vector2(0, 1)],
					"text_from_choice": true,
					"text": "Кожа скрипит. Узел держит. Ты делаешь вид, что этого достаточно.",
				},
				{
					"image": "res://assets/bg_street.png",
					"region": Rect2(700, 0, 800, 900),
					"poly": [Vector2(0.52, 0), Vector2(1, 0), Vector2(1, 0.40), Vector2(0.46, 0.50)],
					"text": "Бровка. Ветер с реки. Западная трибуна — леса, не катастрофа.",
				},
				{
					"image": "res://assets/match_1.png",
					"region": Rect2(280, 40, 980, 960),
					"poly": [Vector2(0.44, 0.58), Vector2(1, 0.46), Vector2(1, 1), Vector2(0.40, 1)],
					"text": "Это не симулятор. Это девяносто минут, в которых заканчивается всё, чем ты был.",
				},
			],
		},
	]

var pages: Array = _pages()

func _ready() -> void:
	UIKit.apply_theme(self)
	_bubbles = Control.new()
	_bubbles.name = "Bubbles"
	_bubbles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%Page.add_child(_bubbles)
	_style_chrome()
	%BackButton.pressed.connect(_to_menu)
	%NovelButton.pressed.connect(_to_novel)
	%MenuButton.pressed.connect(_to_menu)
	resized.connect(_relayout)
	_relayout()
	call_deferred("_relayout")

func _relayout() -> void:
	var vp := size
	if vp.x < 200.0 or vp.y < 200.0:
		return
	var sheet_h := vp.y - 36.0
	var sheet_w := minf(580.0, sheet_h * 0.84)
	%Page.position = Vector2((vp.x - sheet_w) * 0.5, 18.0)
	%Page.size = Vector2(sheet_w, sheet_h)
	var inner_w := sheet_w - PAD * 2.0
	var art_h := sheet_h - PAD * 2.0 - CAPTION_H - 10.0
	%Panels.position = Vector2(PAD, PAD)
	%Panels.size = Vector2(inner_w, art_h)
	_bubbles.position = %Panels.position
	_bubbles.size = %Panels.size
	%Caption.position = Vector2(PAD, PAD + art_h + 10.0)
	%Caption.size = Vector2(inner_w, CAPTION_H)
	_build()

func _build() -> void:
	_frames.clear()
	for child in %Panels.get_children():
		%Panels.remove_child(child)
		child.free()
	var panels: Array = pages[page_i]["panels"]
	for i in panels.size():
		_frames.append(_make_frame(panels[i], i))
	_refresh()

func _make_frame(data: Dictionary, index: int):
	var area: Vector2 = %Panels.size
	var frame = _Frame.new()
	frame.position = Vector2.ZERO
	frame.size = area
	frame.index = index
	frame.paper = PAPER
	frame.ink = INK
	frame.gold = GOLD
	frame.empty = EMPTY
	var atlas := AtlasTexture.new()
	atlas.atlas = load(data["image"])
	atlas.region = data["region"]
	frame.art = atlas
	frame.region = data["region"]
	var poly := PackedVector2Array()
	for point in data["poly"]:
		poly.append(Vector2(point) * area)
	frame.poly = poly
	%Panels.add_child(frame)
	return frame

func _refresh() -> void:
	var panels: Array = pages[page_i]["panels"]
	var last := panels.size() - 1
	for i in _frames.size():
		var frame = _frames[i]
		var shown := i <= panel_i
		var active := i == panel_i and phase != "end"
		frame.set_state(shown, active)
		if active:
			frame.move_to_front()
	var panel: Dictionary = panels[panel_i]
	var who := ""
	var body := ""
	if phase == "choice":
		body = pages[page_i]["choice"]["prompt"]
	else:
		who = panel.get("who", "")
		body = _panel_text(panel)
	%Who.visible = who != ""
	%Who.text = who
	%Body.text = body
	%PageNo.text = "страница %d / %d" % [page_i + 1, pages.size()]
	%Hint.text = _hint(last)
	_show_bubbles()
	%Choices.visible = false
	%EndCard.visible = phase == "end"

func _panel_text(panel: Dictionary) -> String:
	if panel.get("text_from_choice", false) and choice_line != "":
		return choice_line
	return panel["text"]

func _hint(last: int) -> String:
	if phase == "end":
		return ""
	if phase == "choice":
		return "выбери облачко"
	if panel_i < last:
		return "клик — следующий кадр"
	if pages[page_i].has("choice"):
		return "клик — выбор"
	if page_i < pages.size() - 1:
		return "клик — следующая страница"
	return "клик — конец наброска"

func _show_bubbles() -> void:
	for child in _bubbles.get_children():
		_bubbles.remove_child(child)
		child.free()
	if phase != "choice":
		return
	var area: Vector2 = _bubbles.size
	var options: Array = pages[page_i]["choice"]["options"]
	for i in options.size():
		var option: Dictionary = options[i]
		var oval: Rect2 = option["oval"]
		var bubble = _Bubble.new()
		bubble.ink = INK
		bubble.gold = GOLD
		bubble.setup(
			option["label"],
			Rect2(oval.position * area, oval.size * area),
			Vector2(option["tail"]) * area
		)
		bubble.picked.connect(_pick.bind(i))
		_bubbles.add_child(bubble)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_forward()
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		_to_menu()
		get_viewport().set_input_as_handled()
		return
	if phase == "choice" and event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			_pick(0)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_2:
			_pick(1)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_left"):
		_back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept"):
		_forward()
		get_viewport().set_input_as_handled()

func _forward() -> void:
	if turning or phase == "end" or phase == "choice":
		return
	var last: int = pages[page_i]["panels"].size() - 1
	if panel_i < last:
		panel_i += 1
		_refresh()
		return
	if pages[page_i].has("choice") and phase == "read":
		phase = "choice"
		_refresh()
		return
	if page_i < pages.size() - 1:
		_turn(1)
		return
	phase = "end"
	_refresh()

func _back() -> void:
	if turning:
		return
	if phase == "end" or phase == "choice":
		phase = "read"
		_refresh()
		return
	if panel_i > 0:
		panel_i -= 1
		_refresh()
		return
	if page_i > 0:
		_turn(-1)

func _turn(dir: int) -> void:
	turning = true
	var tw := create_tween()
	tw.tween_property(%Page, "modulate:a", 0.0, 0.08)
	tw.tween_callback(func() -> void:
		page_i += dir
		panel_i = 0 if dir > 0 else pages[page_i]["panels"].size() - 1
		phase = "read"
		_build()
	)
	tw.tween_property(%Page, "modulate:a", 1.0, 0.14)
	tw.finished.connect(func() -> void:
		turning = false
	)

func _pick(index: int) -> void:
	if turning or phase != "choice":
		return
	var options: Array = pages[page_i]["choice"]["options"]
	choice_line = options[index]["text"]
	phase = "read"
	_turn(1)

func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _to_novel() -> void:
	GameState.mode = "new"
	get_tree().change_scene_to_file("res://scenes/manga_game.tscn")

func _style_chrome() -> void:
	var sheet := StyleBoxFlat.new()
	sheet.bg_color = PAPER
	sheet.border_color = INK
	sheet.set_border_width_all(4)
	sheet.shadow_color = Color(0, 0, 0, 0.45)
	sheet.shadow_size = 18
	sheet.shadow_offset = Vector2(0, 8)
	%Page.add_theme_stylebox_override("panel", sheet)

	var cap := StyleBoxFlat.new()
	cap.bg_color = Color(0, 0, 0, 0)
	cap.border_color = INK
	cap.border_width_top = 2
	cap.content_margin_top = 8
	%Caption.add_theme_stylebox_override("panel", cap)

	%Who.add_theme_font_override("font", UIKit.bold())
	%Who.add_theme_font_size_override("font_size", 15)
	%Who.add_theme_color_override("font_color", GOLD)
	%Body.add_theme_font_override("font", UIKit.serif())
	%Body.add_theme_font_size_override("font_size", 18)
	%Body.add_theme_color_override("font_color", INK)
	%Hint.add_theme_font_size_override("font_size", 13)
	%Hint.add_theme_color_override("font_color", MUTED)
	%PageNo.add_theme_font_size_override("font_size", 13)
	%PageNo.add_theme_color_override("font_color", MUTED)

	_style_text_button(%BackButton)
	for button in [%NovelButton, %MenuButton]:
		_style_paper_button(button)
	%EndTitle.add_theme_font_override("font", UIKit.bold())
	%EndTitle.add_theme_font_size_override("font_size", 28)
	%EndTitle.add_theme_color_override("font_color", INK)
	%EndBody.add_theme_font_size_override("font_size", 18)
	%EndBody.add_theme_color_override("font_color", INK)

func _style_text_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_font_override("font", UIKit.serif())
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
	button.add_theme_color_override("font_hover_color", GOLD)

func _style_paper_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = PAPER
	normal.border_color = INK
	normal.set_border_width_all(3)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	var hover := normal.duplicate()
	hover.border_color = GOLD
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_font_override("font", UIKit.serif())
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
