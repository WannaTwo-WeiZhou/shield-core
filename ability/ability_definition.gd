# 能力的静态定义，从 abilities_config.json 加载。
# 只保存数据，不包含运行时逻辑（当前能力固定为单级）。
class_name AbilityDefinition
extends RefCounted

var id: String = ""
var display_name: String = ""
var description: String = ""
var rarity: int = 1          # 1=普通 2=稀有 3=史诗
var weight: int = 100        # 候选池权重
var max_level: int = 1
var repeatable: bool = false
var tags: Array = []         # 例如 ["shield", "attribute"]
var affects_tags: Array = [] # 本能力影响哪些标签的行为
var responds_to_tags: Array = [] # 本能力响应哪些标签事件
var per_level: Array = []    # Array[Dictionary]，每级的效果数据


static func from_dict(data: Dictionary) -> AbilityDefinition:
	var def := AbilityDefinition.new()
	def.id = data.get("id", "")
	def.display_name = data.get("name", "")
	def.description = data.get("description", "")
	def.rarity = data.get("rarity", 1)
	def.weight = data.get("weight", 100)
	def.max_level = data.get("max_level", 1)
	def.repeatable = data.get("repeatable", false)
	def.tags = data.get("tags", [])
	def.affects_tags = data.get("affects_tags", [])
	def.responds_to_tags = data.get("responds_to_tags", [])
	def.per_level = data.get("per_level", [])
	return def


## 返回指定等级（1-based）的效果字典
func get_level_data(level: int) -> Dictionary:
	if per_level.is_empty():
		return {}
	var idx := clampi(level - 1, 0, per_level.size() - 1)
	return per_level[idx]


func has_tag(tag: String) -> bool:
	return tags.has(tag)


func rarity_label() -> String:
	match rarity:
		1: return "普通"
		2: return "稀有"
		3: return "史诗"
	return "未知"
