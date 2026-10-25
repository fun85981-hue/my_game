class_name PileUI
extends Control

## 牌堆 / 弃牌堆的通用外观：叠起来的一摞牌 + 数量 + 点击信号。

signal pressed

@export var title: String = "牌堆":
	set(value):
		title = value
		if is_node_ready() and _title_label != null:
			_title_label.text = value

@export var hint: String = "":
	set(value):
		hint = value
		if is_node_ready() and _hint_label != null:
			_hint_label.text = value

@export var accent: Color = Color("#7aa2f7"):
	set(value):
		accent = value
		if is_node_ready():
			queue_redraw()

var count: int = 0:
	set(value):
		count = value
		if is_node_ready() and _count_label != null:
			_count_label.text = str(value)
			queue_redraw()

var _title_label: Label
var _count_label: Label
var _hint_label: Label
var _bump_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_labels()
	resized.connect(_layout_labels)
	_layout_labels()
	queue_redraw()


func center_global() -> Vector2:
	return get_global_rect().get_center()


func bump() -> void:
	if _bump_tween != null and _bump_tween.is_valid():
		_bump_tween.kill()
	scale = Vector2.ONE
	_bump_tween = create_tween()
	_bump_tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.07)
	_bump_tween.tween_property(self, "scale", Vector2.ONE, 0.11)


func _build_labels() -> void:
	_title_label = _make_label(title, 15, Color(0.72, 0.78, 0.9, 1.0))
	add_child(_title_label)
	_count_label = _make_label(str(count), 34, Color(0.93, 0.95, 1.0, 1.0))
	add_child(_count_label)
	_hint_label = _make_label(hint, 12, Color(0.55, 0.62, 0.74, 0.95))
	add_child(_hint_label)


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _layout_labels() -> void:
	if _title_label == null:
		return
	pivot_offset = size * 0.5
	_title_label.position = Vector2(0.0, 8.0)
	_title_label.size = Vector2(size.x, 22.0)
	_count_label.position = Vector2(0.0, size.y * 0.5 - 28.0)
	_count_label.size = Vector2(size.x, 52.0)
	_hint_label.position = Vector2(0.0, size.y - 26.0)
	_hint_label.size = Vector2(size.x, 20.0)


func _draw() -> void:
	var layers := clampi(count, 0, 3)
	var empty := count <= 0
	for i in range(layers, -1, -1):
		var offset := Vector2(-4.0 * float(i), -4.0 * float(i))
		draw_style_box(_stack_style(i, empty), Rect2(offset, size))
	if not empty:
		var inner := Rect2(Vector2(9.0, 9.0), size - Vector2(18.0, 18.0))
		draw_rect(inner, Color(accent.r, accent.g, accent.b, 0.2), false, 1.5)


func _stack_style(depth: int, empty: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(12)
	style.set_border_width_all(2)
	if empty:
		style.bg_color = Color(0.1, 0.12, 0.16, 0.55)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.22)
	else:
		var shade := 0.155 - float(depth) * 0.025
		style.bg_color = Color(shade, shade * 1.12, shade * 1.55, 1.0)
		style.border_color = Color(accent.r, accent.g, accent.b, 0.5 - float(depth) * 0.08)
	return style


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and not mb.double_click:
			pressed.emit()
			accept_event()
