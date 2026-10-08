extends Control

var poly: PackedVector2Array = PackedVector2Array()
var art: Texture2D
var region: Rect2 = Rect2()
var shown := false
var active := false
var index := 0
var paper := Color(0.965, 0.941, 0.894)
var ink := Color(0.102, 0.086, 0.071)
var gold := Color(0.788, 0.635, 0.153)
var empty := Color(0.89, 0.86, 0.8)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_state(is_shown: bool, is_active: bool) -> void:
	shown = is_shown
	active = is_active
	queue_redraw()

func _draw() -> void:
	if poly.size() < 3:
		return
	if shown and art != null:
		var colors := PackedColorArray()
		colors.resize(poly.size())
		for i in poly.size():
			colors[i] = Color.WHITE
		draw_polygon(poly, colors, _uvs(), art)
	else:
		draw_colored_polygon(poly, empty)
	var line := poly.duplicate()
	line.append(poly[0])
	var border := gold if active else ink
	draw_polyline(line, border, 4.0 if active else 3.0, true)
	_draw_mark()

func _draw_mark() -> void:
	var centroid := Vector2.ZERO
	for point in poly:
		centroid += point
	centroid /= float(poly.size())
	var corner := poly[0]
	for point in poly:
		if point.x + point.y < corner.x + corner.y:
			corner = point
	var inward := centroid - corner
	if inward.length() < 1.0:
		return
	var at := corner + inward.normalized() * 30.0
	var badge := Rect2(at - Vector2(10, 10), Vector2(20, 20))
	var badge_color := gold if active else (Color(ink, 0.82) if shown else Color(ink, 0.22))
	draw_rect(badge, badge_color)
	var num_color := ink if active else (Color(0.97, 0.95, 0.91) if shown else ink)
	draw_string(UIKit.bold(), badge.position + Vector2(6, 15), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, num_color)

func _uvs() -> PackedVector2Array:
	var bbox := Rect2(poly[0], Vector2.ZERO)
	for point in poly:
		bbox = bbox.expand(point)
	var region_aspect := maxf(region.size.x, 1.0) / maxf(region.size.y, 1.0)
	var box_aspect := maxf(bbox.size.x, 1.0) / maxf(bbox.size.y, 1.0)
	var uv_w := 1.0
	var uv_h := 1.0
	if box_aspect > region_aspect:
		uv_h = region_aspect / box_aspect
	else:
		uv_w = box_aspect / region_aspect
	var origin := Vector2((1.0 - uv_w) * 0.5, (1.0 - uv_h) * 0.5)
	var uvs := PackedVector2Array()
	for point in poly:
		var nx := (point.x - bbox.position.x) / maxf(bbox.size.x, 1.0)
		var ny := (point.y - bbox.position.y) / maxf(bbox.size.y, 1.0)
		uvs.append(Vector2(origin.x + nx * uv_w, origin.y + ny * uv_h))
	return uvs
