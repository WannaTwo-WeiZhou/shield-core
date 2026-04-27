# 玩家实际持有的能力实例，记录当前等级与运行时状态。
class_name AbilityInstance
extends RefCounted

var definition: AbilityDefinition
var current_level: int = 1  # 保留字段兼容旧 UI/事件，固定为 1
var stack_count: int = 1    # 重复获得次数，普通能力固定为 1


func _init(def: AbilityDefinition) -> void:
	definition = def
	current_level = 1
	stack_count = 1


func is_maxed() -> bool:
	return true


## 等级系统已移除，保留空实现以兼容旧调用
func upgrade() -> void:
	return


## 能力为唯一实例，始终读取第一级效果
func get_current_data() -> Dictionary:
	return definition.get_level_data(1)


func add_stack() -> void:
	stack_count += 1


func get_stack_count() -> int:
	return stack_count


func has_tag(tag: String) -> bool:
	return definition.has_tag(tag)


func get_id() -> String:
	return definition.id
