extends Node

const STAT_MAX := {
	"endurance": 10,
	"composure": 10,
	"team_bond": 10,
	"introspection": 10,
	"aggression": 5,
	"knee_pain": 10,
	"fatigue": 10,
	"nostalgia": 10,
	"anxiety": 10,
	"regret": 10,
	"hope": 10,
}

const STAT_LABELS := [
	["endurance", "Тело", 10],
	["composure", "Холод", 10],
	["team_bond", "Связь", 10],
	["introspection", "Правда", 10],
	["knee_pain", "Колени", 10],
	["fatigue", "Усталость", 10],
	["anxiety", "Тревога", 10],
	["hope", "Надежда", 10],
	["regret", "Сожаление", 10],
	["nostalgia", "Память", 10],
	["aggression", "Злость", 5],
]

const SAVE_PATH := "user://save.json"

var mode := "new"
var stats := {}
var flags := {}
var vars := {}
var score_us := 0
var score_them := 0
var minute := 0
var show_hud := false
var bg_id := "black"
var portrait_id := ""
var portrait_side := "left"
var log: Array = []

func _ready() -> void:
	reset()

func reset() -> void:
	stats = {
		"endurance": 6,
		"composure": 5,
		"team_bond": 4,
		"introspection": 3,
		"aggression": 0,
		"knee_pain": 2,
		"fatigue": 0,
		"nostalgia": 0,
		"anxiety": 0,
		"regret": 0,
		"hope": 0,
	}
	flags = {}
	vars = {
		"ending_id": "c",
		"letter_to": "не знаешь кому",
	}
	score_us = 0
	score_them = 0
	minute = 0
	show_hud = false
	bg_id = "black"
	portrait_id = ""
	portrait_side = "left"
	log = []

func stat_value(stat_name: String) -> int:
	return int(stats.get(stat_name, 0))

func apply(step: Dictionary) -> void:
	match String(step.get("op", "")):
		"bg":
			bg_id = String(step.get("id", "black"))
		"portrait":
			portrait_id = String(step.get("id", ""))
			portrait_side = String(step.get("side", "left"))
		"minute":
			minute = int(step.get("n", minute))
		"hud":
			show_hud = bool(step.get("on", false))
		"stat":
			var stat_name := String(step.get("name", ""))
			var hi := int(STAT_MAX.get(stat_name, 10))
			stats[stat_name] = clampi(stat_value(stat_name) + int(step.get("delta", 0)), 0, hi)
		"flag":
			flags[String(step.get("name", ""))] = bool(step.get("value", true))
		"score":
			score_us += int(step.get("us", 0))
			score_them += int(step.get("them", 0))
		"set":
			vars[String(step.get("name", ""))] = step.get("value", "")
		_:
			push_error("Неизвестная команда сюжета: %s" % str(step.get("op", "")))

func flag_on(flag_name: String) -> bool:
	return bool(flags.get(flag_name, false))

func eval(cond: Dictionary) -> bool:
	match String(cond.get("kind", "")):
		"stat":
			var value := stat_value(String(cond.get("stat", "")))
			var n := int(cond.get("n", 0))
			match String(cond.get("cmp", "")):
				">=":
					return value >= n
				">":
					return value > n
				"<":
					return value < n
				"<=":
					return value <= n
				"==":
					return value == n
		"sum":
			var total := 0
			for stat_name in cond.get("stats", []):
				total += stat_value(String(stat_name))
			return total >= int(cond.get("n", 0))
		"flag":
			return flag_on(String(cond.get("flag", "")))
		"all_flags":
			for flag_name in cond.get("flags", []):
				if not flag_on(String(flag_name)):
					return false
			return true
		"any_flags":
			for flag_name in cond.get("flags", []):
				if flag_on(String(flag_name)):
					return true
			return false
		"and":
			for nested in cond.get("conds", []):
				if not eval(nested):
					return false
			return true
		"or":
			for nested in cond.get("conds", []):
				if eval(nested):
					return true
			return false
		"not":
			return not eval(cond.get("cond", {}))
		"score":
			match String(cond.get("cmp", "")):
				"gt":
					return score_us > score_them
				"lt":
					return score_us < score_them
				"eq":
					return score_us == score_them
	push_error("Плохое условие: %s" % str(cond))
	return false

static func level_word(value: int, hi: int = 10) -> String:
	if hi <= 0:
		return "—"
	var t := float(value) / float(hi)
	if t < 0.2:
		return "очень низко"
	if t < 0.4:
		return "низко"
	if t < 0.6:
		return "средне"
	if t < 0.8:
		return "высоко"
	return "очень высоко"

func score_line() -> String:
	return "Торпедо  %d:%d  Прибой" % [score_us, score_them]

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func write_save(label_id: String, index: int) -> void:
	var payload := {
		"label": label_id,
		"index": index,
		"log": log,
		"stats": stats,
		"flags": flags,
		"vars": vars,
		"score_us": score_us,
		"score_them": score_them,
		"minute": minute,
		"show_hud": show_hud,
		"bg": bg_id,
		"portrait": portrait_id,
		"portrait_side": portrait_side,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Не удалось сохранить игру")
		return
	file.store_string(JSON.stringify(payload))

func load_save() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = parsed
	if data.has("stats"):
		for stat_name in STAT_MAX.keys():
			stats[stat_name] = int(data["stats"].get(stat_name, stats.get(stat_name, 0)))
	flags = {}
	if data.has("flags"):
		for flag_name in data["flags"].keys():
			flags[String(flag_name)] = bool(data["flags"][flag_name])
	vars = data.get("vars", vars)
	score_us = int(data.get("score_us", 0))
	score_them = int(data.get("score_them", 0))
	minute = int(data.get("minute", 0))
	show_hud = bool(data.get("show_hud", false))
	bg_id = String(data.get("bg", "black"))
	portrait_id = String(data.get("portrait", ""))
	portrait_side = String(data.get("portrait_side", "left"))
	log = data.get("log", [])
	return {
		"label": String(data.get("label", "intro")),
		"index": int(data.get("index", 0)),
	}
