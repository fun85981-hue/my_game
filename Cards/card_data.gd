class_name CardData
extends Resource

## 单张卡牌的数据定义。只保存数据，不持有任何节点，方便以后换成卡表 / 存档。

@export var id: StringName = &""
@export var title: String = "未知卡牌"
@export var description: String = ""
@export var cost: int = 1
@export var kind: String = "技能"
@export var accent: Color = Color("#7aa2f7")

# ---- 战斗效果 ----
@export var damage: int = 0        # 对敌方造成的伤害
@export var block: int = 0         # 给自己加的格挡
@export var draw: int = 0          # 抽牌数
@export var energy_gain: int = 0   # 立即获得的能量
@export var vulnerable: int = 0    # 给敌方施加的易伤层数
@export var strength: int = 0      # 获得的力量（提高攻击牌伤害）
@export var energy_per_turn: int = 0  # 能力：每回合额外能量

func is_power() -> bool:
	return kind == "能力"
