extends Control

var CAST := {
	"coach": ["Виктор Семёнович", Color.html("#e4c56a")],
	"glock": ["Глок", Color.html("#c4b896")],
	"sokol": ["Сокол", Color.html("#f0d36a")],
	"pen": ["Пень", Color.html("#9bb0c4")],
	"bardin": ["Бардин", Color.html("#d8cbb0")],
	"father": ["Отец", Color.html("#b9a58a")],
	"wife": ["Она", Color.html("#e2c15a")],
	"boy": ["Мальчик", Color.html("#cfc3a6")],
	"doctor": ["Врач", Color.html("#a9b8c4")],
	"crowd": ["Трибуна", Color.html("#c07060")],
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

const CAPTIONS := {
	"cover": "ПРИБРЕЖЬЕ",
	"locker": "РАЗДЕВАЛКА",
	"street": "БРОВКА",
	"west": "ЗАПАДНАЯ ТРИБУНА",
	"pitch": "ПОЛЕ",
	"match1": "ПОЛЕ",
	"match2": "ПОЛЕ",
	"match3": "ПОЛЕ",
	"match4": "ПОЛЕ",
	"match_action": "ПОЛЕ",
	"match_mid": "ПОЛЕ",
	"match_goal": "ПОЛЕ",
	"river": "РЕКА",
	"tunnel": "ТОННЕЛЬ",
	"factory": "ЦЕХ · 2002",
	"apartment": "КВАРТИРА",
	"epilogue": "ПОСЛЕ",
	"whistle": "ПОСЛЕДНИЕ МИНУТЫ",
}

var runner: StoryRunner
@onready var background: TextureRect = %Background
@onready var fade: ColorRect = %Fade
@onready var portrait_slot: Control = %PortraitSlot
@onready var portrait_view: TextureRect = %Portrait
@onready var portrait_name: Label = %PortraitName
@onready var hud_box: HBoxContainer = %HudBox
@onready var hud_score: Label = %ScoreLabel
@onready var hud_minute: Label = %MinuteLabel
@onready var place_label: Label = %PlaceLabel
@onready var dialogue: PanelContainer = %Dialogue
@onready var name_badge: Label = %NameBadge
@onready var body: Label = %Body
@onready var hint: Label = %Hint
@onready var choices: VBoxContainer = %Choices
@onready var journal: ColorRect = %Journal
@onready var rows: VBoxContainer = %Rows
@onready var history: ColorRect = %History
@onready var history_text: RichTextLabel = %HistoryText
@onready var confirm: ColorRect = %Confirm
var choice_buttons: Array = []
var selected := 0
var full_text := ""
var speaker := ""
var revealing := false
var reveal_pos := 0.0
var waiting := ""
var clock := 0.0

func _ready() -> void:
	UIKit.apply_theme(self)
	_style_scene()
	_connect_ui()
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

func _process(delta: float) -> void:
	clock += delta
	if revealing:
		reveal_pos += delta * 78.0
		var count := mini(int(reveal_pos), full_text.length())
		body.text = full_text.substr(0, count)
		if count >= full_text.length():
			revealing = false
			hint.visible = true
	elif waiting == "say":
		hint.modulate.a = 0.45 + 0.55 * absf(sin(clock * 3.0))

func _unhandled_input(event: InputEvent) -> void:
	if journal.visible or history.visible or confirm.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_overlays()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_open_journal()
		get_viewport().set_input_as_handled()
		return
	if waiting == "choice":
		if event.is_action_pressed("ui_down"):
			_move_choice(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			_move_choice(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			_activate_choice()
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and not event.echo:
			var number: int = int(event.keycode) - int(KEY_1)
			if number >= 0 and number < choice_buttons.size():
				selected = number
				_activate_choice()
				get_viewport().set_input_as_handled()
		return
	if waiting == "say" and (event.is_action_pressed("ui_accept") or _click(event)):
		_advance_say()
		get_viewport().set_input_as_handled()

func _click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT

func _style_scene() -> void:
	fade.modulate.a = 0.0
	for node in [hud_score, hud_minute, name_badge, portrait_name]:
		node.add_theme_font_override("font", UIKit.bold())
	hud_score.add_theme_font_size_override("font_size", 26)
	hud_score.add_theme_color_override("font_color", Color.html("#e8d9a8"))
	hud_minute.add_theme_font_size_override("font_size", 26)
	hud_minute.add_theme_color_override("font_color", Color.html("#c9a227"))
	place_label.add_theme_font_size_override("font_size", 16)
	place_label.add_theme_color_override("font_color", Color.html("#cbbfa6"))
	body.add_theme_font_size_override("font_size", 26)
	body.add_theme_color_override("font_color", Color.html("#e8dcc4"))
	body.add_theme_constant_override("line_spacing", 6)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color.html("#8a8070"))
	portrait_name.add_theme_font_size_override("font_size", 22)
	portrait_name.add_theme_color_override("font_color", Color.html("#e8d9a8"))
	history_text.add_theme_font_override("normal_font", UIKit.serif())
	history_text.add_theme_font_size_override("normal_font_size", 20)
	history_text.add_theme_color_override("default_color", Color.html("#e8dcc4"))
	for button in [%StateButton, %HistoryButton, %MenuButton]:
		_style_tool(button)

func _style_tool(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0.35)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := normal.duplicate()
	hover.bg_color = Color.html("#c9a22755")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_font_override("font", UIKit.serif())
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.html("#e8d9a8"))
	button.add_theme_color_override("font_hover_color", Color.html("#fff4d2"))

func _connect_ui() -> void:
	%StateButton.pressed.connect(_open_journal)
	%HistoryButton.pressed.connect(_open_history)
	%MenuButton.pressed.connect(_ask_menu)
	%YesButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	%NoButton.pressed.connect(_close_overlays)
	$ClickLayer.gui_input.connect(func(event: InputEvent) -> void:
		if _click(event):
			_advance_say()
	)
	dialogue.gui_input.connect(func(event: InputEvent) -> void:
		if _click(event):
			_advance_say()
			dialogue.accept_event()
	)
	for overlay in [journal, history, confirm]:
		overlay.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				_close_overlays()
		)


func _fill_journal() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.free()
	rows.add_child(UIKit.label(GameState.score_line() + "    %d'" % GameState.minute, 18, Color.html("#b7aa90")))
	var letter := String(GameState.vars.get("letter_to", ""))
	if letter != "" and letter != "не знаешь кому":
		rows.add_child(UIKit.label("Письмо: %s" % letter, 16, Color.html("#8a8070")))
	for row in GameState.STAT_LABELS:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		var title := UIKit.label(String(row[1]), 20, Color.html("#d8cbb0"))
		title.custom_minimum_size = Vector2(170, 0)
		line.add_child(title)
		var bar := ProgressBar.new()
		bar.max_value = int(row[2])
		bar.value = GameState.stat_value(String(row[0]))
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(280, 16)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color.html("#c9a227")
		var back := StyleBoxFlat.new()
		back.bg_color = Color.html("#3a342c")
		bar.add_theme_stylebox_override("fill", fill)
		bar.add_theme_stylebox_override("background", back)
		line.add_child(bar)
		line.add_child(UIKit.label(GameState.level_word(int(bar.value), int(row[2])), 18, Color.html("#9a8f78")))
		rows.add_child(line)


func _sync() -> void:
	_show_background(GameState.bg_id)
	place_label.text = String(CAPTIONS.get(GameState.bg_id, ""))
	hud_box.visible = GameState.show_hud
	hud_score.text = GameState.score_line()
	hud_minute.text = "%d'" % GameState.minute
	var face := String(GameState.portrait_id)
	if face == "" or not FACES.has(face):
		portrait_slot.visible = false
	else:
		portrait_slot.visible = true
		portrait_view.texture = FACES[face]
		if GameState.portrait_side == "right":
			portrait_slot.offset_left = 850
			portrait_slot.offset_right = 1252
		else:
			portrait_slot.offset_left = 28
			portrait_slot.offset_right = 430
		var info: Array = CAST.get(face, [face, Color.html("#d8cbb0")])
		portrait_name.text = String(info[0])

func _show_background(id: String) -> void:
	var next: Texture2D = BG.get(id, BG["cover"])
	background.modulate = Color.BLACK if id == "black" else Color.WHITE
	if background.texture == next:
		return
	background.texture = next
	fade.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.45)

func _on_say(step: Dictionary) -> void:
	waiting = "say"
	_sync()
	choices.visible = false
	dialogue.visible = true
	speaker = String(step.get("who", ""))
	full_text = String(step.get("text", ""))
	if speaker == "":
		name_badge.visible = false
	else:
		var info: Array = CAST.get(speaker, [speaker, Color.html("#c9a227")])
		name_badge.visible = true
		name_badge.text = "  %s  " % String(info[0])
		name_badge.modulate = Color.WHITE
		name_badge.add_theme_color_override("font_color", info[1])
	reveal_pos = 0.0
	revealing = true
	hint.visible = false
	body.text = ""
	_save()

func _advance_say() -> void:
	if waiting != "say" or journal.visible or history.visible or confirm.visible:
		return
	if revealing:
		revealing = false
		body.text = full_text
		hint.visible = true
		return
	_remember(speaker, full_text)
	runner.advance()

func _on_choice(step: Dictionary) -> void:
	waiting = "choice"
	_sync()
	dialogue.visible = false
	choices.visible = true
	for child in choices.get_children():
		child.queue_free()
	choice_buttons.clear()
	selected = 0
	var shown := 0
	for opt in step.get("options", []):
		if opt.has("show_if") and not GameState.eval(opt.show_if):
			continue
		shown += 1
		var caption := "%d   %s" % [shown, String(opt.get("text", ""))]
		var button := UIKit.choice_button(caption)
		var dest := String(opt.get("goto", ""))
		var words := String(opt.get("text", ""))
		button.pressed.connect(_pick.bind(dest, words))
		button.mouse_entered.connect(_hover_choice.bind(button))
		choices.add_child(button)
		choice_buttons.append(button)
	_paint_choices()
	_save()

func _paint_choices() -> void:
	for i in choice_buttons.size():
		UIKit.paint_choice(choice_buttons[i], i == selected)

func _move_choice(delta: int) -> void:
	if choice_buttons.is_empty():
		return
	selected = posmod(selected + delta, choice_buttons.size())
	_paint_choices()

func _hover_choice(button: Button) -> void:
	selected = choice_buttons.find(button)
	_paint_choices()

func _activate_choice() -> void:
	if selected < 0 or selected >= choice_buttons.size():
		return
	choice_buttons[selected].pressed.emit()

func _pick(dest: String, words: String) -> void:
	if waiting != "choice":
		return
	waiting = ""
	_remember("", "— " + words)
	choices.visible = false
	runner.choose(dest)

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
	GameState.write_save(runner.label_id, runner.index)

func _open_journal() -> void:
	if history.visible or confirm.visible:
		return
	if journal.visible:
		journal.visible = false
		return
	_fill_journal()
	journal.visible = true

func _open_history() -> void:
	var lines: PackedStringArray = []
	for entry in GameState.log:
		var who := String(entry.get("who", ""))
		var text := String(entry.get("text", ""))
		if who == "":
			lines.append(text)
		else:
			var info: Array = CAST.get(who, [who])
			lines.append("%s: %s" % [String(info[0]), text])
	history_text.text = "\n\n".join(lines) if not lines.is_empty() else "Пока пусто."
	history.visible = true

func _ask_menu() -> void:
	confirm.visible = true

func _close_overlays() -> void:
	journal.visible = false
	history.visible = false
	confirm.visible = false

func _on_finished() -> void:
	_save()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
