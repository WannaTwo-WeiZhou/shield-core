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
var per_level: Array = []    # Array[Dictionary]，每级的效果数据


## 从配置字典初始化自身（实例方法，避免 GDScript static 自引用编译问题）
func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	display_name = data.get("name", "")
	description = data.get("description", "")
	rarity = data.get("rarity", 1)
	weight = data.get("weight", 100)
	max_level = data.get("max_level", 1)
	repeatable = data.get("repeatable", false)
	if data.has("per_level"):
		per_level = data.get("per_level", [])


## 返回指定等级（1-based）的效果字典
func get_level_data(level: int) -> Dictionary:
	if per_level.is_empty():
		return {}
	var idx := clampi(level - 1, 0, per_level.size() - 1)
	return per_level[idx]


func rarity_label() -> String:
	match rarity:
		1: return "普通"
		2: return "稀有"
		3: return "史诗"
	return "未知"
