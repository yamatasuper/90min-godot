extends Control

const PAPER := Color(0.965, 0.941, 0.894)
const INK := Color(0.102, 0.086, 0.071)
const GOLD := Color(0.788, 0.635, 0.153)
const MUTED := Color(0.42, 0.38, 0.32)
const EMPTY := Color(0.89, 0.86, 0.8)

const CAPTION_H := 124.0
const PAD := 16.0
const _Frame := preload("res://scripts/manga_frame.gd")

const SWEEP := 2.2
const TARGET := 0.62
const HALF := 0.055

const STAR := "res://assets/season/01_star.jpg"
const TV := "res://assets/season/02_tv.jpg"
const WINDOW := "res://assets/season/03_window.jpg"
const SCROLL := "res://assets/season/04_scroll.jpg"
const STADIUM := "res://assets/season/05_stadium.jpg"
const MATCH := "res://assets/season/06_match.jpg"
const GOAL := "res://assets/season/07_goal.jpg"
const MISS := "res://assets/season/08_miss.jpg"
const TEAMMATE := "res://assets/season/09_teammate.jpg"
const SEARCH := "res://assets/season/10_search.jpg"
const DAY2 := "res://assets/season/11_day2.jpg"

const TOP := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.36), Vector2(0, 0.62)]
const BL := [Vector2(0, 0.66), Vector2(0.40, 0.56), Vector2(0.22, 1), Vector2(0, 1)]
const BR := [Vector2(0.46, 0.54), Vector2(1, 0.40), Vector2(1, 1), Vector2(0.28, 1)]
const TOP2 := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.38), Vector2(0.55, 0.50), Vector2(0, 0.42)]
const BL2 := [Vector2(0, 0.46), Vector2(0.48, 0.54), Vector2(0.30, 1), Vector2(0, 1)]
const BR2 := [Vector2(0.58, 0.46), Vector2(1, 0.42), Vector2(1, 1), Vector2(0.38, 1)]
const SU := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.46), Vector2(0, 0.58)]
const SD := [Vector2(0, 0.62), Vector2(1, 0.50), Vector2(1, 1), Vector2(0, 1)]
const FULL := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
const ALL := Rect2(0, 0, 1, 1)

var page_i := 0
var panel_i := 0
var phase := "read"
var turning := false
var shot_hit := false
var pointer := 0.0
var clock := 0.0
var _frames: Array = []
var _cache := {}
var bar: ShotBar
var pages: Array = []

func _ready() -> void:
	UIKit.apply_theme(self)
	pages = _story()
	bar = ShotBar.new()
	bar.paper = PAPER
	bar.ink = INK
	bar.gold = GOLD
	bar.font = UIKit.bold()
	bar.target = TARGET
	bar.half = HALF
	bar.visible = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%Page.add_child(bar)
	_style_chrome()
	%BackButton.pressed.connect(_to_menu)
	%NovelButton.pressed.connect(_replay)
	%MenuButton.pressed.connect(_to_menu)
	%EndTitle.text = "День 2. Процесс пошёл."
	resized.connect(_relayout)
	_relayout()
	call_deferred("_relayout")

func _story() -> Array:
	return [
		_pg("День 1 · Конец сезона", [
			_pn(STAR, "Футболист стоит напротив заполненных трибун и поднимает руки.", TOP),
			_pn(STAR, "Трибуны в ответ тянут руки к нему.", BL, Rect2(0, 0.62, 0.46, 0.38)),
			_pn(TV, "Кадр отдаляется. Это телевизор. Перед ним ты, с чипсами.", BR),
		]),
		_pg("На диване", [
			_pn(TV, "Футбол давно меня не радует. Мало чего радует.", TOP2, Rect2(0, 0.02, 0.62, 0.96), "мысли"),
			_pn(TV, "Может, в какой-то из вселенных я был бы на его месте.", BL2, Rect2(0.5, 0.15, 0.48, 0.7), "мысли"),
			_pn(TV, "Но я на своём месте. А может, и плохо. Я уже ни в чём не уверен.", BR2, Rect2(0, 0.05, 0.55, 0.9), "мысли"),
		]),
		_pg("Вечер", [
			_pn(WINDOW, "Подходишь к окну. За окном — небольшой город.", TOP),
			_pn(SCROLL, "Снова диван. Топ-10 футболистов, которые поздно начали.", BL),
			_pn(SCROLL, "Может, я и не поздно начал. Почему я застрял там, где сейчас.", BR, Rect2(0, 0, 0.72, 0.92), "мысли"),
		]),
		_pg("Следующий день · Утро", [
			_pn(STADIUM, "Утро. Вторая лига — далеко не самый популярный чемпионат.", TOP),
			_pn(STADIUM, "Стадион еле-еле заполнил четверть.", BL, Rect2(0, 0.16, 0.32, 0.34)),
			_pn(MATCH, "Матч. Радует ли тебя всё, что вокруг, — или нет.", BR),
		]),
		_pg("Удар", [
			_pn(MATCH, "Мяч у тебя. Попади в линию.", FULL),
		], true),
		_pg("После матча", [
			_pn(TEAMMATE, "Матч кончился. По дороге домой тебя догоняет сокомандник.", TOP2),
			_pn(TEAMMATE, "Меня, возможно, позовут в высшую. Скоро просмотр.", BL2, Rect2(0, 0.02, 0.52, 0.96), "Сокомандник"),
			_pn(TEAMMATE, "Ты показушно радуешься: «Это твой шанс. Я за тебя.»", BR2, Rect2(0.4, 0, 0.58, 0.98)),
		]),
		_pg("Вечер · Дома", [
			_pn(SEARCH, "Дома листаешь интернет. Высшая лига. Хотя бы просмотр.", TOP),
			_pn(SEARCH, "Ничего.", BL, Rect2(0.35, 0.38, 0.62, 0.6)),
			_pn(SEARCH, "Но подвижки начались. Главное — не растерять до завтра.", BR, Rect2(0.02, 0, 0.55, 0.75), "мысли"),
		]),
		_pg("День 2", [
			_pn(DAY2, "Утро. Процесс пошёл.", FULL),
		]),
	]

func _result_page(hit: bool) -> Dictionary:
	if hit:
		return _pg("Гол", [
			_pn(GOAL, "Гол. Все вокруг радуются.", SU),
			_pn(GOAL, "А смысл радоваться?", SD, Rect2(0.28, 0.02, 0.46, 0.72), "мысли"),
		])
	return _pg("Мимо", [
		_pn(MISS, "Мимо.", SU),
		_pn(MISS, "Безразлично смотришь на пустые трибуны.", SD, Rect2(0.38, 0.05, 0.6, 0.55), "мысли"),
	])

func _pg(kicker: String, panels: Array, shot := false) -> Dictionary:
	return {"kicker": kicker, "panels": panels, "shot": shot}

func _pn(image: String, text: String, poly: Array, crop: Rect2 = ALL, who := "") -> Dictionary:
	return {"image": image, "text": text, "poly": poly, "crop": crop, "who": who}

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
	%Caption.position = Vector2(PAD, PAD + art_h + 10.0)
	%Caption.size = Vector2(inner_w, CAPTION_H)
	bar.position = %Panels.position + Vector2(8, art_h - 96)
	bar.size = Vector2(inner_w - 16, 88)
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
	var tex := _texture(data["image"])
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	var crop: Rect2 = data["crop"]
	var sz := tex.get_size()
	atlas.region = Rect2(crop.position * sz, crop.size * sz)
	frame.art = atlas
	frame.region = atlas.region
	var poly := PackedVector2Array()
	for point in data["poly"]:
		poly.append(Vector2(point) * area)
	frame.poly = poly
	%Panels.add_child(frame)
	return frame

func _refresh() -> void:
	var shooting := bool(pages[page_i].get("shot", false))
	if shooting:
		if phase != "aim":
			clock = 0.0
			pointer = 0.0
			bar.pointer = 0.0
			bar.frozen = false
			bar.hit = false
		phase = "aim"
	elif phase != "result":
		phase = "read"
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
	var speaker := String(panel["who"])
	if speaker == "":
		speaker = pages[page_i]["kicker"]
	%Who.visible = speaker != ""
	%Who.text = speaker
	if phase == "result":
		%Body.text = "Попал. Гол." if shot_hit else "Мимо."
	else:
		%Body.text = panel["text"]
	%PageNo.text = "страница %d / %d" % [page_i + 1, pages.size()]
	%Hint.text = _hint(last)
	%Choices.visible = false
	%EndCard.visible = phase == "end"
	bar.visible = phase == "aim" or phase == "result"
	if bar.visible:
		%Page.move_child(bar, -1)

func _hint(last: int) -> String:
	if phase == "end":
		return ""
	if phase == "aim":
		return "клик или пробел — удар"
	if phase == "result":
		return "клик — следующая страница"
	if panel_i < last:
		return "клик — следующий кадр"
	if page_i < pages.size() - 1:
		return "клик — следующая страница"
	return "клик — конец"

func _texture(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var tex: Texture2D = load(path)
	_cache[path] = tex
	return tex

func _process(delta: float) -> void:
	if phase != "aim":
		return
	clock += delta
	var u := fposmod(clock / (SWEEP * 2.0), 1.0)
	pointer = 1.0 - absf(u * 2.0 - 1.0)
	bar.pointer = pointer
	bar.queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if phase == "aim":
			_fire()
		elif phase != "end":
			_forward()
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		_to_menu()
		get_viewport().set_input_as_handled()
		return
	if phase == "end":
		return
	if phase == "aim":
		if event.is_action_pressed("ui_accept"):
			_fire()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left"):
			_back()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_left"):
		_back()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept"):
		_forward()
		get_viewport().set_input_as_handled()

func _fire() -> void:
	if phase != "aim":
		return
	shot_hit = absf(pointer - TARGET) <= HALF
	pages.insert(page_i + 1, _result_page(shot_hit))
	pages[page_i]["shot"] = false
	pages[page_i]["panels"][panel_i]["text"] = "Попал. Гол." if shot_hit else "Мимо."
	phase = "result"
	bar.frozen = true
	bar.hit = shot_hit
	bar.queue_redraw()
	%Body.text = pages[page_i]["panels"][panel_i]["text"]
	%PageNo.text = "страница %d / %d" % [page_i + 1, pages.size()]
	%Hint.text = "клик — следующая страница"

func _forward() -> void:
	if turning or phase == "aim" or phase == "end":
		return
	var last: int = pages[page_i]["panels"].size() - 1
	if phase != "result" and panel_i < last:
		panel_i += 1
		_refresh()
		return
	if page_i < pages.size() - 1:
		_turn(1)
		return
	phase = "end"
	bar.visible = false
	%EndBody.text = "Удар: %s. Дальше — чужая радость или пустые трибуны. День 2 только начался." % ("гол" if shot_hit else "мимо")
	%EndCard.visible = true
	%Hint.text = ""

func _back() -> void:
	if turning or phase == "end":
		return
	if phase == "aim" or phase == "result":
		phase = "read"
		bar.visible = false
	if panel_i > 0 and phase == "read":
		panel_i -= 1
		_refresh()
		return
	if page_i > 0:
		_turn(-1)

func _turn(dir: int) -> void:
	turning = true
	bar.visible = false
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

func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _replay() -> void:
	get_tree().reload_current_scene()

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

class ShotBar extends Control:
	var pointer := 0.0
	var target := 0.62
	var half := 0.055
	var frozen := false
	var hit := false
	var paper := Color.WHITE
	var ink := Color.BLACK
	var gold := Color.WHITE
	var font: Font

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(paper, 0.94))
		draw_rect(Rect2(Vector2.ZERO, size), ink, false, 3.0)
		var track := Rect2(Vector2(14, 40), Vector2(size.x - 28, 20))
		draw_rect(track, Color(0.93, 0.9, 0.84))
		draw_rect(track, ink, false, 3.0)
		var zone := Rect2(
			track.position.x + track.size.x * (target - half),
			track.position.y - 7.0,
			track.size.x * half * 2.0,
			track.size.y + 14.0
		)
		draw_rect(zone, gold)
		var px := track.position.x + track.size.x * pointer
		var marker := ink if not frozen or hit else Color(0.45, 0.16, 0.12)
		var tip := Vector2(px, track.position.y - 2.0)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-7, -12), tip + Vector2(7, -12)]), marker)
		draw_line(Vector2(px, track.position.y), Vector2(px, track.position.y + track.size.y), marker, 4.0)
		if font == null:
			return
		var word := "Попади в линию"
		if frozen:
			word = "Гол" if hit else "Мимо"
		draw_string(font, Vector2(14, 24), word, HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 18, ink)
