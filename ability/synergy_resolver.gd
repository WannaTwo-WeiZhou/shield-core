# 联动解析器：检测玩家当前持有能力的标签组合，激活对应联动效果。
# 联动规则来自 synergies_config.json，新联动只需添加配置，无需修改代码。
class_name SynergyResolver
extends RefCounted

const CONFIG_PATH := "res://ability/synergies_config.json"

var _synergy_defs: Array = []
var _active_synergy_ids: Array = []


func load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if not file:
		push_error("[SynergyResolver] 无法打开 synergies_config.json")
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("[SynergyResolver] 解析失败: %s" % json.get_error_message())
		file.close()
		return
	file.close()
	_synergy_defs = json.data.get("synergies", [])
	print("[SynergyResolver] 加载联动规则 %d 条" % _synergy_defs.size())


## 根据玩家当前标签集重新评估联动，将生效的效果注册进 pipeline 并发射信号
func evaluate(all_tags: Array, owned_instances: Dictionary, pipeline: ModifierPipeline, event_bus: Node) -> void:
	_active_synergy_ids.clear()
	for syn in _synergy_defs:
		if _synergy_matches(syn, all_tags, owned_instances):
			_active_synergy_ids.append(syn["id"])
			_apply_synergy(syn, pipeline)
			event_bus.on_synergy_activated.emit(syn["id"])
			print("[SYNERGY] 激活: %s — %s" % [syn["id"], syn.get("description", "")])


func is_active(synergy_id: String) -> bool:
	return _active_synergy_ids.has(synergy_id)


func get_active_synergies() -> Array:
	return _active_synergy_ids.duplicate()


func _synergy_matches(syn: Dictionary, all_tags: Array, owned_instances: Dictionary) -> bool:
	var required_abilities: Array = syn.get("required_abilities", [])
	var required_tags: Array = syn.get("required_tags", [])

	var condition_matched := false
	# ID 条件优先，标签条件兜底（兼容旧配置）
	if not required_abilities.is_empty():
		condition_matched = _abilities_satisfied(required_abilities, owned_instances)
	elif not required_tags.is_empty():
		condition_matched = _tags_satisfied(required_tags, all_tags)
	else:
		return false

	if not condition_matched:
		return false

	return true


func _tags_satisfied(required: Array, available: Array) -> bool:
	if required.is_empty():
		return false  # 无约束的联动不应自动激活，需至少声明一个条件标签
	for tag in required:
		if not available.has(tag):
			return false
	return true


func _abilities_satisfied(required: Array, owned_instances: Dictionary) -> bool:
	if required.is_empty():
		return false
	for ability_id in required:
		if not owned_instances.has(ability_id):
			return false
	return true


func _apply_synergy(syn: Dictionary, pipeline: ModifierPipeline) -> void:
	var effects: Array = []
	if syn.has("effects"):
		effects = syn.get("effects", [])
	else:
		var legacy_effect: Dictionary = syn.get("effect", {})
		if not legacy_effect.is_empty():
			effects = [legacy_effect]

	for effect: Dictionary in effects:
		_apply_effect(syn, effect, pipeline)


func _apply_effect(syn: Dictionary, effect: Dictionary, pipeline: ModifierPipeline) -> void:
	match effect.get("type", ""):
		"tag_enhance":
			# 向某个标签的效果链添加增强标记，供战斗结算读取
			pipeline.add_tag_effect(
				effect.get("target_tag", ""),
				{"type": "enhance", "add_tags": effect.get("add_tags", []), "synergy_id": syn["id"]}
			)
		"attribute_bonus":
			pipeline.add_attribute(
				effect.get("attribute", ""),
				float(effect.get("bonus", 0))
			)
		"runtime_flag":
			pipeline.add_runtime_flag(
				effect.get("flag", ""),
				{
					"synergy_id": syn.get("id", ""),
					"params": effect.get("params", {})
				}
			)
		"event_modifier":
			var event_name: String = effect.get("event", "")
			var modifier := effect.duplicate(true)
			modifier.erase("type")
			modifier.erase("event")
			modifier["synergy_id"] = syn.get("id", "")
			pipeline.add_event_modifier(event_name, modifier)
		_:
			push_warning("[SynergyResolver] 未知 effect type: %s (synergy: %s)" % [
				effect.get("type", ""),
				syn.get("id", "unknown")
			])
