class_name Card
extends Control

## 一张卡牌。自己负责外观、悬停、拖拽；是否出牌、插到哪个位置由 Hand / Game 决定。

signal drag_started(card: Card)
signal drag_released(card: Card)
signal hover_changed(card: Card, hovered: bool)
signal double_clicked(card: Card)

const CARD_SIZE := Vector2(150.0, 210.0)

enum State { IN_HAND, DRAGGING, BUSY }

var data: CardData
var state: State = State.IN_HAND

var _bg: Panel
var _accent_bar: ColorRect
var _cost_badge: Panel
var _cost_label: Label
var _title_label: Label
var _kind_label: Label
var _desc_label: Label

var _move_tween: Tween
var _flash_tween: Tween
var _drag_offset := Vector2.ZERO
var _hovered := false


func _ready() -> void:
	size = CARD_SIZE
	custom_minimum_size = CARD_SIZE
	pivot_offset = CARD_SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	if data != null:
		_refresh_content()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## 由 Game 在实例化后调用，把卡牌数据塞进来。
func setup(p_data: CardData) -> void:
	data = p_data
	if is_node_ready():
		_refresh_content()


func _build_ui() -> void:
	_bg = Panel.new()
	_bg.name = "Background"
	_bg.position = Vector2.ZERO
	_bg.size = CARD_SIZE
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_accent_bar = ColorRect.new()
	_accent_bar.name = "AccentBar"
	_accent_bar.position = Vector2(12.0, 12.0)
	_accent_bar.size = Vector2(CARD_SIZE.x - 24.0, 4.0)
	_accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_accent_bar)

	_cost_badge = Panel.new()
	_cost_badge.name = "CostBadge"
	_cost_badge.position = Vector2(10.0, 24.0)
	_cost_badge.size = Vector2(34.0, 34.0)
	_cost_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cost_badge)

	_cost_label = _make_label("1", 18, Color(1.0, 1.0, 1.0, 1.0))
	_cost_label.name = "CostLabel"
	_cost_label.size = Vector2(34.0, 34.0)
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_badge.add_child(_cost_label)

	_title_label = _make_label("卡牌", 18, Color(0.95, 0.97, 1.0, 1.0))
	_title_label.name = "Title"
	_title_label.position = Vector2(52.0, 26.0)
	_title_label.size = Vector2(86.0, 26.0)
	add_child(_title_label)

	_kind_label = _make_label("技能", 12, Color(0.7, 0.76, 0.9, 1.0))
	_kind_label.name = "Kind"
	_kind_label.position = Vector2(12.0, 66.0)
	_kind_label.size = Vector2(126.0, 18.0)
	add_child(_kind_label)

	_desc_label = _make_label("", 13, Color(0.82, 0.86, 0.94, 1.0))
	_desc_label.name = "Description"
	_desc_label.position = Vector2(12.0, 92.0)
	_desc_label.size = Vector2(126.0, 104.0)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_child(_desc_label)


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _refresh_content() -> void:
	if _title_label == null:
		return
	_title_label.text = data.title
	_kind_label.text = data.kind
	_desc_label.text = data.description
	_cost_label.text = str(data.cost)
	_accent_bar.color = data.accent
	_kind_label.add_theme_color_override("font_color", data.accent)
	_refresh_style()


func _refresh_style() -> void:
	if data == null or _bg == null:
		return
	var accent: Color = data.accent
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.105, 0.125, 0.175, 1.0)
	style.border_color = accent.lightened(0.2) if _hovered else accent.darkened(0.2)
	style.set_border_width_all(3 if _hovered else 2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 10 if _hovered else 5
	style.shadow_offset = Vector2(0.0, 4.0)
	_bg.add_theme_stylebox_override("panel", style)

	var badge := StyleBoxFlat.new()
	badge.bg_color = accent.darkened(0.1)
	badge.set_corner_radius_all(17)
	badge.set_border_width_all(1)
	badge.border_color = accent.lightened(0.35)
	_cost_badge.add_theme_stylebox_override("panel", badge)


# ---------------------------------------------------------------- 输入

func _gui_input(event: InputEvent) -> void:
	if state != State.IN_HAND:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed and mb.double_click:
			double_clicked.emit(self)
			accept_event()
			return
		if mb.pressed:
			_begin_drag()
			accept_event()


func _begin_drag() -> void:
	state = State.DRAGGING
	_kill_move_tween()
	_set_hovered(false)
	_drag_offset = get_global_mouse_position() - global_position
	z_index = 300
	rotation = 0.0
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)
	drag_started.emit(self)


func _process(_delta: float) -> void:
	if state != State.DRAGGING:
		return
	global_position = get_global_mouse_position() - _drag_offset
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		state = State.IN_HAND
		drag_released.emit(self)


func _on_mouse_entered() -> void:
	if state == State.IN_HAND:
		_set_hovered(true)


func _on_mouse_exited() -> void:
	_set_hovered(false)


func _set_hovered(value: bool) -> void:
	if _hovered == value:
		return
	_hovered = value
	_refresh_style()
	hover_changed.emit(self, value)


# ---------------------------------------------------------------- 动画

func move_to(target_global: Vector2, target_rotation: float, target_scale: Vector2, animated := true, duration := 0.18) -> void:
	if state == State.DRAGGING:
		return
	_kill_move_tween()
	if not animated:
		global_position = target_global
		rotation = target_rotation
		scale = target_scale
		return
	_move_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "global_position", target_global, duration)
	_move_tween.tween_property(self, "rotation", target_rotation, duration)
	_move_tween.tween_property(self, "scale", target_scale, duration)


## 打出 / 弃掉：飞向牌堆并缩小淡出，结束后自毁。
func fly_to(target_center: Vector2, duration := 0.26) -> void:
	state = State.BUSY
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_kill_move_tween()
	z_index = 400
	var shrink := Vector2(0.18, 0.18)
	_move_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_move_tween.tween_property(self, "global_position", target_center - CARD_SIZE * 0.5 * shrink, duration)
	_move_tween.tween_property(self, "scale", shrink, duration)
	_move_tween.tween_property(self, "modulate:a", 0.0, duration)
	_move_tween.finished.connect(queue_free)


## 能量不足时闪红提示。
func flash_denied() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color(1.0, 0.45, 0.45, 1.0), 0.08)
	_flash_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)


func _kill_move_tween() -> void:
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
