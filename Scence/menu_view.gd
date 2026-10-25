class_name MenuView
extends Control

## 主界面：选择角色 + 选择难度，点击开始进入地图。

signal start_requested(character_index: int, difficulty_index: int)

var characters: Array[Dictionary] = []
var difficulties: Array[Dictionary] = []

var _character_index := 0
var _difficulty_index := 0

var _title: Label
var _subtitle: Label
var _char_header: Label
var _diff_header: Label
var _footer: Label
var _char_row: HBoxContainer
var _diff_row: HBoxContainer
var _start_button: Button
var _character_buttons: Array[Button] = []
var _difficulty_buttons: Array[Button] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_static()
	resized.connect(_layout)
	_layout()


func setup(p_characters: Array[Dictionary], p_difficulties: Array[Dictionary]) -> void:
	characters = p_characters
	difficulties = p_difficulties
	_build_character_cards()
	_build_difficulty_cards()
	_layout()
	_update_selection()


# ---------------------------------------------------------------- 构建

func _build_static() -> void:
	_title = _label("ROGUE LIKE", 52, Color("#E8B168"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)

	_subtitle = _label("选择角色与难度，开始一局冒险", 17, Color(0.6, 0.66, 0.8, 0.95))
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_subtitle)

	_char_header = _label("选择角色", 18, Color(0.82, 0.86, 0.95, 0.95))
	_char_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_char_header)

	_char_row = HBoxContainer.new()
	_char_row.add_theme_constant_override("separation", 20)
	add_child(_char_row)

	_diff_header = _label("选择难度", 18, Color(0.82, 0.86, 0.95, 0.95))
	_diff_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_diff_header)

	_diff_row = HBoxContainer.new()
	_diff_row.add_theme_constant_override("separation", 20)
	add_child(_diff_row)

	_start_button = Button.new()
	_start_button.text = "开始游戏"
	_start_button.focus_mode = Control.FOCUS_NONE
	_start_button.add_theme_font_size_override("font_size", 20)
	_start_button.add_theme_color_override("font_color", Color(0.98, 0.97, 0.94, 1.0))
	_start_button.pressed.connect(_on_start_pressed)
	add_child(_start_button)

	_footer = _label("数值来自 data/ 下的四张表 · 修改后重新运行即可生效", 12, Color(0.45, 0.5, 0.62, 0.9))
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_footer)


func _build_character_cards() -> void:
	for child in _char_row.get_children():
		child.queue_free()
	_character_buttons.clear()
	for i in characters.size():
		var hero := characters[i]
		var accent := Color(String(hero.get("accent", "#C97B4A")))
		var button := _make_card(Vector2(300.0, 176.0))
		button.pressed.connect(_on_character_pressed.bind(i))

		var box := _card_box(button)
		box.add_child(_label(String(hero.get("name", "角色")), 26, accent))
		box.add_child(_label("生命 %d · 每回合能量 %d" % [
			int(hero.get("max_hp", 80)), int(hero.get("energy", 3)),
		], 14, Color(0.86, 0.89, 0.96, 1.0)))

		var passive := _label(String(hero.get("description", "")), 13, Color(0.62, 0.68, 0.8, 0.95))
		passive.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		passive.custom_minimum_size = Vector2(264.0, 40.0)
		box.add_child(passive)

		box.add_child(_label("初始牌组 %d 张 · 回合结束护甲 %d" % [
			CardLibrary.deck_for(hero).size(), int(hero.get("end_turn_block", 0)),
		], 12, Color(0.5, 0.56, 0.68, 0.95)))

		_char_row.add_child(button)
		_character_buttons.append(button)


func _build_difficulty_cards() -> void:
	for child in _diff_row.get_children():
		child.queue_free()
	_difficulty_buttons.clear()
	for i in difficulties.size():
		var difficulty := difficulties[i]
		var accent := Color(String(difficulty.get("color", "#7FBF7F")))
		var button := _make_card(Vector2(260.0, 96.0))
		button.pressed.connect(_on_difficulty_pressed.bind(i))

		var box := _card_box(button)
		box.add_theme_constant_override("separation", 4)
		box.add_child(_label(String(difficulty.get("name", "难度")), 20, accent))
		var desc := _label(String(difficulty.get("description", "")), 12, Color(0.6, 0.66, 0.78, 0.95))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(desc)

		_diff_row.add_child(button)
		_difficulty_buttons.append(button)


func _make_card(min_size: Vector2) -> Button:
	var button := Button.new()
	button.custom_minimum_size = min_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 1)
	return button


func _card_box(button: Button) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)
	return box


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


# ---------------------------------------------------------------- 布局

func _layout() -> void:
	_title.position = Vector2(0.0, 46.0)
	_title.size = Vector2(size.x, 66.0)
	_subtitle.position = Vector2(0.0, 116.0)
	_subtitle.size = Vector2(size.x, 26.0)

	_char_header.position = Vector2(0.0, 172.0)
	_char_header.size = Vector2(size.x, 24.0)
	_char_row.size = _char_row.get_combined_minimum_size()
	_char_row.position = Vector2((size.x - _char_row.size.x) * 0.5, 204.0)

	_diff_header.position = Vector2(0.0, 424.0)
	_diff_header.size = Vector2(size.x, 24.0)
	_diff_row.size = _diff_row.get_combined_minimum_size()
	_diff_row.position = Vector2((size.x - _diff_row.size.x) * 0.5, 456.0)

	_start_button.position = Vector2((size.x - 300.0) * 0.5, 594.0)
	_start_button.size = Vector2(300.0, 56.0)

	_footer.position = Vector2(0.0, size.y - 32.0)
	_footer.size = Vector2(size.x, 20.0)


# ---------------------------------------------------------------- 选择

func _on_character_pressed(index: int) -> void:
	_character_index = index
	_update_selection()


func _on_difficulty_pressed(index: int) -> void:
	_difficulty_index = index
	_update_selection()


func _update_selection() -> void:
	for i in _character_buttons.size():
		var accent := Color(String(characters[i].get("accent", "#C97B4A")))
		_apply_card_style(_character_buttons[i], accent, i == _character_index)
	for i in _difficulty_buttons.size():
		var accent := Color(String(difficulties[i].get("color", "#7FBF7F")))
		_apply_card_style(_difficulty_buttons[i], accent, i == _difficulty_index)
	var accent := Color("#E8B168")
	if _difficulty_index < difficulties.size():
		accent = Color(String(difficulties[_difficulty_index].get("color", "#E8B168")))
	_start_button.add_theme_stylebox_override("normal", _button_style(accent, true))
	_start_button.add_theme_stylebox_override("hover", _button_style(accent.lightened(0.15), true))
	_start_button.add_theme_stylebox_override("pressed", _button_style(accent.darkened(0.15), true))


func _apply_card_style(button: Button, accent: Color, selected: bool) -> void:
	button.add_theme_stylebox_override("normal", _button_style(accent, selected, false))
	button.add_theme_stylebox_override("hover", _button_style(accent, selected, true))
	button.add_theme_stylebox_override("pressed", _button_style(accent, selected, false))


func _button_style(accent: Color, selected: bool, hovered := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var base := 0.10 if not selected else 0.15
	if hovered:
		base += 0.02
	style.bg_color = Color(base, base * 1.15, base * 1.55, 1.0)
	style.set_corner_radius_all(14)
	style.set_border_width_all(3 if selected else 1)
	style.border_color = accent if selected else Color(0.3, 0.36, 0.48, 0.65)
	return style


func _on_start_pressed() -> void:
	start_requested.emit(_character_index, _difficulty_index)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.045, 0.055, 0.075, 1.0))
