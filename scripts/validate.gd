extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var book: Dictionary = StoryData.labels()
	var errs := StoryData.problems(book)
	if not errs.is_empty():
		for err in errs:
			push_error(err)
		print("ОШИБКИ: ", errs.size())
		quit(1)
		return
	var failed := false
	for policy in ["first", "last"]:
		var ending := _play(book, policy)
		if ending == "":
			failed = true
		else:
			print("OK ", policy, " -> ", ending)
	quit(1 if failed else 0)

func _play(book: Dictionary, policy: String) -> String:
	var state = preload("res://scripts/game_state.gd").new()
	state.reset()
	var runner := StoryRunner.new()
	runner.auto = true
	var visited := {}
	runner.auto_choice = func(step: Dictionary) -> String:
		return _pick(state, step, visited, policy)
	runner.setup(book, state)
	runner.finished.connect(func() -> void:
		pass
	)
	runner.start("intro")
	if runner.dead or runner.label_id != "credits":
		push_error("Политика %s остановилась на %s (шаг %s)" % [policy, runner.label_id, runner.index])
		return ""
	print("  счёт ", state.score_us, ":", state.score_them, " концовка ", state.vars.get("ending_id", "?"))
	return String(state.vars.get("ending_id", "?"))

func _pick(state, step: Dictionary, visited: Dictionary, policy: String) -> String:
	var visible: Array = []
	for opt in step.get("options", []):
		if opt.has("show_if") and not state.eval(opt.show_if):
			continue
		visible.append(opt)
	if visible.is_empty():
		return ""
	var fresh: Array = []
	for opt in visible:
		if not visited.has(String(opt.get("goto", ""))):
			fresh.append(opt)
	var pool: Array = fresh if not fresh.is_empty() else visible
	var dest := ""
	if fresh.is_empty():
		var order: Array = visible.duplicate()
		if policy == "last":
			order.reverse()
		for opt in order:
			if _progress(String(opt.get("goto", ""))):
				dest = String(opt.get("goto", ""))
				break
	if dest == "":
		dest = String(pool[0 if policy == "first" else pool.size() - 1].get("goto", ""))
	visited[dest] = true
	return dest

func _progress(id: String) -> bool:
	return id in [
		"sideline", "first_half", "halftime", "second_half",
		"ending_resolve", "after_whistle", "epilogue", "credits",
	]
