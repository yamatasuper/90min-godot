extends Control

const PAPER := Color(0.965, 0.941, 0.894)
const INK := Color(0.102, 0.086, 0.071)
const GOLD := Color(0.788, 0.635, 0.153)
const MUTED := Color(0.42, 0.38, 0.32)
const EMPTY := Color(0.89, 0.86, 0.8)
const CAPTION_H := 118.0
const PAD := 16.0
const _Frame := preload("res://scripts/manga_frame.gd")
const _Bubble := preload("res://scripts/manga_bubble.gd")

const LAYOUTS := [
	[
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.36), Vector2(0, 0.62)],
		[Vector2(0, 0.66), Vector2(0.40, 0.56), Vector2(0.22, 1), Vector2(0, 1)],
		[Vector2(0.46, 0.54), Vector2(1, 0.40), Vector2(1, 1), Vector2(0.28, 1)],
	],
	[
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.38), Vector2(0.55, 0.50), Vector2(0, 0.42)],
		[Vector2(0, 0.46), Vector2(0.48, 0.54), Vector2(0.30, 1), Vector2(0, 1)],
		[Vector2(0.58, 0.46), Vector2(1, 0.42), Vector2(1, 1), Vector2(0.38, 1)],
	],
	[
		[Vector2(0, 0), Vector2(0.48, 0), Vector2(0.34, 1), Vector2(0, 1)],
		[Vector2(0.52, 0), Vector2(1, 0), Vector2(1, 0.40), Vector2(0.46, 0.50)],
		[Vector2(0.44, 0.58), Vector2(1, 0.46), Vector2(1, 1), Vector2(0.40, 1)],
	],
]

var CAST := {
	"coach": "Виктор Семёнович",
	"glock": "Глок",
	"sokol": "Сокол",
	"pen": "Пень",
	"bardin": "Бардин",
	"father": "Отец",
	"wife": "Она",
	"boy": "Мальчик",
	"doctor": "Врач",
	"crowd": "Трибуна",
}

const BG := {
	"cover": preload("res://assets/bg_cover.png"),
	"locker": preload("res://assets/bg_locker.png"),
	"street": preload("res://assets/bg_street.png"),
	"west": preload("res://assets/bg_west.png"),
	"pitch": preload("res://assets/bg_pitch.png"),
	"match1": preload("res://assets/match_1.png"),
	"match2": preload("res://assets/match_2.png"),
	"match3": preload("res://assets/match_3.png"),
	"match4": preload("res://assets/match_4.png"),
	"match_action": preload("res://assets/match_action.png"),
	"match_mid": preload("res://assets/match_mid.png"),
	"match_goal": preload("res://assets/match_goal.png"),
	"river": preload("res://assets/bg_river.png"),
	"tunnel": preload("res://assets/bg_tunnel.png"),
	"factory": preload("res://assets/bg_factory.png"),
	"apartment": preload("res://assets/bg_apartment.png"),
	"epilogue": preload("res://assets/bg_epilogue.png"),
	"whistle": preload("res://assets/bg_whistle.png"),
}

const FACES := {
	"bardin": preload("res://assets/portrait_bardin.png"),
	"coach": preload("res://assets/portrait_coach.png"),
	"glock": preload("res://assets/portrait_glock.png"),
	"sokol": preload("res://assets/portrait_sokol.png"),
	"pen": preload("res://assets/portrait_pen.png"),
	"wife": preload("res://assets/portrait_wife.png"),
}

const PLACES := {
	"cover": "Прибрежье",
	"locker": "Раздевалка",
	"street": "Бровка",
	"west": "Западная трибуна",
	"pitch": "Поле",
	"match1": "Поле",
	"match2": "Поле",
	"match3": "Поле",
	"match4": "Поле",
	"match_action": "Поле",
	"match_mid": "Поле",
	"match_goal": "Поле",
	"river": "Река",
	"tunnel": "Тоннель",
	"factory": "Цех",
	"apartment": "Квартира",
	"epilogue": "После",
	"whistle": "После свистка",
}

const BG_CROPS := [
	Rect2(0, 40, 1536, 900),
	Rect2(0, 0, 920, 1024),
	Rect2(600, 0, 936, 1024),
]
const FACE_CROP := Rect2(80, 30, 860, 1180)

var runner: StoryRunner
var _bubbles: Control
var _frames: Array = []
var panels: Array = []
var page_no := 1
var page_bg := ""
var phase := "say"
var turning := false
var choice_step: Dictionary = {}
var queued: Dictionary = {}

func _ready() -> void:
	UIKit.apply_theme(self)
	_bubbles = Control.new()
	_bubbles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%Page.add_child(_bubbles)
	%Page.move_child(_bubbles, %Caption.get_index())
	_style_chrome()
	%BackButton.pressed.connect(_ask_menu)
	%YesButton.pressed.connect(_to_menu)
	%NoButton.pressed.connect(_close_overlays)
	%EndMenu.pressed.connect(_to_menu)
	%Journal.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			%Journal.visible = false
	)
	resized.connect(_relayout)
	call_deferred("_boot")

func _boot() -> void:
	_relayout()
	runner = StoryRunner.new()
	runner.setup(StoryData.labels(), GameState)
	runner.waiting_say.connect(_on_say)
	runner.waiting_choice.connect(_on_choice)
	runner.finished.connect(_on_finished)
	if GameState.mode == "continue":
		var spot := GameState.load_save()
		if spot.is_empty():
			GameState.reset()
			runner.start("intro")
		else:
			runner.resume(String(spot.get("label", "intro")), int(spot.get("index", 0)))
	else:
		GameState.reset()
		runner.start("intro")

func _relayout() -> void:
	var vp := size
	if vp.x < 200.0 or vp.y < 200.0:
		return
	var sheet_h := vp.y - 36.0
	var sheet_w := minf(620.0, sheet_h * 0.86)
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
	_rebuild()

func _layout() -> Array:
	return LAYOUTS[(page_no - 1) % LAYOUTS.size()]

func _rebuild() -> void:
	_frames.clear()
	for child in %Panels.get_children():
		%Panels.remove_child(child)
		child.free()
	var area: Vector2 = %Panels.size
	if area.x < 10.0:
		return
	var slots: Array = _layout()
	for i in slots.size():
		var frame = _Frame.new()
		frame.size = area
		frame.index = i
		frame.paper = PAPER
		frame.ink = INK
		frame.gold = GOLD
		frame.empty = EMPTY
		var poly := PackedVector2Array()
		for point in slots[i]:
			poly.append(Vector2(point) * area)
		frame.poly = poly
		if i < panels.size():
			var panel: Dictionary = panels[i]
			frame.art = panel.get("art")
			frame.region = panel.get("region", Rect2())
		%Panels.add_child(frame)
		_frames.append(frame)
	_refresh()

func _refresh() -> void:
	for i in _frames.size():
		var shown := i < panels.size()
		var active := shown and i == panels.size() - 1 and phase != "end"
		_frames[i].set_state(shown, active)
		if active:
			_frames[i].move_to_front()
	var who := ""
	var body := ""
	if not panels.is_empty() and phase != "choice":
		var panel: Dictionary = panels.back()
		who = String(panel.get("name", ""))
		body = String(panel.get("text", ""))
		if panel.get("bubble", false):
			body = ""
	%Who.visible = who != ""
	%Who.text = who
	%Body.text = body
	%PageNo.text = String(PLACES.get(page_bg, ""))
	if GameState.show_hud:
		%Hud.text = "%s    %d'" % [GameState.score_line(), GameState.minute]
	else:
		%Hud.text = "стр. %d" % page_no
	%Hint.text = "выбери облачко" if phase == "choice" else "клик — следующий кадр    Tab — состояние"
	_clear_bubbles()
	if phase == "choice":
		_spawn_choice_bubbles()
	elif phase == "say" and not panels.is_empty() and panels.back().get("bubble", false):
		_spawn_line_bubble(panels.back())
	%EndCard.visible = phase == "end"

func _clear_bubbles() -> void:
	for child in _bubbles.get_children():
		_bubbles.remove_child(child)
		child.free()

func _spawn_line_bubble(panel: Dictionary) -> void:
	var area := _bubbles.size
	var slot := int(panel.get("slot", 0))
	var spots: Array = _layout()
	var centroid := Vector2.ZERO
	for point in spots[slot]:
		centroid += Vector2(point)
	centroid /= float(spots[slot].size())
	var oval_size := Vector2(0.62, 0.18)
	var origin := Vector2(
		clampf(centroid.x - oval_size.x * 0.5, 0.03, 0.97 - oval_size.x),
		clampf(centroid.y - 0.24, 0.02, 0.70)
	)
	var bubble = _Bubble.new()
	bubble.ink = INK
	bubble.gold = GOLD
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.setup(String(panel.get("text", "")), Rect2(origin * area, oval_size * area), centroid * area)
	_bubbles.add_child(bubble)

func _spawn_choice_bubbles() -> void:
	var options := _visible_options()
	var n := options.size()
	if n == 0:
		return
	var area := _bubbles.size
	var cols := 2 if n > 1 else 1
	var rows := int(ceil(float(n) / float(cols)))
	var gap_x := 0.04
	var gap_y := 0.035
	var w := (1.0 - gap_x * float(cols + 1)) / float(cols)
	var h := minf(0.22, (0.92 - gap_y * float(rows + 1)) / float(rows))
	for i in n:
		var col := i % cols
		var row := int(i / cols)
		var origin := Vector2(gap_x + col * (w + gap_x), 0.03 + row * (h + gap_y))
		var tail := Vector2(origin.x + w * 0.35, minf(origin.y + h + 0.1, 0.98))
		var bubble = _Bubble.new()
		bubble.ink = INK
		bubble.gold = GOLD
		bubble.setup(String(options[i].get("text", "")), Rect2(origin * area, Vector2(w, h) * area), tail * area)
		bubble.picked.connect(_pick.bind(i))
		_bubbles.add_child(bubble)

func _visible_options() -> Array:
	var shown: Array = []
	for opt in choice_step.get("options", []):
		if opt.has("show_if") and not GameState.eval(opt.show_if):
			continue
		shown.append(opt)
	return shown

func _on_say(step: Dictionary) -> void:
	var panel := _make_panel(step)
	_save()
	if _should_break(String(panel.get("bg", ""))):
		queued = panel
		_turn_page()
		return
	if panels.is_empty():
		page_bg = String(panel.get("bg", ""))
	panels.append(panel)
	phase = "say"
	_rebuild()

func _should_break(bg_id: String) -> bool:
	if panels.is_empty():
		return false
	if panels.size() >= 3:
		return true
	return bg_id != page_bg and page_bg != ""

func _make_panel(step: Dictionary) -> Dictionary:
	var who := String(step.get("who", ""))
	var text := String(step.get("text", ""))
	var bg_id := GameState.bg_id
	var art: Texture2D = null
	var region := Rect2()
	var slot := panels.size()
	if who != "" and FACES.has(who):
		art = FACES[who]
		region = _fit(FACE_CROP, art)
	elif BG.has(bg_id):
		art = BG[bg_id]
		region = _fit(BG_CROPS[slot % BG_CROPS.size()], art)
	var bubble := who != "" and text.length() <= 110
	return {
		"bg": bg_id,
		"art": art,
		"region": region,
		"who": who,
		"name": String(CAST.get(who, "")),
		"text": text,
		"bubble": bubble,
		"slot": mini(slot, 2),
	}

func _fit(region: Rect2, tex: Texture2D) -> Rect2:
	var limit := tex.get_size()
	var pos := Vector2(minf(region.position.x, limit.x - 8.0), minf(region.position.y, limit.y - 8.0))
	var size := Vector2(
		minf(region.size.x, limit.x - pos.x),
		minf(region.size.y, limit.y - pos.y)
	)
	return Rect2(pos, size)

func _on_choice(step: Dictionary) -> void:
	choice_step = step
	phase = "choice"
	_save()
	_refresh()

func _pick(index: int) -> void:
	if phase != "choice" or turning:
		return
	var options := _visible_options()
	if index < 0 or index >= options.size():
		return
	var words := String(options[index].get("text", ""))
	_remember("", "— " + words)
	var dest := String(options[index].get("goto", ""))
	phase = "say"
	choice_step = {}
	_clear_bubbles()
	runner.choose(dest)

func _turn_page() -> void:
	turning = true
	var tw := create_tween()
	tw.tween_property(%Page, "modulate:a", 0.0, 0.08)
	tw.tween_callback(func() -> void:
		page_no += 1
		panels.clear()
		if not queued.is_empty():
			page_bg = String(queued.get("bg", ""))
			queued["slot"] = 0
			panels.append(queued)
			queued = {}
		phase = "say"
		_rebuild()
	)
	tw.tween_property(%Page, "modulate:a", 1.0, 0.14)
	tw.finished.connect(func() -> void:
		turning = false
	)

func _gui_input(event: InputEvent) -> void:
	if %Journal.visible or %Confirm.visible or %EndCard.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_forward()
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		if %Journal.visible or %Confirm.visible:
			_close_overlays()
		else:
			_ask_menu()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		_toggle_journal()
		get_viewport().set_input_as_handled()
		return
	if phase == "choice" and event is InputEventKey and event.pressed:
		var number: int = int(event.keycode) - int(KEY_1)
		if number >= 0 and number < _visible_options().size():
			_pick(number)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_right"):
		_forward()
		get_viewport().set_input_as_handled()

func _forward() -> void:
	if turning or phase == "choice" or phase == "end":
		return
	if %Journal.visible or %Confirm.visible:
		return
	if not panels.is_empty():
		var last: Dictionary = panels.back()
		_remember(String(last.get("who", "")), String(last.get("text", "")))
	runner.advance()

func _remember(who: String, text: String) -> void:
	if text == "":
		return
	if not GameState.log.is_empty():
		var last = GameState.log.back()
		if String(last.get("who", "")) == who and String(last.get("text", "")) == text:
			return
	GameState.log.append({"who": who, "text": text})
	if GameState.log.size() > 120:
		GameState.log = GameState.log.slice(-120)

func _save() -> void:
	if runner == null:
		return
	GameState.write_save(runner.label_id, runner.index)

func _on_finished() -> void:
	_save()
	phase = "end"
	%EndCard.visible = true

func _toggle_journal() -> void:
	if %Confirm.visible:
		return
	%Journal.visible = not %Journal.visible
	if %Journal.visible:
		_fill_journal()

func _fill_journal() -> void:
	for child in %Rows.get_children():
		%Rows.remove_child(child)
		child.free()
	%Rows.add_child(UIKit.label(GameState.score_line() + "    %d'" % GameState.minute, 18, MUTED))
	for row in GameState.STAT_LABELS:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		var title := UIKit.label(String(row[1]), 18, INK)
		title.custom_minimum_size = Vector2(150, 0)
		line.add_child(title)
		var bar := ProgressBar.new()
		bar.max_value = int(row[2])
		bar.value = GameState.stat_value(String(row[0]))
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(220, 14)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var fill := StyleBoxFlat.new()
		fill.bg_color = GOLD
		var back := StyleBoxFlat.new()
		back.bg_color = Color(0.75, 0.7, 0.6)
		bar.add_theme_stylebox_override("fill", fill)
		bar.add_theme_stylebox_override("background", back)
		line.add_child(bar)
		line.add_child(UIKit.label(GameState.level_word(int(bar.value), int(row[2])), 16, MUTED))
		%Rows.add_child(line)

func _ask_menu() -> void:
	%Journal.visible = false
	%Confirm.visible = true

func _close_overlays() -> void:
	%Journal.visible = false
	%Confirm.visible = false

func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _style_chrome() -> void:
	var sheet := StyleBoxFlat.new()
	sheet.bg_color = PAPER
	sheet.border_color = INK
	sheet.set_border_width_all(4)
	sheet.shadow_color = Color(0, 0, 0, 0.45)
	sheet.shadow_size = 18
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
	%Hud.add_theme_font_size_override("font_size", 13)
	%Hud.add_theme_color_override("font_color", MUTED)
	for button in [%BackButton]:
		_style_text_button(button)
	for button in [%YesButton, %NoButton, %EndMenu]:
		_style_paper_button(button)
	%EndTitle.add_theme_font_override("font", UIKit.bold())
	%EndTitle.add_theme_font_size_override("font_size", 28)
	%EndTitle.add_theme_color_override("font_color", INK)
	%ConfirmText.add_theme_font_size_override("font_size", 20)
	%ConfirmText.add_theme_color_override("font_color", INK)
	%JournalTitle.add_theme_font_override("font", UIKit.bold())
	%JournalTitle.add_theme_font_size_override("font_size", 26)
	%JournalTitle.add_theme_color_override("font_color", INK)

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
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
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
