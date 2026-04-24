# 玩家实际持有的能力实例，记录当前等级与运行时状态。
class_name AbilityInstance
extends RefCounted

var definition: AbilityDefinition
var current_level: int = 1


func _init(def: AbilityDefinition) -> void:
	definition = def
	current_level = 1


func is_maxed() -> bool:
	return current_level >= definition.max_level


## 升级，若已满级则忽略
func upgrade() -> void:
	if not is_maxed():
		current_level += 1


## 当前等级的效果数据
func get_current_data() -> Dictionary:
	return definition.get_level_data(current_level)


func has_tag(tag: String) -> bool:
	return definition.has_tag(tag)


func get_id() -> String:
	return definition.id
