extends Control

func _ready() -> void:
	UIKit.apply_theme(self)
	for button in [%StartButton, %ContinueButton, %AboutButton, %QuitButton]:
		_style_menu_button(button)
	%ContinueButton.visible = GameState.has_save()
	%StartButton.pressed.connect(func() -> void:
		GameState.mode = "new"
		get_tree().change_scene_to_file("res://scenes/manga_game.tscn")
	)
	%ContinueButton.pressed.connect(func() -> void:
		GameState.mode = "continue"
		get_tree().change_scene_to_file("res://scenes/manga_game.tscn")
	)
	%AboutButton.pressed.connect(func() -> void:
		%AboutOverlay.visible = true
	)
	%QuitButton.pressed.connect(func() -> void:
		get_tree().quit()
	)
	%AboutOverlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			%AboutOverlay.visible = false
	)
	$Panel/Menu/Title.add_theme_font_override("font", UIKit.bold())
	$Panel/Menu/Subtitle.add_theme_color_override("font_color", Color.html("#c9a227"))
	$Panel/Menu/Meta.add_theme_color_override("font_color", Color.html("#b7aa90"))
	$Panel/Menu/Tagline.add_theme_color_override("font_color", Color.html("#8a8070"))
	$Foot.add_theme_color_override("font_color", Color.html("#6f675c"))
	$AboutOverlay/Card/Text/Heading.add_theme_font_override("font", UIKit.bold())
	$AboutOverlay/Card/Text/Heading.add_theme_font_size_override("font_size", 36)
	$AboutOverlay/Card/Text/Heading.add_theme_color_override("font_color", Color.html("#e8d9a8"))
	$AboutOverlay/Card/Text/Body.add_theme_font_size_override("font_size", 22)
	$AboutOverlay/Card/Text/Body.add_theme_color_override("font_color", Color.html("#e8dcc4"))

func _style_menu_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := normal.duplicate()
	hover.bg_color = Color.html("#c9a22718")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_font_override("font", UIKit.serif())
	button.add_theme_font_size_override("font_size", 32)
	button.add_theme_color_override("font_color", Color.html("#d8cbb0"))
	button.add_theme_color_override("font_hover_color", Color.html("#c9a227"))
