class_name StoryRunner
extends RefCounted

signal waiting_say(step)
signal waiting_choice(step)
signal finished

var labels: Dictionary = {}
var state
var label_id := ""
var index := 0
var auto := false
var auto_choice: Callable = Callable()
var dead := false
var steps_done := 0
var visits := {}

func setup(book: Dictionary, match_state) -> void:
	labels = book
	state = match_state

func start(id: String) -> void:
	dead = false
	steps_done = 0
	visits = {}
	enter(id)
	run()

func resume(id: String, at: int) -> void:
	dead = false
	label_id = id
	index = at
	run()

func enter(id: String) -> void:
	if not labels.has(id):
		push_error("Нет сцены: %s" % id)
		dead = true
		return
	visits[id] = int(visits.get(id, 0)) + 1
	if auto and int(visits[id]) > 40:
		push_error("Петля сюжета: %s" % id)
		dead = true
		return
	label_id = id
	index = 0

func advance() -> void:
	index += 1
	run()

func choose(dest: String) -> void:
	enter(dest)
	if dead:
		finished.emit()
		return
	run()

func run() -> void:
	while not dead:
		steps_done += 1
		if auto and steps_done > 8000:
			push_error("Прогон не закончился. Сцена: %s" % label_id)
			dead = true
			break
		var steps: Array = labels[label_id]
		if index >= steps.size():
			finished.emit()
			return
		var step: Dictionary = steps[index]
		var op := String(step.get("op", ""))
		if op == "say" or op == "say_if":
			if op == "say_if" and not state.eval(step.get("cond", {})):
				index += 1
				continue
			if auto:
				index += 1
				continue
			waiting_say.emit(step)
			return
		if op == "choice":
			if auto:
				var dest := ""
				if auto_choice.is_valid():
					dest = String(auto_choice.call(step))
				if dest == "":
					push_error("Нет доступного выбора: %s" % label_id)
					dead = true
					break
				enter(dest)
				continue
			waiting_choice.emit(step)
			return
		if op == "goto":
			enter(String(step.get("id", "")))
			continue
		if op == "if_goto":
			if state.eval(step.get("cond", {})):
				enter(String(step.get("id", "")))
			else:
				index += 1
			continue
		state.apply(step)
		index += 1
	if dead:
		finished.emit()
