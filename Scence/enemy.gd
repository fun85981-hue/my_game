class_name Enemy
extends Control

## 敌对单位：血量 + 攻击力，带血条、意图提示、受击 / 攻击 / 死亡动画。
## 每一关通过 configure() 换成不同的敌人。

@export var display_name := "腐化史莱姆"
@export var max_hp := 60
@export var attack_power := 8
@export var attack_pattern: Array[int] = [8, 8, 14]
@export var body_color := Color("#7b5cd6")
@export var body_scale := 1.0

var hp := 60
var vulnerable_turns := 0

var _pattern_index := 0
var _intent_damage := 8
var _intent_visible := true
var _dead := false
var _time := 0.0

var _name_label: Label
var _intent_label: Label
var _hp_label: Label
var _vuln_label: Label
var _death_tween: Tween


func _ready() -> void:
	size = Vector2(240.0, 260.0)
	pivot_offset = size * 0.5
	hp = max_hp
	_intent_damage = attack_pattern[0] if not attack_pattern.is_empty() else 8
	_build_labels()
	refresh_labels()
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if not _dead:
		queue_redraw()


# ---------------------------------------------------------------- 关卡配置

## 用关卡表里的一条配置重置敌人（血量、攻击循环、外观全部换新）。
func configure(config: Dictionary) -> void:
	if _death_tween != null and _death_tween.is_valid():
		_death_tween.kill()
	display_name = String(config.get("name", "敌人"))
	max_hp = int(config.get("hp", 60))
	attack_pattern.clear()
	for value in config.get("pattern", [8]):
		attack_pattern.append(int(value))
	body_color = Color(config.get("color", "#7b5cd6"))
	body_scale = float(config.get("scale", 1.0))
	_pattern_index = 0
	_intent_damage = attack_pattern[0] if not attack_pattern.is_empty() else 8
	vulnerable_turns = 0
	hp = max_hp
	_dead = false
	visible = true
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	scale = Vector2.ONE
	_intent_visible = true
	if _name_label != null:
		_name_label.text = display_name
	refresh_labels()
	queue_redraw()


# ---------------------------------------------------------------- 对外接口

func current_intent() -> int:
	return _intent_damage


func set_intent(damage: int) -> void:
	_intent_damage = damage
	refresh_labels()


func advance_intent() -> void:
	if attack_pattern.is_empty():
		return
	_pattern_index = (_pattern_index + 1) % attack_pattern.size()
	set_intent(attack_pattern[_pattern_index])


func set_intent_visible(value: bool) -> void:
	_intent_visible = value
	refresh_labels()


func tick_vulnerable() -> void:
	if vulnerable_turns > 0:
		vulnerable_turns -= 1
		refresh_labels()
		queue_redraw()


func apply_vulnerable(stacks: int) -> void:
	vulnerable_turns += stacks
	refresh_labels()
	queue_redraw()


func take_damage(amount: int) -> void:
	if _dead:
		return
	hp = maxi(0, hp - amount)
	refresh_labels()
	queue_redraw()
	_punch()
	if hp <= 0:
		_dead = true


func lunge() -> void:
	var base := position
	var t := create_tween()
	t.tween_property(self, "position:y", base.y + 56.0, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(self, "position:y", base.y, 0.26).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await t.finished


func play_death() -> void:
	_dead = true
	_death_tween = create_tween().set_parallel(true)
	_death_tween.tween_property(self, "modulate:a", 0.0, 0.45)
	_death_tween.tween_property(self, "scale", Vector2(0.7, 0.7), 0.45)


func refresh_labels() -> void:
	if _hp_label == null:
		return
	_hp_label.text = "%d / %d" % [hp, max_hp]
	_vuln_label.text = "易伤 %d" % vulnerable_turns if vulnerable_turns > 0 else ""
	_intent_label.visible = _intent_visible
	_intent_label.text = "意图：攻击 %d" % _intent_damage if _intent_visible else ""


# ---------------------------------------------------------------- 内部

func _build_labels() -> void:
	_name_label = _make_label(display_name, 14, Color(0.62, 0.68, 0.8, 0.9))
	_name_label.position = Vector2(0.0, 2.0)
	_name_label.size = Vector2(240.0, 20.0)
	add_child(_name_label)

	_intent_label = _make_label("", 16, Color(1.0, 0.7, 0.38, 1.0))
	_intent_label.position = Vector2(0.0, 28.0)
	_intent_label.size = Vector2(240.0, 24.0)
	add_child(_intent_label)

	_hp_label = _make_label("", 13, Color(0.92, 0.94, 1.0, 1.0))
	_hp_label.position = Vector2(0.0, 196.0)
	_hp_label.size = Vector2(240.0, 18.0)
	add_child(_hp_label)

	_vuln_label = _make_label("", 13, Color(0.95, 0.55, 0.85, 1.0))
	_vuln_label.position = Vector2(0.0, 214.0)
	_vuln_label.size = Vector2(240.0, 18.0)
	add_child(_vuln_label)


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _punch() -> void:
	var flash := create_tween()
	modulate = Color(1.9, 1.6, 1.6, 1.0)
	flash.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)
	var squash := create_tween()
	squash.tween_property(self, "scale", Vector2(1.06, 0.94), 0.06)
	squash.tween_property(self, "scale", Vector2.ONE, 0.12)


func _draw() -> void:
	if _dead:
		return
	var dark := body_color.darkened(0.38)
	var bob := sin(_time * 2.2) * 3.0
	var center := Vector2(size.x * 0.5, 108.0 + bob)

	# 影子
	draw_set_transform(Vector2(size.x * 0.5, 164.0), 0.0, Vector2(1.0, 0.26))
	draw_circle(Vector2.ZERO, 54.0 * body_scale, Color(0.0, 0.0, 0.0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 身体与五官都画在缩放后的局部坐标里，换体型时整体一致
	draw_set_transform(center, 0.0, Vector2(body_scale, body_scale * 0.94))
	draw_circle(Vector2.ZERO, 52.0, body_color)
	draw_circle(Vector2(-14.0, -16.0), 20.0, Color(1.0, 1.0, 1.0, 0.1))
	draw_arc(Vector2.ZERO, 51.0, 0.0, TAU, 48, dark, 3.0)

	var eye_y := -8.0
	for side: float in [-1.0, 1.0]:
		var ex := side * 20.0
		draw_circle(Vector2(ex, eye_y), 12.0, Color("#f4f2ff"))
		draw_circle(Vector2(ex + side * 2.0, eye_y + 2.0), 5.5, Color(0.12, 0.08, 0.2))
		var outer := Vector2(ex + side * 12.0, eye_y - 18.0)
		var inner := Vector2(ex - side * 12.0, eye_y - 9.0)
		draw_line(outer, inner, dark, 4.0)

	draw_line(Vector2(-12.0, 24.0), Vector2(12.0, 24.0), Color(0.15, 0.08, 0.22), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 血条
	var bar := Rect2(Vector2(20.0, 180.0), Vector2(size.x - 40.0, 14.0))
	draw_rect(bar, Color(0.06, 0.07, 0.1, 1.0))
	var ratio := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	if ratio > 0.0:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), Color(0.85, 0.32, 0.34, 1.0))
	draw_rect(bar, Color(1.0, 1.0, 1.0, 0.18), false, 1.0)
