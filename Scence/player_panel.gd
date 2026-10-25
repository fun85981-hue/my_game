class_name PlayerPanel
extends Control

## 玩家状态：角色名 + 生命条 + 护甲（格挡）数值 + 角色被动说明。

var hp := 80
var max_hp := 80
var block := 0

var character_name := "战士"
var passive_text := ""
var accent := Color("#C97B4A")

var _name_label: Label
var _hp_text: Label
var _block_label: Label
var _passive_label: Label


func _ready() -> void:
	_name_label = _make_label(character_name, 16, accent)
	_name_label.position = Vector2(18.0, 4.0)
	_name_label.size = Vector2(130.0, 24.0)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_name_label)

	_hp_text = _make_label("", 15, Color(0.95, 0.96, 1.0, 1.0))
	_hp_text.position = Vector2(150.0, 4.0)
	_hp_text.size = Vector2(132.0, 24.0)
	_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_hp_text)

	_block_label = _make_label("", 14, Color(0.55, 0.8, 1.0, 1.0))
	_block_label.position = Vector2(18.0, 50.0)
	_block_label.size = Vector2(96.0, 20.0)
	_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_block_label)

	_passive_label = _make_label("", 10, Color(0.55, 0.62, 0.75, 0.95))
	_passive_label.position = Vector2(108.0, 50.0)
	_passive_label.size = Vector2(174.0, 20.0)
	_passive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_passive_label)

	set_character(character_name, passive_text, accent)
	set_state(hp, max_hp, block)


func set_character(p_name: String, p_passive: String, p_accent: Color) -> void:
	character_name = p_name
	passive_text = p_passive
	accent = p_accent
	if is_node_ready() and _name_label != null:
		_name_label.text = character_name
		_name_label.add_theme_color_override("font_color", accent)
		_passive_label.text = passive_text
		queue_redraw()


func set_state(p_hp: int, p_max_hp: int, p_block: int) -> void:
	hp = p_hp
	max_hp = p_max_hp
	block = p_block
	if is_node_ready() and _hp_text != null:
		_hp_text.text = "%d / %d" % [hp, max_hp]
		_block_label.text = "格挡 %d" % block
		_block_label.add_theme_color_override(
			"font_color",
			Color(0.55, 0.8, 1.0, 1.0) if block > 0 else Color(0.44, 0.5, 0.62, 0.75)
		)
	queue_redraw()


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _draw() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.09, 0.11, 0.15, 0.9)
	bg.set_corner_radius_all(12)
	bg.set_border_width_all(2)
	bg.border_color = Color(accent.r, accent.g, accent.b, 0.45)
	draw_style_box(bg, Rect2(Vector2.ZERO, size))

	var bar := Rect2(Vector2(18.0, 32.0), Vector2(size.x - 36.0, 12.0))
	draw_rect(bar, Color(0.06, 0.07, 0.1, 1.0))
	var ratio := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	if ratio > 0.0:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color(0.86, 0.33, 0.36, 1.0))
	draw_rect(bar, Color(1.0, 1.0, 1.0, 0.15), false, 1.0)
