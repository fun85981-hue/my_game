class_name MapData

## 地图数据：来自 data/map.xlsx 的「地图」工作表。
## 每个节点有 层(0 起) / 列 / 类型；连线由相邻层、列号相差不超过 1 自动生成。

const PATH := "res://data/map.xlsx"
const TYPES := ["战斗", "精英", "休整", "首领"]

const DEFAULT_NODES := [
	{"floor": 0, "col": 0, "type": "战斗"},
	{"floor": 0, "col": 1, "type": "战斗"},
	{"floor": 0, "col": 2, "type": "战斗"},
	{"floor": 1, "col": 0, "type": "战斗"},
	{"floor": 1, "col": 1, "type": "精英"},
	{"floor": 1, "col": 2, "type": "战斗"},
	{"floor": 1, "col": 3, "type": "休整"},
	{"floor": 2, "col": 0, "type": "战斗"},
	{"floor": 2, "col": 1, "type": "战斗"},
	{"floor": 2, "col": 2, "type": "精英"},
	{"floor": 2, "col": 3, "type": "战斗"},
	{"floor": 3, "col": 0, "type": "休整"},
	{"floor": 3, "col": 1, "type": "战斗"},
	{"floor": 3, "col": 2, "type": "精英"},
	{"floor": 4, "col": 1, "type": "首领"},
]

static var _nodes: Array[Dictionary] = []


static func nodes() -> Array[Dictionary]:
	if not _nodes.is_empty():
		return _nodes
	var sheets := XlsxReader.read_sheets(PATH)
	if sheets.is_empty():
		push_warning("MapData：读取 %s 失败，使用内置默认地图" % PATH)
		_nodes = DEFAULT_NODES.duplicate(true)
		return _nodes
	var rows: Array = sheets.get("地图", [])
	if rows.size() < 2:
		push_warning("MapData：地图表为空，使用内置默认地图")
		_nodes = DEFAULT_NODES.duplicate(true)
		return _nodes
	var columns := _header_index(rows[0])
	for r in range(1, rows.size()):
		var row: Array = rows[r]
		var floor_text := _text(row, columns, "层")
		if floor_text == "":
			continue
		var floor_index := maxi(0, floor_text.to_int() - 1)
		var node_type := _text(row, columns, "类型", "战斗")
		if not TYPES.has(node_type):
			push_warning("MapData：未知节点类型「%s」，按「战斗」处理" % node_type)
			node_type = "战斗"
		_nodes.append({
			"floor": floor_index,
			"col": maxi(0, _text(row, columns, "列", "0").to_int()),
			"type": node_type,
		})
	_nodes.sort_custom(func(a, b):
		if int(a["floor"]) == int(b["floor"]):
			return int(a["col"]) < int(b["col"])
		return int(a["floor"]) < int(b["floor"])
	)
	if _nodes.is_empty():
		_nodes = DEFAULT_NODES.duplicate(true)
	return _nodes


## 生成连线：相邻层且列号相差 ≤ 1；若某节点没有父/子，则连到最近的一个。
static func build_edges(list: Array[Dictionary]) -> Array[Vector2i]:
	var edges: Array[Vector2i] = []
	for i in list.size():
		for j in list.size():
			if int(list[j]["floor"]) != int(list[i]["floor"]) + 1:
				continue
			if absi(int(list[j]["col"]) - int(list[i]["col"])) <= 1:
				edges.append(Vector2i(i, j))

	var max_floor := 0
	for node in list:
		max_floor = maxi(max_floor, int(node["floor"]))

	for i in list.size():
		var floor_index := int(list[i]["floor"])
		var col := int(list[i]["col"])
		if floor_index > 0 and not _has_incoming(edges, i):
			var parent := _nearest(list, floor_index - 1, col)
			if parent >= 0:
				edges.append(Vector2i(parent, i))
		if floor_index < max_floor and not _has_outgoing(edges, i):
			var child := _nearest(list, floor_index + 1, col)
			if child >= 0:
				edges.append(Vector2i(i, child))
	return edges


static func _has_incoming(edges: Array[Vector2i], index: int) -> bool:
	for edge in edges:
		if edge.y == index:
			return true
	return false


static func _has_outgoing(edges: Array[Vector2i], index: int) -> bool:
	for edge in edges:
		if edge.x == index:
			return true
	return false


static func _nearest(list: Array[Dictionary], floor_index: int, col: int) -> int:
	var best := -1
	var best_distance := 99999
	for i in list.size():
		if int(list[i]["floor"]) != floor_index:
			continue
		var distance := absi(int(list[i]["col"]) - col)
		if distance < best_distance:
			best_distance = distance
			best = i
	return best


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
