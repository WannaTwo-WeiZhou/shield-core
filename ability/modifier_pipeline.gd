# 统一修饰器/效果管线。
# 所有能力将自己的效果注册到此处，战斗系统查询此处而不直接询问某个能力。
# 每次能力变化后由 AbilityManager 重建（reset → 重新注册）。
class_name ModifierPipeline
extends RefCounted

## 数值属性加成：attribute_name -> 累计加成值
var _attribute_bonuses: Dictionary = {}

## 标签效果列表：tag -> Array[Dictionary]
## 供联动系统或战斗结算读取
var _tag_effects: Dictionary = {}

## 运行时效果注册表：effect_type -> Array[Dictionary]
## 用于承载联动注入的行为修饰（如事件修饰器、运行时标记）
var _runtime_effects: Dictionary = {}


func reset() -> void:
	_attribute_bonuses.clear()
	_tag_effects.clear()
	_runtime_effects.clear()


## 注册属性加成（可叠加）
func add_attribute(attribute: String, value: float) -> void:
	_attribute_bonuses[attribute] = _attribute_bonuses.get(attribute, 0.0) + value


## 查询属性总加成（不存在返回 0）
func get_attribute(attribute: String) -> float:
	return _attribute_bonuses.get(attribute, 0.0)


## 注册标签效果（供事件/联动读取）
func add_tag_effect(tag: String, effect: Dictionary) -> void:
	if not _tag_effects.has(tag):
		_tag_effects[tag] = []
	_tag_effects[tag].append(effect)


## 查询某标签下所有效果
func get_tag_effects(tag: String) -> Array:
	return _tag_effects.get(tag, [])


## 查询某标签下指定类型的所有效果（简化联动查询）
func get_tag_effects_by_type(tag: String, effect_type: String) -> Array:
	return get_tag_effects(tag).filter(func(e: Dictionary) -> bool: return e.get("type", "") == effect_type)


## 检查某标签下是否存在指定类型效果
func has_tag_effect(tag: String, effect_type: String) -> bool:
	for eff in get_tag_effects(tag):
		if eff.get("type", "") == effect_type:
			return true
	return false


## 注册运行时效果（按 effect_type 分组）
func add_runtime_effect(effect_type: String, effect: Dictionary) -> void:
	if effect_type.is_empty():
		return
	if not _runtime_effects.has(effect_type):
		_runtime_effects[effect_type] = []
	_runtime_effects[effect_type].append(effect)


## 查询某类运行时效果
func get_runtime_effects(effect_type: String) -> Array:
	return _runtime_effects.get(effect_type, [])


## 注册运行时标记（常用于开启某个融合/套装状态）
func add_runtime_flag(flag: String, payload: Dictionary = {}) -> void:
	if flag.is_empty():
		return
	var effect := {"flag": flag}
	for key in payload.keys():
		effect[key] = payload[key]
	add_runtime_effect("runtime_flag", effect)


func has_runtime_flag(flag: String) -> bool:
	for effect in get_runtime_effects("runtime_flag"):
		if effect.get("flag", "") == flag:
			return true
	return false


## 注册事件修饰器（供 on_block / on_reflect 等统一消费）
func add_event_modifier(event_name: String, modifier: Dictionary) -> void:
	if event_name.is_empty():
		return
	var payload := modifier.duplicate()
	payload["event"] = event_name
	add_runtime_effect("event_modifier", payload)


func get_event_modifiers(event_name: String) -> Array:
	return get_runtime_effects("event_modifier").filter(
		func(effect: Dictionary) -> bool:
			return effect.get("event", "") == event_name
	)


## 调试用：返回当前属性加成字典（不直接暴露私有字段）
func debug_get_bonuses() -> Dictionary:
	return _attribute_bonuses.duplicate()


func debug_get_runtime_effects() -> Dictionary:
	return _runtime_effects.duplicate(true)


## 调试用：打印当前状态
func debug_print() -> void:
	print("[ModifierPipeline] Attributes: ", _attribute_bonuses)
	print("[ModifierPipeline] Tag effects: ", _tag_effects.keys())
	print("[ModifierPipeline] Runtime effects: ", _runtime_effects.keys())
