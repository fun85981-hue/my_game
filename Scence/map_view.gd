class_name MapView
extends Control

## 分支地图的显示与交互：画连线、节点、当前位置，处理点击。

signal node_chosen(index: int)

const RADIUS := 24.0
const TYPE_COLORS := {
	"战斗": Color("#C0564E"),
	"精英": Color("#A05AC0"),
	"休整": Color("#4E9E6A"),
	"首领": Color("#C9A227"),
}
const TYPE_ICONS := {"战斗": "战", "精英": "精", "休整": "休", "首领": "王"}
const LEGEND := [
	["战斗", "普通敌人"],
	["精英", "强化敌人：生命 ×1.5、攻击 +2"],
	["休整", "恢复生命，不进入战斗"],
	["首领", "最终决战，打赢即通关"],
]

var nodes: Array[Dictionary] = []
var edges: Array[Vector2i] = []
var current := -1
var reachable: Array[int] = []
var cleared: Array[bool] = []

var _positions: Array[Vector2] = []
var _labels: Array[Label] = []
var _title: Label
var _status: Label
var _hint: Label
var _message: Label
var _legend: VBoxContainer
var _time := 0.0
var _hover := -1
var _message_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_static_ui()
	_build_message()
	resized.connect(_layout)
	set_process(true)


func setup(p_nodes: Array[Dictionary], p_edges: Array[Vector2i]) -> void:
	nodes = p_nodes
	edges = p_edges
	_rebuild_labels()
	_layout()
	queue_redraw()


func set_state(p_current: int, p_reachable: Array[int], p_cleared: Array[bool], status_text: String) -> void:
	current = p_current
	reachable = p_reachable
	cleared = p_cleared
	if _status != null:
		_status.text = status_text
	_update_label_alpha()
	queue_redraw()


func show_message(text: String) -> void:
	if _message == null:
		return
	_message.text = text
	_message.modulate.a = 0.0
	if _message_tween != null and _message_tween.is_valid():
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_property(_message, "modulate:a", 1.0, 0.12)
	_message_tween.tween_interval(0.9)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.3)


func _process(delta: float) -> void:
	_time += delta
	if visible:
		queue_redraw()


# ---------------------------------------------------------------- 构建

func _build_static_ui() -> void:
	_title = Label.new()
	_title.text = "选择路线"
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0, 1.0))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 16)
	_status.add_theme_color_override("font_color", Color(0.72, 0.78, 0.9, 0.95))
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status)

	_hint = Label.new()
	_hint.text = "点击与当前位置相连的节点继续前进"
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.add_theme_color_override("font_color", Color(0.5, 0.57, 0.7, 0.9))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)

	_legend = VBoxContainer.new()
	_legend.add_theme_constant_override("separation", 10)
	_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_legend)
	for entry in LEGEND:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(12.0, 12.0)
		dot.color = TYPE_COLORS.get(entry[0], Color.WHITE)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(dot)
		var label := Label.new()
		label.text = "%s · %s" % [entry[0], entry[1]]
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.74, 0.79, 0.9, 0.92))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
		_legend.add_child(row)


func _build_message() -> void:
	_message = Label.new()
	_message.add_theme_font_size_override("font_size", 22)
	_message.add_theme_color_override("font_color", Color(1.0, 0.9, 0.65, 1.0))
	_message.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_message.add_theme_constant_override("outline_size", 4)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.modulate.a = 0.0
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_message)


func _rebuild_labels() -> void:
	for label in _labels:
		label.queue_free()
	_labels.clear()
	for node in nodes:
		var label := Label.new()
		label.text = String(TYPE_ICONS.get(String(node["type"]), "?"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		label.size = Vector2(RADIUS * 2.0, RADIUS * 2.0)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		_labels.append(label)


# ---------------------------------------------------------------- 布局

func _layout() -> void:
	_title.position = Vector2(60.0, 30.0)
	_title.size = Vector2(320.0, 44.0)
	_status.position = Vector2(size.x - 540.0, 40.0)
	_status.size = Vector2(480.0, 28.0)
	_hint.position = Vector2(0.0, size.y - 46.0)
	_hint.size = Vector2(size.x - 380.0, 24.0)
	_legend.position = Vector2(size.x - 360.0, 160.0)
	if _message != null:
		_message.position = Vector2(size.x * 0.5 - 300.0, size.y * 0.5 - 150.0)
		_message.size = Vector2(600.0, 36.0)

	if nodes.is_empty():
		return
	var max_floor := 0
	var max_col := 0
	for node in nodes:
		max_floor = maxi(max_floor, int(node["floor"]))
		max_col = maxi(max_col, int(node["col"]))
	var left := 100.0
	var right := maxf(left + 200.0, size.x - 400.0)
	var top := 150.0
	var bottom := size.y - 90.0

	_positions.clear()
	for node in nodes:
		var floor_ratio := float(node["floor"]) / float(maxi(1, max_floor))
		var col_ratio := (float(node["col"]) + 0.5) / float(max_col + 1)
		_positions.append(Vector2(lerpf(left, right, col_ratio), lerpf(bottom, top, floor_ratio)))
	for i in _labels.size():
		_labels[i].position = _positions[i] - Vector2(RADIUS, RADIUS)
	queue_redraw()


# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	# 不透明背景：盖住后面的战斗界面
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.045, 0.055, 0.075, 1.0))
	if _positions.size() != nodes.size():
		return
	for edge in edges:
		var from_pos: Vector2 = _positions[edge.x]
		var to_pos: Vector2 = _positions[edge.y]
		var color := Color(1.0, 1.0, 1.0, 0.1)
		if edge.x == current:
			color = Color(1.0, 0.84, 0.45, 0.5)
		draw_line(from_pos, to_pos, color, 2.0)

	for i in nodes.size():
		_draw_node(i)


func _draw_node(index: int) -> void:
	var pos: Vector2 = _positions[index]
	var node_type := String(nodes[index]["type"])
	var base: Color = TYPE_COLORS.get(node_type, Color.WHITE)
	var is_cleared: bool = index < cleared.size() and cleared[index]
	var is_current := index == current
	var is_reachable := reachable.has(index)

	var alpha := 1.0
	if is_cleared:
		alpha = 0.45
	elif not is_reachable and not is_current:
		alpha = 0.32

	if is_reachable:
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		draw_circle(pos, RADIUS + 5.0 + pulse * 4.0, Color(base.r, base.g, base.b, 0.16))

	draw_circle(pos, RADIUS, Color(base.r, base.g, base.b, alpha))
	draw_arc(pos, RADIUS, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.55 * alpha), 2.0)

	if is_current:
		draw_arc(pos, RADIUS + 5.0, 0.0, TAU, 40, Color(1.0, 0.9, 0.6, 0.95), 3.0)

	if index == _hover:
		draw_arc(pos, RADIUS + 8.0, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.45), 2.0)

	if is_cleared:
		draw_circle(pos + Vector2(RADIUS * 0.62, -RADIUS * 0.62), 6.0, Color(0.55, 0.9, 0.6, 0.9))


func _update_label_alpha() -> void:
	for i in _labels.size():
		var alpha := 1.0
		var is_cleared: bool = i < cleared.size() and cleared[i]
		if is_cleared:
			alpha = 0.5
		elif i != current and not reachable.has(i):
			alpha = 0.4
		_labels[i].modulate = Color(1.0, 1.0, 1.0, alpha)


# ---------------------------------------------------------------- 交互

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hovered := _node_at((event as InputEventMouseMotion).position)
		if hovered != _hover:
			_hover = hovered
			queue_redraw()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var index := _node_at(mb.position)
			if index < 0:
				return
			if reachable.has(index):
				node_chosen.emit(index)
			else:
				show_message("这个节点现在走不到")


func _node_at(point: Vector2) -> int:
	for i in _positions.size():
		if point.distance_to(_positions[i]) <= RADIUS + 6.0:
			return i
	return -1
