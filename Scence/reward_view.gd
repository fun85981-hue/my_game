class_name RewardView
extends Control

## 战斗胜利后的选牌界面：从奖励池随机三张，选一张加入本局牌组，或跳过。

signal chosen(card: CardData)
signal skipped

const CARD_SIZE := Vector2(240.0, 320.0)

var _cards: Array[CardData] = []
var _title: Label
var _subtitle: Label
var _row: HBoxContainer
var _skip_button: Button
var _hint: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_title = _label("战斗胜利！选择一张卡牌加入牌组", 30, Color("#E8B168"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)

	_subtitle = _label("", 15, Color(0.62, 0.68, 0.8, 0.95))
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_subtitle)

	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 24)
	add_child(_row)

	_skip_button = Button.new()
	_skip_button.text = "跳过奖励"
	_skip_button.focus_mode = Control.FOCUS_NONE
	_skip_button.add_theme_font_size_override("font_size", 17)
	_skip_button.add_theme_color_override("font_color", Color(0.9, 0.92, 0.98, 1.0))
	_skip_button.add_theme_stylebox_override("normal", _plain_style())
	_skip_button.add_theme_stylebox_override("hover", _plain_style(true))
	_skip_button.add_theme_stylebox_override("pressed", _plain_style())
	_skip_button.pressed.connect(func() -> void: skipped.emit())
	add_child(_skip_button)

	_hint = _label("选中的卡牌会加入本局牌组，之后每场战斗都会抽到", 12, Color(0.45, 0.5, 0.62, 0.9))
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)

	resized.connect(_layout)


func open(pool: Array[CardData], deck_size: int) -> void:
	var shuffled := pool.duplicate()
	shuffled.shuffle()
	_cards.clear()
	for i in mini(3, shuffled.size()):
		_cards.append(shuffled[i])

	for child in _row.get_children():
		child.queue_free()
	for i in _cards.size():
		_row.add_child(_make_card_button(_cards[i], i))

	_subtitle.text = "当前牌组 %d 张 · 从下面三张里选一张" % deck_size
	visible = true
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)
	_layout()


func _make_card_button(data: CardData, index: int) -> Button:
	var accent: Color = data.accent
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _card_style(accent, false))
	button.add_theme_stylebox_override("hover", _card_style(accent, true))
	button.add_theme_stylebox_override("pressed", _card_style(accent, false))
	button.pressed.connect(func() -> void: chosen.emit(_cards[index]))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)

	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	head.add_child(_label(str(data.cost), 26, accent))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(spacer)
	head.add_child(_label(data.kind, 13, Color(0.62, 0.68, 0.8, 0.95)))

	box.add_child(_label(data.title, 22, Color(0.95, 0.97, 1.0, 1.0)))

	var desc := _label(data.description, 14, Color(0.78, 0.83, 0.92, 0.95))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(desc)

	var pick := _label("点击选择", 12, Color(0.55, 0.62, 0.75, 0.9))
	pick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(pick)

	return button


func _card_style(accent: Color, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.13, 0.18, 1.0) if not hovered else Color(0.14, 0.17, 0.23, 1.0)
	style.set_corner_radius_all(14)
	style.set_border_width_all(3 if hovered else 2)
	style.border_color = accent.lightened(0.15) if hovered else accent.darkened(0.1)
	return style


func _plain_style(hovered := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.18, 0.24, 1.0) if hovered else Color(0.11, 0.13, 0.18, 1.0)
	style.set_corner_radius_all(10)
	style.set_border_width_all(1)
	style.border_color = Color(0.35, 0.42, 0.55, 0.7)
	return style


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _layout() -> void:
	_title.position = Vector2(0.0, 74.0)
	_title.size = Vector2(size.x, 44.0)
	_subtitle.position = Vector2(0.0, 122.0)
	_subtitle.size = Vector2(size.x, 24.0)

	_row.size = _row.get_combined_minimum_size()
	_row.position = Vector2((size.x - _row.size.x) * 0.5, 172.0)

	_skip_button.position = Vector2((size.x - 220.0) * 0.5, 540.0)
	_skip_button.size = Vector2(220.0, 48.0)

	_hint.position = Vector2(0.0, size.y - 44.0)
	_hint.size = Vector2(size.x, 20.0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.045, 0.055, 0.075, 1.0))
