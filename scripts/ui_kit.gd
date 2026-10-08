class_name UIKit
extends RefCounted

static var _serif: Font
static var _bold: Font

static func serif() -> Font:
	if _serif == null:
		var font := SystemFont.new()
		font.font_names = PackedStringArray([
			"New York", "Iowan Old Style", "Palatino", "Times New Roman",
			"Georgia", "Noto Serif", "Liberation Serif", "serif",
		])
		_serif = font
	return _serif

static func bold() -> Font:
	if _bold == null:
		var font := SystemFont.new()
		font.font_names = PackedStringArray([
			"New York", "Iowan Old Style", "Palatino", "Times New Roman",
			"Georgia", "Noto Serif", "Liberation Serif", "serif",
		])
		font.font_weight = 700
		_bold = font
	return _bold

static func apply_theme(node: Control) -> void:
	var theme := Theme.new()
	theme.default_font = serif()
	theme.default_font_size = 20
	node.theme = theme

static func label(text: String, size: int, color: Color, bold_face := false) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", bold() if bold_face else serif())
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node

static func flat_button(text: String, min_size: Vector2 = Vector2(420, 48)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := normal.duplicate()
	hover.bg_color = Color.html("#c9a22718")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_font_override("font", serif())
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color.html("#d8cbb0"))
	button.add_theme_color_override("font_hover_color", Color.html("#c9a227"))
	button.add_theme_color_override("font_pressed_color", Color.html("#e8d9a8"))
	return button

static func choice_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(760, 52)
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_paint_choice(button, false)
	button.add_theme_font_override("font", serif())
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color.html("#e8dcc4"))
	button.add_theme_color_override("font_hover_color", Color.html("#0c0b09"))
	button.add_theme_color_override("font_pressed_color", Color.html("#0c0b09"))
	return button

static func paint_choice(button: Button, selected: bool) -> void:
	_paint_choice(button, selected)

static func _paint_choice(button: Button, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.html("#c9a227") if selected else Color.html("#161310ee")
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	var hover := normal.duplicate()
	hover.bg_color = Color.html("#c9a227")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_color_override("font_color", Color.html("#0c0b09") if selected else Color.html("#e8dcc4"))
