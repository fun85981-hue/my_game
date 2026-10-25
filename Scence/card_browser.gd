class_name CardBrowser
extends Control

## 牌堆 / 弃牌堆的查看窗口：按给定顺序列出卡牌，点击空白、关闭按钮或 Esc 退出。

signal closed

var _cards: Array[CardData] = []

var _dim: ColorRect
var _panel: Panel
var _title: Label
var _subtitle: Label
var _list: VBoxContainer
var _scroll: ScrollContainer


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()


## 打开窗口。cards 的顺序就是显示顺序（第一张在最上面）。
func open(title_text: String, subtitle_text: String, cards: Array[CardData], empty_text: String) -> void:
	_cards = cards.duplicate()
	_title.text = title_text
	_subtitle.text = subtitle_text
	for child in _list.get_children():
		child.queue_free()
	if _cards.is_empty():
		var empty := _make_label(empty_text, 15, Color(0.55, 0.6, 0.72, 0.9))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(0.0, 48.0)
		_list.add_child(empty)
	else:
		for i in _cards.size():
			_list.add_child(_make_row(i, _cards[i]))
	visible = true
	modulate.a = 0.0
	_scroll.scroll_vertical = 0
	var rows := maxi(_cards.size(), 1)
	var panel_height := clampf(150.0 + float(rows) * 62.0, 320.0, 600.0)
	_panel.offset_top = -panel_height * 0.5
	_panel.offset_bottom = panel_height * 0.5
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.15)


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func current_cards() -> Array[CardData]:
	return _cards


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and (key.keycode == KEY_ESCAPE or key.keycode == KEY_Q):
			close()
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- 构建界面

func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.0, 0.65)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -440.0
	_panel.offset_top = -270.0
	_panel.offset_right = 440.0
	_panel.offset_bottom = 270.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.075, 0.09, 0.13, 0.98)
	panel_style.set_corner_radius_all(16)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.32, 0.42, 0.62, 0.55)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	panel_style.shadow_size = 18
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 18)
	_panel.add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 8)
	margin.add_child(root_box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	root_box.add_child(header)

	_title = _make_label("", 24, Color(0.94, 0.96, 1.0, 1.0))
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_child(_title)

	var close_button := Button.new()
	close_button.text = "关闭 (Esc)"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 15)
	close_button.pressed.connect(close)
	header.add_child(close_button)

	_subtitle = _make_label("", 13, Color(0.58, 0.65, 0.78, 0.95))
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root_box.add_child(_subtitle)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_box.add_child(_scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	_scroll.add_child(_list)


func _make_row(index: int, data: CardData) -> Control:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.105, 0.125, 0.18, 1.0)
	style.set_corner_radius_all(8)
	style.border_width_left = 4
	style.border_color = data.accent
	style.content_margin_left = 12.0
	style.content_margin_top = 8.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 8.0

	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", style)
	row.custom_minimum_size = Vector2(0.0, 54.0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(box)

	var order := _make_label("%02d" % (index + 1), 13, Color(0.45, 0.5, 0.62, 0.9))
	order.custom_minimum_size = Vector2(28.0, 0.0)
	order.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(order)

	var cost := _make_label(str(data.cost), 17, data.accent)
	cost.custom_minimum_size = Vector2(22.0, 0.0)
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cost)

	var name_label := _make_label(data.title, 16, Color(0.94, 0.96, 1.0, 1.0))
	name_label.custom_minimum_size = Vector2(110.0, 0.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(name_label)

	var desc := _make_label(data.description, 13, Color(0.62, 0.68, 0.8, 0.95))
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(desc)

	var kind := _make_label(data.kind, 12, Color(0.5, 0.56, 0.68, 0.9))
	kind.custom_minimum_size = Vector2(46.0, 0.0)
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(kind)

	return row


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			close()
			accept_event()
