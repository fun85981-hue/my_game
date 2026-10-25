extends Control

## 主流程：分支地图 → 选择节点 → 战斗 / 休整 → 回到地图，直到击败首领。
## 卡牌、角色、关卡、地图数值分别来自 data/ 下的四张表。

const CARD_SCENE := preload("res://Cards/Cards.tscn")

@onready var hand: Hand = $Hand
@onready var card_layer: Control = $CardLayer
@onready var draw_pile: PileUI = $DrawPile
@onready var discard_pile: PileUI = $DiscardPile
@onready var graveyard_pile: PileUI = $GraveyardPile
@onready var enemy: Enemy = $Enemy
@onready var player_panel: PlayerPanel = $PlayerPanel
@onready var fx_layer: Control = $FxLayer
@onready var hurt_flash: ColorRect = $HurtFlash
@onready var turn_label: Label = $TopBar/TurnLabel
@onready var level_label: Label = $TopBar/LevelLabel
@onready var energy_label: Label = $TopBar/EnergyLabel
@onready var end_turn_button: Button = $TopBar/EndTurnButton
@onready var toast: Label = $Toast
@onready var overlay: Control = $Overlay
@onready var overlay_title: Label = $Overlay/Center/Title
@onready var overlay_subtitle: Label = $Overlay/Center/Subtitle
@onready var restart_button: Button = $Overlay/Center/RestartButton
@onready var browser: CardBrowser = $CardBrowser
@onready var map_view: MapView = $MapView
@onready var menu_view: MenuView = $MenuView
@onready var reward_view: RewardView = $RewardView

var deck: Array[CardData] = []
var discard: Array[CardData] = []
var graveyard: Array[CardData] = []
var run_deck: Array[CardData] = []
var energy := 0
var turn := 0
var busy := false
var game_over := false
var player_hp := 80
var player_block := 0
var end_turn_block := 0
var strength := 0
var bonus_energy := 0
var character_name := "战士"
var character_description := ""

var max_hand := 10
var hand_size := 5
var max_energy := 3
var max_hp := 80
var rest_heal := 25

var map_nodes: Array[Dictionary] = []
var map_edges: Array[Vector2i] = []
var map_cleared: Array[bool] = []
var current_node := -1
var active_node := -1

var selected_character: Dictionary = {}
var selected_difficulty: Dictionary = {}
var battle_levels: Array[Dictionary] = []

var _toast_tween: Tween
var _overlay_action := "restart"


func _ready() -> void:
	randomize()
	GameData.load_all()
	max_hand = GameData.int_setting("手牌上限", 10)
	rest_heal = GameData.int_setting("休整回复", 25)

	overlay.visible = false
	draw_pile.pressed.connect(_on_draw_pile_pressed)
	discard_pile.pressed.connect(_on_discard_pile_pressed)
	graveyard_pile.pressed.connect(_on_graveyard_pile_pressed)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

	map_nodes = MapData.nodes()
	map_edges = MapData.build_edges(map_nodes)
	map_cleared.resize(map_nodes.size())
	map_cleared.fill(false)
	map_view.setup(map_nodes, map_edges)
	map_view.node_chosen.connect(_on_map_node_chosen)
	map_view.visible = false

	reward_view.chosen.connect(_on_reward_chosen)
	reward_view.skipped.connect(_on_reward_skipped)
	reward_view.visible = false

	menu_view.setup(GameData.characters(), GameData.difficulties())
	menu_view.start_requested.connect(_on_start_requested)
	menu_view.visible = true
	_refresh_player()


## 主界面点「开始游戏」后：应用角色与难度，重置一局，进入地图。
func _on_start_requested(character_index: int, difficulty_index: int) -> void:
	var all_characters := GameData.characters()
	var all_difficulties := GameData.difficulties()
	if all_characters.is_empty() or all_difficulties.is_empty():
		return
	selected_character = all_characters[clampi(character_index, 0, all_characters.size() - 1)]
	selected_difficulty = all_difficulties[clampi(difficulty_index, 0, all_difficulties.size() - 1)]
	battle_levels = GameData.levels(String(selected_difficulty.get("name", "")))

	max_hp = int(selected_character.get("max_hp", 80))
	max_energy = int(selected_character.get("energy", 3))
	end_turn_block = int(selected_character.get("end_turn_block", 0))
	character_name = String(selected_character.get("name", "角色"))
	character_description = String(selected_character.get("description", ""))
	hand_size = int(selected_character.get("start_hand", 5))
	player_hp = max_hp
	player_block = 0
	run_deck = CardLibrary.deck_for(selected_character)
	player_panel.set_character(character_name, character_description, Color(String(selected_character.get("accent", "#C97B4A"))))
	_refresh_player()

	map_cleared.fill(false)
	current_node = -1
	active_node = -1
	menu_view.visible = false
	print("开局：%s · 难度 %s · 牌组 %d 张 · %d 层" % [
		character_name, _difficulty_name(), CardLibrary.deck_for(selected_character).size(), battle_levels.size(),
	])
	_open_map()


func _difficulty_name() -> String:
	return String(selected_difficulty.get("name", ""))


# ---------------------------------------------------------------- 地图流程

func _open_map() -> void:
	busy = false
	game_over = false
	map_view.visible = true
	_refresh_map()


func _refresh_map() -> void:
	var reachable := _reachable_nodes()
	var status := "%s · 难度 %s · 生命 %d / %d · 牌组 %d 张" % [
		character_name, _difficulty_name(), player_hp, max_hp, CardLibrary.deck_for(selected_character).size(),
	]
	map_view.set_state(current_node, reachable, map_cleared, status)


func _reachable_nodes() -> Array[int]:
	var result: Array[int] = []
	if current_node < 0:
		var lowest := 9999
		for node in map_nodes:
			lowest = mini(lowest, int(node["floor"]))
		for i in map_nodes.size():
			if int(map_nodes[i]["floor"]) == lowest:
				result.append(i)
		return result
	for edge in map_edges:
		if edge.x == current_node:
			result.append(edge.y)
	return result


func _on_map_node_chosen(index: int) -> void:
	if busy or game_over or map_view.visible == false:
		return
	if not _reachable_nodes().has(index):
		return
	var node := map_nodes[index]
	if String(node["type"]) == "休整":
		_rest_at(index)
	else:
		_begin_battle(index)


func _rest_at(index: int) -> void:
	var healed := mini(max_hp, player_hp + rest_heal) - player_hp
	player_hp += healed
	current_node = index
	map_cleared[index] = true
	_refresh_player()
	map_view.show_message("休整：恢复 %d 点生命" % healed)
	_refresh_map()


func _begin_battle(index: int) -> void:
	active_node = index
	var node := map_nodes[index]
	var node_type := String(node["type"])
	if battle_levels.is_empty():
		push_warning("没有可用的关卡数值，无法开始战斗")
		return
	var floor_index := clampi(int(node["floor"]), 0, battle_levels.size() - 1)
	var config: Dictionary = battle_levels[floor_index].duplicate(true)

	var prefix := ""
	if node_type == "精英":
		config["hp"] = int(round(float(config["hp"]) * 1.5))
		var boosted: Array[int] = []
		for value in config["pattern"]:
			boosted.append(int(value) + 2)
		config["pattern"] = boosted
		prefix = "精英·"
	elif node_type == "首领":
		prefix = "首领·"
	config["name"] = prefix + String(config.get("name", "敌人"))

	map_view.visible = false
	game_over = false
	_start_battle(config, node_type)


func _start_battle(config: Dictionary, node_type: String) -> void:
	enemy.configure(config)
	strength = 0
	bonus_energy = 0
	_reset_piles()
	player_block = 0
	turn = 0
	energy = 0
	_refresh()
	_refresh_player()
	level_label.text = "第 %d 层 · %s" % [int(map_nodes[active_node]["floor"]) + 1, node_type]
	await get_tree().process_frame
	await start_turn()


func _reset_piles() -> void:
	for card in hand.cards:
		card.queue_free()
	hand.cards.clear()
	hand.hovered = null
	discard.clear()
	graveyard.clear()
	deck.clear()
	deck.assign(run_deck)
	deck.shuffle()
	_refresh()


# ---------------------------------------------------------------- 回合流程

func start_turn() -> void:
	if game_over:
		return
	turn += 1
	energy = max_energy + bonus_energy
	player_block = 0
	_refresh()
	_refresh_player()
	if turn > 1:
		_toast("你的回合")
	await get_tree().process_frame
	for _i in hand_size:
		if not draw_card():
			break
		await get_tree().create_timer(0.07).timeout


func end_turn() -> void:
	if busy or game_over:
		return
	busy = true
	end_turn_button.disabled = true
	while not hand.cards.is_empty():
		var card: Card = hand.cards[0]
		hand.remove_card(card)
		discard.append(card.data)
		card.fly_to(discard_pile.center_global(), 0.2)
		discard_pile.bump()
		await get_tree().create_timer(0.05).timeout
	_refresh()
	await get_tree().create_timer(0.2).timeout
	if game_over:
		busy = false
		return
	_apply_end_turn_passive()
	await get_tree().create_timer(0.3).timeout
	if game_over:
		busy = false
		return
	await _enemy_turn()
	if game_over:
		busy = false
		return
	await start_turn()
	busy = false
	end_turn_button.disabled = false


## 角色被动：每个玩家回合结束时给自己加护甲（战士）。
func _apply_end_turn_passive() -> void:
	if end_turn_block <= 0:
		return
	player_block += end_turn_block
	_refresh_player()
	_popup(player_panel.global_position + Vector2(330.0, 22.0), "+%d 护甲" % end_turn_block, Color(0.55, 0.8, 1.0))


func _enemy_turn() -> void:
	_toast("敌方回合")
	enemy.set_intent_visible(false)
	await get_tree().create_timer(0.45).timeout
	if game_over:
		return
	var incoming := enemy.current_intent()
	await enemy.lunge()
	if game_over:
		return
	_damage_player(incoming)
	if game_over:
		return
	await get_tree().create_timer(0.4).timeout
	enemy.advance_intent()
	enemy.tick_vulnerable()
	enemy.set_intent_visible(true)
	await get_tree().create_timer(0.15).timeout


# ---------------------------------------------------------------- 牌堆

func draw_card() -> bool:
	if hand.cards.size() >= max_hand:
		_toast("手牌已满（%d 张）" % max_hand)
		return false
	if deck.is_empty() and not _reshuffle_discard():
		_toast("牌堆和弃牌堆都空了")
		return false
	var data: CardData = deck.pop_front()
	var card := CARD_SCENE.instantiate() as Card
	card_layer.add_child(card)
	card.setup(data)
	card.drag_started.connect(_on_card_drag_started)
	card.drag_released.connect(_on_card_drag_released)
	card.double_clicked.connect(_on_card_double_clicked)
	card.global_position = draw_pile.center_global() - Card.CARD_SIZE * 0.5
	card.scale = Vector2(0.6, 0.6)
	hand.insert_card(card)
	draw_pile.bump()
	_refresh()
	return true


func _reshuffle_discard() -> bool:
	if discard.is_empty():
		return false
	deck.append_array(discard)
	discard.clear()
	deck.shuffle()
	_refresh()
	_toast("弃牌堆已洗回牌堆")
	return true


# ---------------------------------------------------------------- 出牌与结算

func play_card(card: Card) -> void:
	if card == null or game_over or busy or map_view.visible:
		return
	if card.state == Card.State.BUSY:
		return
	if energy < card.data.cost:
		card.flash_denied()
		_toast("能量不足，需要 %d 点" % card.data.cost)
		hand.relayout()
		return
	energy -= card.data.cost
	var is_power := card.data.is_power()
	hand.remove_card(card)
	if is_power:
		graveyard.append(card.data)
		card.fly_to(graveyard_pile.center_global())
		graveyard_pile.bump()
	else:
		discard.append(card.data)
		card.fly_to(discard_pile.center_global())
		discard_pile.bump()
	_refresh()
	_apply_card_effects(card.data)


func _apply_card_effects(data: CardData) -> void:
	if data.damage > 0:
		_damage_enemy(data.damage + strength)
	if data.vulnerable > 0:
		enemy.apply_vulnerable(data.vulnerable)
	if data.block > 0:
		player_block += data.block
		_refresh_player()
	if data.energy_gain > 0:
		energy += data.energy_gain
		_refresh()
	if data.draw > 0:
		for _i in data.draw:
			draw_card()
	if data.strength > 0:
		strength += data.strength
		_refresh()
		_popup(player_panel.global_position + Vector2(330.0, 22.0), "+%d 力量" % data.strength, Color(1.0, 0.78, 0.45))
	if data.energy_per_turn > 0:
		bonus_energy += data.energy_per_turn
		_refresh()
		_popup(player_panel.global_position + Vector2(330.0, 58.0), "每回合 +%d 能量" % data.energy_per_turn, Color(0.7, 0.65, 0.95))


func _damage_enemy(amount: int) -> void:
	if enemy.hp <= 0:
		return
	var final_damage := amount
	if enemy.vulnerable_turns > 0:
		final_damage = int(ceil(float(amount) * 1.5))
	enemy.take_damage(final_damage)
	_popup(enemy.global_position + Vector2(196.0, 96.0), "-%d" % final_damage, Color(1.0, 0.62, 0.55))
	if enemy.hp <= 0:
		_handle_victory()


func _damage_player(amount: int) -> void:
	var absorbed := mini(player_block, amount)
	var lost := amount - absorbed
	player_block -= absorbed
	player_hp = maxi(0, player_hp - lost)
	_refresh_player()
	if absorbed > 0:
		_popup(player_panel.global_position + Vector2(330.0, 6.0), "格挡 %d" % absorbed, Color(0.55, 0.8, 1.0))
	if lost > 0:
		_popup(player_panel.global_position + Vector2(330.0, 40.0), "-%d" % lost, Color(1.0, 0.5, 0.45))
		_flash_hurt()
	if player_hp <= 0:
		_handle_defeat()


func _is_play_drop(card: Card) -> bool:
	var center := card.global_position + Card.CARD_SIZE * 0.5 * card.scale
	return center.y < hand.get_global_rect().position.y - 60.0


# ---------------------------------------------------------------- 胜负

func _handle_victory() -> void:
	if game_over:
		return
	game_over = true
	busy = true
	end_turn_button.disabled = true
	enemy.play_death()
	await get_tree().create_timer(0.55).timeout
	if active_node < 0:
		_overlay_action = "restart"
		_show_overlay("战斗胜利", "", "重新开始", Color(0.72, 1.0, 0.72))
		return

	var node := map_nodes[active_node]
	var node_type := String(node["type"])
	map_cleared[active_node] = true
	current_node = active_node

	if node_type == "首领":
		_overlay_action = "restart"
		_show_overlay("通关！", "你击败了首领，完成本次冒险", "重新开始", Color(0.92, 0.95, 0.7))
	else:
		reward_view.open(CardLibrary.reward_pool(selected_character), run_deck.size())


## 选牌完成：加入本局牌组并回到地图。
func _on_reward_chosen(card: CardData) -> void:
	run_deck.append(card)
	_finish_reward("获得卡牌：%s" % card.title)


func _on_reward_skipped() -> void:
	_finish_reward("跳过奖励")


func _finish_reward(message: String) -> void:
	reward_view.visible = false
	game_over = false
	busy = false
	end_turn_button.disabled = false
	_open_map()
	map_view.show_message(message)


func _handle_defeat() -> void:
	if game_over:
		return
	game_over = true
	busy = true
	end_turn_button.disabled = true
	_overlay_action = "restart"
	await get_tree().create_timer(0.6).timeout
	var where := "未知位置"
	if active_node >= 0:
		var node := map_nodes[active_node]
		where = "第 %d 层 · %s" % [int(node["floor"]) + 1, String(node["type"])]
	_show_overlay("你倒下了", "倒在" + where, "重新开始", Color(1.0, 0.5, 0.5))


func _show_overlay(title: String, subtitle: String, button_text: String, color: Color) -> void:
	overlay_title.text = title
	overlay_title.add_theme_color_override("font_color", color)
	overlay_subtitle.text = subtitle
	restart_button.text = button_text
	overlay.visible = true
	overlay.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(overlay, "modulate:a", 1.0, 0.3)


func _on_restart_pressed() -> void:
	if _overlay_action == "map":
		overlay.visible = false
		game_over = false
		busy = false
		end_turn_button.disabled = false
		_open_map()
	else:
		get_tree().reload_current_scene()


# ---------------------------------------------------------------- 表现

func _popup(at: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = at - Vector2(40.0, 0.0)
	fx_layer.add_child(label)
	var start_y := label.position.y
	var t := create_tween().set_parallel(true)
	t.tween_property(label, "position:y", start_y - 48.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.3)
	t.finished.connect(label.queue_free)


func _flash_hurt() -> void:
	hurt_flash.color = Color(0.85, 0.15, 0.15, 0.0)
	var t := create_tween()
	t.tween_property(hurt_flash, "color:a", 0.25, 0.06)
	t.tween_property(hurt_flash, "color:a", 0.0, 0.3)


# ---------------------------------------------------------------- 信号

func _on_card_drag_started(_card: Card) -> void:
	pass


func _on_card_drag_released(card: Card) -> void:
	if _is_play_drop(card):
		play_card(card)
	else:
		hand.return_card(card)


func _on_card_double_clicked(card: Card) -> void:
	play_card(card)


func _on_end_turn_pressed() -> void:
	end_turn()


func _on_draw_pile_pressed() -> void:
	if busy or game_over:
		return
	browser.open("牌堆（剩余 %d 张）" % deck.size(), "从上到下为接下来的抽牌顺序", deck, "牌堆是空的")


func _on_discard_pile_pressed() -> void:
	if game_over:
		return
	var newest_first: Array[CardData] = []
	newest_first.assign(discard)
	newest_first.reverse()
	browser.open("弃牌堆（%d 张）" % discard.size(), "最新弃掉的牌排在最上面", newest_first, "弃牌堆是空的")


func _on_graveyard_pile_pressed() -> void:
	if game_over:
		return
	var newest_first: Array[CardData] = []
	newest_first.assign(graveyard)
	newest_first.reverse()
	browser.open("坟场（%d 张）" % graveyard.size(), "本场战斗消耗的能力牌，不会回到牌堆", newest_first, "坟场是空的")


# ---------------------------------------------------------------- 输入 / 界面

func _unhandled_input(event: InputEvent) -> void:
	if browser.visible or map_view.visible:
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		if key.keycode == KEY_SPACE:
			end_turn()


func _refresh() -> void:
	draw_pile.count = deck.size()
	discard_pile.count = discard.size()
	discard_pile.hint = "点击查看" if discard.is_empty() else "牌顶 " + String(discard.back().title)
	graveyard_pile.count = graveyard.size()
	graveyard_pile.hint = "点击查看" if graveyard.is_empty() else "能力已生效"
	turn_label.text = "回合 %d" % turn
	var energy_text := "能量 %d / %d" % [energy, max_energy + bonus_energy]
	if strength > 0:
		energy_text += " · 力量 %d" % strength
	energy_label.text = energy_text


func _refresh_player() -> void:
	player_panel.set_state(player_hp, max_hp, player_block)


func _toast(message: String) -> void:
	toast.text = message
	toast.modulate.a = 0.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast, "modulate:a", 1.0, 0.12)
	_toast_tween.tween_interval(0.9)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.35)
