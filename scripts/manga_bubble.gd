extends Control

signal picked

var ink := Color(0.102, 0.086, 0.071)
var gold := Color(0.788, 0.635, 0.153)
var hovered := false
var _poly := PackedVector2Array()

func setup(body: String, oval: Rect2, tail_tip: Vector2) -> void:
	var bbox := Rect2(oval.position, oval.size)
	bbox = bbox.expand(tail_tip).grow(8.0)
	position = bbox.position
	size = bbox.size
	var local_oval := Rect2(oval.position - position, oval.size)
	var local_tail := tail_tip - position
	_poly = _make_poly(local_oval, local_tail)
	var label := Label.new()
	label.text = body
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UIKit.serif())
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", ink)
	var pad := Vector2(18, 12)
	label.position = local_oval.position + pad
	label.size = local_oval.size - pad * 2.0
	add_child(label)
	queue_redraw()

func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, _poly)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		hovered = true
		queue_redraw()
	elif what == NOTIFICATION_MOUSE_EXIT:
		hovered = false
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		picked.emit()
		accept_event()

func _draw() -> void:
	if _poly.size() < 3:
		return
	var fill := Color(1, 0.985, 0.95) if not hovered else Color(1, 0.96, 0.86)
	var colors := PackedColorArray()
	colors.resize(_poly.size())
	for i in _poly.size():
		colors[i] = fill
	draw_polygon(_poly, colors)
	var line := _poly.duplicate()
	line.append(_poly[0])
	draw_polyline(line, gold if hovered else ink, 3.0, true)

func _make_poly(oval: Rect2, tail_tip: Vector2) -> PackedVector2Array:
	var center := oval.get_center()
	var radius := oval.size * 0.5
	var steps := 34
	var pts: Array[Vector2] = []
	for i in steps:
		var angle := TAU * float(i) / float(steps)
		var wobble := 1.0 + 0.04 * sin(angle * 3.0)
		pts.append(center + Vector2(cos(angle) * radius.x * wobble, sin(angle) * radius.y * wobble))
	var direction := (tail_tip - center).normalized()
	var best := 0
	var best_dot := -2.0
	for i in steps:
		var dot := (pts[i] - center).normalized().dot(direction)
		if dot > best_dot:
			best_dot = dot
			best = i
	var poly := PackedVector2Array()
	for i in steps:
		var gap := mini(absi(i - best), steps - absi(i - best))
		if gap == 0:
			poly.append(tail_tip)
		elif gap > 2:
			poly.append(pts[i])
	return poly
