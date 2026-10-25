class_name GameData

## 数值表读取层：
##   data/cards.xlsx     → 卡牌（含「归属」：通用 / 角色专属）
##   data/characters.xlsx→ 角色（生命、能量、护甲、起始手牌、起始牌组）
##   data/levels.xlsx    → 难度、各难度下的怪物数值、全局设置
##   data/map.xlsx       → 由 MapData 读取
## 找不到表或表损坏时退回到内置默认值，保证游戏还能跑起来。

const CARDS_PATH := "res://data/cards.xlsx"
const CHARACTERS_PATH := "res://data/characters.xlsx"
const LEVELS_PATH := "res://data/levels.xlsx"

const DEFAULT_CARDS := [
	{"id": "strike", "title": "打击", "kind": "攻击", "cost": 1, "description": "造成 6 点伤害。", "accent": "#E06C75", "damage": 6, "block": 0, "draw": 0, "energy_gain": 0, "vulnerable": 0, "strength": 0, "energy_per_turn": 0, "owner": "通用"},
	{"id": "defend", "title": "防御", "kind": "技能", "cost": 1, "description": "获得 5 点格挡。", "accent": "#61AFEF", "damage": 0, "block": 5, "draw": 0, "energy_gain": 0, "vulnerable": 0, "strength": 0, "energy_per_turn": 0, "owner": "通用"},
	{"id": "heavy", "title": "重击", "kind": "攻击", "cost": 2, "description": "造成 12 点伤害。", "accent": "#D19A66", "damage": 12, "block": 0, "draw": 0, "energy_gain": 0, "vulnerable": 0, "strength": 0, "energy_per_turn": 0, "owner": "通用"},
	{"id": "dash", "title": "疾行", "kind": "技能", "cost": 1, "description": "抽 1 张牌。", "accent": "#56B6C2", "damage": 0, "block": 0, "draw": 1, "energy_gain": 0, "vulnerable": 0, "strength": 0, "energy_per_turn": 0, "owner": "通用"},
	{"id": "bash", "title": "痛击", "kind": "攻击", "cost": 2, "description": "造成 8 点伤害，施加 2 层易伤。", "accent": "#C678DD", "damage": 8, "block": 0, "draw": 0, "energy_gain": 0, "vulnerable": 2, "strength": 0, "energy_per_turn": 0, "owner": "通用"},
	{"id": "focus", "title": "凝神", "kind": "技能", "cost": 0, "description": "获得 1 点能量。", "accent": "#98C379", "damage": 0, "block": 0, "draw": 0, "energy_gain": 1, "vulnerable": 0, "strength": 0, "energy_per_turn": 0, "owner": "通用"},
	{"id": "guard", "title": "铁壁", "kind": "技能", "cost": 2, "description": "获得 12 点格挡。", "accent": "#7F9CC7", "damage": 0, "block": 12, "draw": 0, "energy_gain": 0, "vulnerable": 0, "strength": 0, "energy_per_turn": 0, "owner": "通用"},
	{"id": "core", "title": "能量核心", "kind": "能力", "cost": 1, "description": "每回合能量 +1。打出后进入坟场，本场战斗持续生效。", "accent": "#8E7CC3", "damage": 0, "block": 0, "draw": 0, "energy_gain": 0, "vulnerable": 0, "strength": 0, "energy_per_turn": 1, "owner": "通用"},
	{"id": "shield_bash", "title": "盾击", "kind": "攻击", "cost": 1, "description": "造成 5 点伤害，获得 5 点格挡。", "accent": "#E8A33D", "damage": 5, "block": 5, "draw": 0, "energy_gain": 0, "vulnerable": 0, "strength": 0, "energy_per_turn": 0, "owner": "warrior"},
	{"id": "sunder", "title": "破甲斩", "kind": "攻击", "cost": 2, "description": "造成 10 点伤害，施加 1 层易伤。", "accent": "#D9534F", "damage": 10, "block": 0, "draw": 0, "energy_gain": 0, "vulnerable": 1, "strength": 0, "energy_per_turn": 0, "owner": "warrior"},
	{"id": "war_cry", "title": "战吼", "kind": "技能", "cost": 1, "description": "抽 2 张牌。", "accent": "#D98C3F", "damage": 0, "block": 0, "draw": 2, "energy_gain": 0, "vulnerable": 0, "strength": 0, "energy_per_turn": 0, "owner": "warrior"},
	{"id": "bulwark", "title": "坚守", "kind": "技能", "cost": 1, "description": "获得 8 点格挡。", "accent": "#B07C4F", "damage": 0, "block": 8, "draw": 0, "energy_gain": 0, "vulnerable": 0, "strength": 0, "energy_per_turn": 0, "owner": "warrior"},
	{"id": "rage", "title": "战意", "kind": "能力", "cost": 1, "description": "获得 2 点力量。打出后进入坟场，本场战斗持续生效。", "accent": "#C97B4A", "damage": 0, "block": 0, "draw": 0, "energy_gain": 0, "vulnerable": 0, "strength": 2, "energy_per_turn": 0, "owner": "warrior"},
]

const DEFAULT_CHARACTER := {
	"id": "warrior",
	"name": "战士",
	"max_hp": 80,
	"energy": 3,
	"end_turn_block": 3,
	"start_hand": 5,
	"deck": [
		{"id": "strike", "count": 4},
		{"id": "defend", "count": 3},
		{"id": "shield_bash", "count": 2},
		{"id": "war_cry", "count": 1},
		{"id": "sunder", "count": 1},
		{"id": "bulwark", "count": 1},
		{"id": "core", "count": 1},
	],
	"description": "每回合结束获得 3 点护甲。",
	"accent": "#C97B4A",
}

const DEFAULT_DIFFICULTIES := [
	{"name": "普通", "description": "标准数值，适合第一次游玩。", "color": "#7FBF7F"},
	{"name": "困难", "description": "敌人更强，容错更低。", "color": "#E0A040"},
	{"name": "噩梦", "description": "敌人极强，一步失误就结束。", "color": "#D05050"},
]

const DEFAULT_LEVELS := [
	{"level": 1, "difficulty": "普通", "name": "腐化史莱姆", "hp": 60, "pattern": [8, 8, 14], "color": "#7B5CD6", "scale": 1.0},
	{"level": 1, "difficulty": "困难", "name": "腐化史莱姆", "hp": 78, "pattern": [10, 10, 17], "color": "#7B5CD6", "scale": 1.0},
	{"level": 1, "difficulty": "噩梦", "name": "腐化史莱姆", "hp": 96, "pattern": [12, 12, 20], "color": "#7B5CD6", "scale": 1.0},
	{"level": 2, "difficulty": "普通", "name": "荒野狼", "hp": 70, "pattern": [10, 7, 16], "color": "#C98A4B", "scale": 1.0},
	{"level": 2, "difficulty": "困难", "name": "荒野狼", "hp": 91, "pattern": [12, 9, 19], "color": "#C98A4B", "scale": 1.0},
	{"level": 2, "difficulty": "噩梦", "name": "荒野狼", "hp": 112, "pattern": [15, 11, 22], "color": "#C98A4B", "scale": 1.0},
	{"level": 3, "difficulty": "普通", "name": "石像鬼", "hp": 85, "pattern": [12, 12, 18], "color": "#7F8C9B", "scale": 1.05},
	{"level": 3, "difficulty": "困难", "name": "石像鬼", "hp": 111, "pattern": [14, 14, 21], "color": "#7F8C9B", "scale": 1.05},
	{"level": 3, "difficulty": "噩梦", "name": "石像鬼", "hp": 136, "pattern": [17, 17, 25], "color": "#7F8C9B", "scale": 1.05},
	{"level": 4, "difficulty": "普通", "name": "咒术师", "hp": 95, "pattern": [9, 16, 9], "color": "#4F9D8C", "scale": 0.95},
	{"level": 4, "difficulty": "困难", "name": "咒术师", "hp": 124, "pattern": [11, 19, 11], "color": "#4F9D8C", "scale": 0.95},
	{"level": 4, "difficulty": "噩梦", "name": "咒术师", "hp": 152, "pattern": [13, 22, 13], "color": "#4F9D8C", "scale": 0.95},
	{"level": 5, "difficulty": "普通", "name": "深渊领主", "hp": 110, "pattern": [15, 12, 20], "color": "#B03A48", "scale": 1.12},
	{"level": 5, "difficulty": "困难", "name": "深渊领主", "hp": 143, "pattern": [18, 15, 24], "color": "#B03A48", "scale": 1.12},
	{"level": 5, "difficulty": "噩梦", "name": "深渊领主", "hp": 176, "pattern": [21, 18, 28], "color": "#B03A48", "scale": 1.12},
]

const DEFAULT_SETTINGS := {
	"手牌上限": 10,
	"休整回复": 25,
}

static var _cards: Array[Dictionary] = []
static var _characters: Array[Dictionary] = []
static var _difficulties: Array[Dictionary] = []
static var _levels_by_difficulty: Dictionary = {}
static var _settings: Dictionary = {}
static var _loaded := false
static var _source := ""


static func load_all(force := false) -> void:
	if _loaded and not force:
		return
	_loaded = true
	_cards.clear()
	_characters.clear()
	_difficulties.clear()
	_levels_by_difficulty.clear()
	_settings.clear()

	var card_sheets := XlsxReader.read_sheets(CARDS_PATH)
	var character_sheets := XlsxReader.read_sheets(CHARACTERS_PATH)
	var level_sheets := XlsxReader.read_sheets(LEVELS_PATH)
	var loaded_paths: Array[String] = []

	if card_sheets.is_empty():
		push_warning("GameData：读取 %s 失败，卡牌改用内置默认值" % CARDS_PATH)
	else:
		loaded_paths.append(CARDS_PATH)
		_parse_cards(card_sheets.get("卡牌", []))

	if character_sheets.is_empty():
		push_warning("GameData：读取 %s 失败，角色改用内置默认值" % CHARACTERS_PATH)
	else:
		loaded_paths.append(CHARACTERS_PATH)
		_parse_characters(character_sheets.get("人物", []))

	if level_sheets.is_empty():
		push_warning("GameData：读取 %s 失败，难度与关卡改用内置默认值" % LEVELS_PATH)
	else:
		loaded_paths.append(LEVELS_PATH)
		_parse_difficulties(level_sheets.get("难度", []))
		_parse_levels(level_sheets.get("关卡", []))
		_parse_settings(level_sheets.get("设置", []))

	_source = " + ".join(loaded_paths) if not loaded_paths.is_empty() else "内置默认值（表格读取失败）"

	if _cards.is_empty():
		_cards = DEFAULT_CARDS.duplicate(true)
	if _characters.is_empty():
		_characters = [DEFAULT_CHARACTER.duplicate(true)]
	if _difficulties.is_empty():
		_difficulties = DEFAULT_DIFFICULTIES.duplicate(true)
	if _levels_by_difficulty.is_empty():
		_levels_by_difficulty = _group_levels(DEFAULT_LEVELS.duplicate(true))
	if _settings.is_empty():
		_settings = DEFAULT_SETTINGS.duplicate(true)

	for character in _characters:
		if character.get("deck", []).is_empty():
			character["deck"] = DEFAULT_CHARACTER["deck"].duplicate(true)


# ---------------------------------------------------------------- 对外接口

static func source() -> String:
	return _source


static func cards() -> Array[Dictionary]:
	load_all()
	return _cards


static func cards_by_id() -> Dictionary:
	load_all()
	var result := {}
	for card in _cards:
		result[String(card.get("id", ""))] = card
	return result


static func characters() -> Array[Dictionary]:
	load_all()
	return _characters


static func character(index := 0) -> Dictionary:
	load_all()
	if _characters.is_empty():
		return DEFAULT_CHARACTER.duplicate(true)
	return _characters[clampi(index, 0, _characters.size() - 1)]


static func difficulties() -> Array[Dictionary]:
	load_all()
	return _difficulties


## 某个难度下的所有层；难度不存在时退回第一个难度。
static func levels(difficulty_name := "") -> Array[Dictionary]:
	load_all()
	var result: Array[Dictionary] = []
	if not difficulty_name.is_empty() and _levels_by_difficulty.has(difficulty_name):
		result.assign(_levels_by_difficulty[difficulty_name])
		return result
	if _levels_by_difficulty.is_empty():
		return result
	var first_key: String = String(_levels_by_difficulty.keys()[0])
	result.assign(_levels_by_difficulty[first_key])
	return result


static func int_setting(key: String, fallback: int) -> int:
	load_all()
	if not _settings.has(key):
		return fallback
	var raw = _settings[key]
	if raw is int or raw is float:
		return int(raw)
	var text := String(raw).strip_edges()
	return text.to_int() if text.is_valid_int() else fallback


static func float_setting(key: String, fallback: float) -> float:
	load_all()
	if not _settings.has(key):
		return fallback
	var raw = _settings[key]
	if raw is int or raw is float:
		return float(raw)
	var text := String(raw).strip_edges()
	return text.to_float() if text.is_valid_float() else fallback


# ---------------------------------------------------------------- 解析

static func _parse_cards(rows: Array) -> void:
	if rows.size() < 2:
		return
	var columns := _header_index(rows[0])
	for r in range(1, rows.size()):
		var row: Array = rows[r]
		var title := _text(row, columns, "名称")
		if title == "":
			continue
		var card_id := _text(row, columns, "卡牌ID")
		if card_id == "":
			card_id = title
		_cards.append({
			"id": card_id,
			"title": title,
			"kind": _text(row, columns, "类型", "技能"),
			"cost": _int(_text(row, columns, "费用"), 1),
			"description": _text(row, columns, "描述"),
			"accent": _text(row, columns, "主题色", "#7AA2F7"),
			"damage": _int(_text(row, columns, "伤害"), 0),
			"block": _int(_text(row, columns, "格挡"), 0),
			"draw": _int(_text(row, columns, "抽牌"), 0),
			"energy_gain": _int(_text(row, columns, "能量"), 0),
			"vulnerable": _int(_text(row, columns, "易伤"), 0),
			"strength": _int(_text(row, columns, "力量"), 0),
			"energy_per_turn": _int(_text(row, columns, "每回合能量"), 0),
			"owner": _text(row, columns, "归属", "通用"),
		})


static func _parse_characters(rows: Array) -> void:
	if rows.size() < 2:
		return
	var columns := _header_index(rows[0])
	for r in range(1, rows.size()):
		var row: Array = rows[r]
		var name_text := _text(row, columns, "名称")
		if name_text == "":
			continue
		_characters.append({
			"id": _text(row, columns, "人物ID"),
			"name": name_text,
			"max_hp": _int(_text(row, columns, "最大生命"), 80),
			"energy": _int(_text(row, columns, "每回合能量"), 3),
			"end_turn_block": _int(_text(row, columns, "回合结束护甲"), 0),
			"start_hand": _int(_text(row, columns, "起始手牌数量"), 5),
			"deck": _parse_deck(_text(row, columns, "起始牌组")),
			"description": _text(row, columns, "描述"),
			"accent": _text(row, columns, "主题色", "#C97B4A"),
		})


static func _parse_difficulties(rows: Array) -> void:
	if rows.size() < 2:
		return
	var columns := _header_index(rows[0])
	for r in range(1, rows.size()):
		var row: Array = rows[r]
		var name_text := _text(row, columns, "难度")
		if name_text == "":
			continue
		_difficulties.append({
			"name": name_text,
			"description": _text(row, columns, "说明"),
			"color": _text(row, columns, "颜色", "#7FBF7F"),
		})


static func _parse_levels(rows: Array) -> void:
	if rows.size() < 2:
		return
	var columns := _header_index(rows[0])
	for r in range(1, rows.size()):
		var row: Array = rows[r]
		var name_text := _text(row, columns, "名称")
		if name_text == "":
			continue
		var hp := _int(_text(row, columns, "生命"), 0)
		if hp <= 0:
			continue
		var difficulty_name := _text(row, columns, "难度", "普通")
		var pattern: Array[int] = []
		for key in ["攻击1", "攻击2", "攻击3", "攻击4"]:
			var value := _text(row, columns, key)
			if value != "":
				pattern.append(_int(value, 0))
		if pattern.is_empty():
			pattern = [8]
		if not _levels_by_difficulty.has(difficulty_name):
			_levels_by_difficulty[difficulty_name] = []
		var bucket: Array = _levels_by_difficulty[difficulty_name]
		bucket.append({
			"level": _int(_text(row, columns, "关卡"), 1),
			"name": name_text,
			"hp": hp,
			"pattern": pattern,
			"color": _text(row, columns, "颜色", "#7B5CD6"),
			"scale": _float(_text(row, columns, "体型"), 1.0),
		})
	for key in _levels_by_difficulty.keys():
		var list: Array = _levels_by_difficulty[key]
		list.sort_custom(func(a, b): return int(a.get("level", 0)) < int(b.get("level", 0)))


static func _parse_settings(rows: Array) -> void:
	if rows.size() < 2:
		return
	var columns := _header_index(rows[0])
	for r in range(1, rows.size()):
		var row: Array = rows[r]
		var key := _text(row, columns, "项目")
		if key == "":
			continue
		_settings[key] = _text(row, columns, "值")


## 解析「起始牌组」：strike:4, defend:3，支持中英文逗号/分号与冒号。
static func _parse_deck(text_value: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var normalized := text_value.replace("；", ",").replace("，", ",").replace(";", ",")
	for piece in normalized.split(",", false):
		var item := piece.strip_edges()
		if item == "":
			continue
		item = item.replace("：", ":").replace("×", "x").replace("*", "x")
		var parts := item.split(":", false)
		var card_id := parts[0].strip_edges()
		var count := 1
		if parts.size() > 1:
			var count_text := parts[1].strip_edges().to_lower().trim_prefix("x")
			count = count_text.to_int() if count_text.is_valid_int() else 1
		if card_id == "" or count <= 0:
			continue
		entries.append({"id": card_id, "count": count})
	return entries


static func _group_levels(source_rows: Array) -> Dictionary:
	var grouped := {}
	for row in source_rows:
		var difficulty_name := String(row.get("difficulty", "普通"))
		if not grouped.has(difficulty_name):
			grouped[difficulty_name] = []
		var bucket: Array = grouped[difficulty_name]
		bucket.append(row.duplicate(true))
	return grouped


# ---------------------------------------------------------------- 小工具

static func _header_index(header: Array) -> Dictionary:
	var columns := {}
	for i in header.size():
		var name := String(header[i]).strip_edges()
		if name != "":
			columns[name] = i
	return columns


static func _text(row: Array, columns: Dictionary, key: String, fallback := "") -> String:
	if not columns.has(key):
		return fallback
	var index: int = columns[key]
	if index < 0 or index >= row.size():
		return fallback
	var value := String(row[index]).strip_edges()
	return value if value != "" else fallback


static func _int(text_value: String, fallback: int) -> int:
	return text_value.to_int() if text_value.is_valid_int() else fallback


static func _float(text_value: String, fallback: float) -> float:
	return text_value.to_float() if text_value.is_valid_float() else fallback
