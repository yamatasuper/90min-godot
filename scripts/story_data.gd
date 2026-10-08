class_name StoryData
extends RefCounted

static func labels() -> Dictionary:
	var out := {}
	var parts: Array = [
		preload("res://scripts/story_early.gd").labels(),
		preload("res://scripts/story_first.gd").labels(),
		preload("res://scripts/story_half.gd").labels(),
		preload("res://scripts/story_second.gd").labels(),
		preload("res://scripts/story_end.gd").labels(),
	]
	for part in parts:
		for key in part.keys():
			if out.has(key):
				push_error("Повтор сцены: %s" % str(key))
			out[key] = part[key]
	return out

static func problems(book: Dictionary) -> PackedStringArray:
	var errs := PackedStringArray()
	var known := {
		"say": true, "say_if": true, "bg": true, "portrait": true, "goto": true,
		"if_goto": true, "stat": true, "flag": true, "score": true, "set": true,
		"minute": true, "hud": true, "choice": true,
	}
	var endings := {"say": true, "choice": true, "goto": true}
	var stat_max: Dictionary = preload("res://scripts/game_state.gd").STAT_MAX
	for id in book.keys():
		var steps = book[id]
		if typeof(steps) != TYPE_ARRAY or steps.is_empty():
			errs.append("Пустая сцена: %s" % str(id))
			continue
		var last_op := ""
		for step in steps:
			if typeof(step) != TYPE_DICTIONARY or not step.has("op"):
				errs.append("%s: битый шаг" % str(id))
				continue
			var op := String(step.op)
			last_op = op
			if not known.has(op):
				errs.append("%s: неизвестная команда %s" % [str(id), op])
			if op == "goto" or op == "if_goto":
				var dest := String(step.get("id", ""))
				if not book.has(dest):
					errs.append("%s: нет перехода %s" % [str(id), dest])
			if op == "stat" and not stat_max.has(String(step.get("name", ""))):
				errs.append("%s: нет стата %s" % [str(id), str(step.get("name", ""))])
			if op == "choice":
				var options = step.get("options", [])
				if typeof(options) != TYPE_ARRAY or options.is_empty():
					errs.append("%s: пустой выбор" % str(id))
				else:
					for opt in options:
						var dest := String(opt.get("goto", ""))
						if dest == "" or not book.has(dest):
							errs.append("%s: выбор ведёт в никуда (%s)" % [str(id), dest])
		if not endings.has(last_op):
			errs.append("%s: сцена обрывается на %s" % [str(id), last_op])
	if not book.has("intro") or not book.has("credits"):
		errs.append("Нет intro или credits")
	return errs
