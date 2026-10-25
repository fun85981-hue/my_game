class_name Hand
extends Control

## 手牌区：只负责“卡片摆在哪、什么角度、谁在最上面”。
## 卡牌节点本身挂在 CardLayer 下（保证渲染在所有 UI 之上），这里按全局坐标摆放。

const GAP_MAX := 104.0
const GAP_MIN := 46.0
const ARC_HEIGHT := 18.0
const ANGLE_STEP := 3.0
const HOVER_LIFT := 46.0
const HOVER_SCALE := 1.12
const BOTTOM_MARGIN := 10.0

var cards: Array[Card] = []
var hovered: Card = null


func insert_card(card: Card) -> void:
	if cards.has(card):
		return
	cards.append(card)
	card.state = Card.State.IN_HAND
	card.hover_changed.connect(_on_card_hover_changed)
	relayout()


func remove_card(card: Card) -> void:
	if not cards.has(card):
		return
	cards.erase(card)
	if hovered == card:
		hovered = null
	relayout()


## 拖拽松手后放回手牌：按松手时的水平位置决定插到第几张。
func return_card(card: Card) -> void:
	if not cards.has(card):
		return
	var index := _drop_index(card)
	cards.erase(card)
	cards.insert(clampi(index, 0, cards.size()), card)
	relayout()


func relayout() -> void:
	var count := cards.size()
	if count == 0:
		return
	var rect := get_global_rect()
	var gap := GAP_MAX
	if count > 1:
		gap = clampf((rect.size.x - Card.CARD_SIZE.x) / float(count - 1) - 10.0, GAP_MIN, GAP_MAX)
	var total_width := Card.CARD_SIZE.x + gap * float(count - 1)
	var start_x := rect.get_center().x - total_width * 0.5
	var base_y := rect.end.y - Card.CARD_SIZE.y - BOTTOM_MARGIN - ARC_HEIGHT

	for i in count:
		var card: Card = cards[i]
		if card.state == Card.State.DRAGGING:
			continue
		var offset := float(i) - float(count - 1) * 0.5
		var norm := 0.0
		if count > 1:
			norm = absf(offset) / (float(count - 1) * 0.5)
		var target := Vector2(start_x + gap * float(i), base_y + norm * norm * ARC_HEIGHT)
		var target_rotation := deg_to_rad(offset * ANGLE_STEP)
		var target_scale := Vector2.ONE
		if card == hovered:
			target.y -= HOVER_LIFT
			target_rotation = 0.0
			target_scale = Vector2(HOVER_SCALE, HOVER_SCALE)
			card.z_index = 100
		else:
			card.z_index = 10 + i
		card.move_to(target, target_rotation, target_scale)


func _drop_index(card: Card) -> int:
	var x := card.global_position.x + Card.CARD_SIZE.x * 0.5
	var index := 0
	for other in cards:
		if other == card:
			continue
		if other.global_position.x + Card.CARD_SIZE.x * 0.5 < x:
			index += 1
	return index


func _on_card_hover_changed(card: Card, is_hovered: bool) -> void:
	if is_hovered:
		hovered = card
	elif hovered == card:
		hovered = null
	relayout()
