class_name VN
extends RefCounted

static func say(text: String, who: String = "") -> Dictionary:
	return {"op": "say", "text": text, "who": who}

static func say_if(cond: Dictionary, text: String, who: String = "") -> Dictionary:
	return {"op": "say_if", "cond": cond, "text": text, "who": who}

static func bg(id: String) -> Dictionary:
	return {"op": "bg", "id": id}

static func portrait(id: String, side: String = "left") -> Dictionary:
	return {"op": "portrait", "id": id, "side": side}

static func goto(id: String) -> Dictionary:
	return {"op": "goto", "id": id}

static func if_goto(cond: Dictionary, id: String) -> Dictionary:
	return {"op": "if_goto", "cond": cond, "id": id}

static func stat(stat_name: String, delta: int) -> Dictionary:
	return {"op": "stat", "name": stat_name, "delta": delta}

static func flag(flag_name: String, value: bool = true) -> Dictionary:
	return {"op": "flag", "name": flag_name, "value": value}

static func score(us: int = 0, them: int = 0) -> Dictionary:
	return {"op": "score", "us": us, "them": them}

static func minute(n: int) -> Dictionary:
	return {"op": "minute", "n": n}

static func hud(on: bool) -> Dictionary:
	return {"op": "hud", "on": on}

static func setv(var_name: String, value: String) -> Dictionary:
	return {"op": "set", "name": var_name, "value": value}

static func choice(options: Array) -> Dictionary:
	return {"op": "choice", "options": options}

static func opt(text: String, dest: String, show_if: Dictionary = {}) -> Dictionary:
	var row := {"text": text, "goto": dest}
	if not show_if.is_empty():
		row["show_if"] = show_if
	return row

static func ge(stat_name: String, n: int) -> Dictionary:
	return {"kind": "stat", "stat": stat_name, "cmp": ">=", "n": n}

static func gt(stat_name: String, n: int) -> Dictionary:
	return {"kind": "stat", "stat": stat_name, "cmp": ">", "n": n}

static func lt(stat_name: String, n: int) -> Dictionary:
	return {"kind": "stat", "stat": stat_name, "cmp": "<", "n": n}

static func sum_ge(stat_names: Array, n: int) -> Dictionary:
	return {"kind": "sum", "stats": stat_names, "cmp": ">=", "n": n}

static func flag_on(flag_name: String) -> Dictionary:
	return {"kind": "flag", "flag": flag_name}

static func flag_off(flag_name: String) -> Dictionary:
	return {"kind": "not", "cond": {"kind": "flag", "flag": flag_name}}

static func all_flags(flag_names: Array) -> Dictionary:
	return {"kind": "all_flags", "flags": flag_names}

static func any_flags(flag_names: Array) -> Dictionary:
	return {"kind": "any_flags", "flags": flag_names}

static func AND(conds: Array) -> Dictionary:
	return {"kind": "and", "conds": conds}

static func OR(conds: Array) -> Dictionary:
	return {"kind": "or", "conds": conds}

static func NOT(cond: Dictionary) -> Dictionary:
	return {"kind": "not", "cond": cond}

static func score_cmp(cmp: String) -> Dictionary:
	return {"kind": "score", "cmp": cmp}
