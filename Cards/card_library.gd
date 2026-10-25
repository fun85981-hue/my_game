class_name CardLibrary

## 卡组来自人物表的「起始牌组」列（cards.xlsx 里的卡牌 ID:数量）。
## 只会把「通用」卡和该角色的专属卡放进牌组，其它角色的专属卡会被跳过并提示。

static func starter_deck() -> Array[CardData]:
	return deck_for(GameData.character())


static func deck_for(hero: Dictionary) -> Array[CardData]:
	var hero_id := String(hero.get("id", ""))
	var catalog := GameData.cards_by_id()
	var deck: Array[CardData] = []

	for entry in hero.get("deck", []):
		var card_id := String(entry.get("id", ""))
		var count := int(entry.get("count", 1))
		if not catalog.has(card_id):
			push_warning("起始牌组：卡牌 ID「%s」在 cards.xlsx 里不存在，已跳过" % card_id)
			continue
		var definition: Dictionary = catalog[card_id]
		if not _is_allowed(definition, hero_id):
			push_warning("起始牌组：卡牌「%s」是 %s 专属，%s 不能使用，已跳过" % [
				card_id, String(definition.get("owner", "通用")), hero_id,
			])
			continue
		for _i in maxi(0, count):
			deck.append(_to_card_data(definition))
	return deck


## 战斗胜利后的奖励池：通用卡 + 该角色专属卡。
static func reward_pool(hero: Dictionary) -> Array[CardData]:
	var hero_id := String(hero.get("id", ""))
	var pool: Array[CardData] = []
	for definition in GameData.cards():
		if _is_allowed(definition, hero_id):
			pool.append(_to_card_data(definition))
	return pool


static func make_card(definition: Dictionary) -> CardData:
	return _to_card_data(definition)


static func _is_allowed(definition: Dictionary, hero_id: String) -> bool:
	var owner := String(definition.get("owner", "通用"))
	return owner == "" or owner == "通用" or owner == hero_id


static func _to_card_data(definition: Dictionary) -> CardData:
	var data := CardData.new()
	data.id = StringName(String(definition.get("id", "")))
	data.title = String(definition.get("title", "卡牌"))
	data.kind = String(definition.get("kind", "技能"))
	data.cost = int(definition.get("cost", 1))
	data.description = String(definition.get("description", ""))
	data.accent = Color(String(definition.get("accent", "#7AA2F7")))
	data.damage = int(definition.get("damage", 0))
	data.block = int(definition.get("block", 0))
	data.draw = int(definition.get("draw", 0))
	data.energy_gain = int(definition.get("energy_gain", 0))
	data.vulnerable = int(definition.get("vulnerable", 0))
	data.strength = int(definition.get("strength", 0))
	data.energy_per_turn = int(definition.get("energy_per_turn", 0))
	return data
