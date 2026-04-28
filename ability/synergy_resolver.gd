# 联动解析器：检测玩家当前持有能力的 ID 组合，激活对应联动效果。
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


## 根据玩家当前已获得能力重新评估联动，将生效的效果注册进 pipeline 并发射信号
func evaluate(owned_instances: Dictionary, pipeline: ModifierPipeline, event_bus: Node) -> void:
	_active_synergy_ids.clear()
	for syn in _synergy_defs:
		if _synergy_matches(syn, owned_instances):
			_active_synergy_ids.append(syn["id"])
			_apply_synergy(syn, pipeline)
			event_bus.on_synergy_activated.emit(syn["id"])
			print("[SYNERGY] 激活: %s — %s" % [syn["id"], syn.get("description", "")])


func is_active(synergy_id: String) -> bool:
	return _active_synergy_ids.has(synergy_id)


func get_active_synergies() -> Array:
	return _active_synergy_ids.duplicate()


func _synergy_matches(syn: Dictionary, owned_instances: Dictionary) -> bool:
	var required_abilities: Array = syn.get("required_abilities", [])
	if required_abilities.is_empty():
		return false
	return _abilities_satisfied(required_abilities, owned_instances)


func _abilities_satisfied(required: Array, owned_instances: Dictionary) -> bool:
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
