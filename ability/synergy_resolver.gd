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
func evaluate(all_tags: Array, pipeline: ModifierPipeline, event_bus: Node) -> void:
	_active_synergy_ids.clear()
	for syn in _synergy_defs:
		var required: Array = syn.get("required_tags", [])
		if _tags_satisfied(required, all_tags):
			_active_synergy_ids.append(syn["id"])
			_apply_synergy(syn, pipeline)
			event_bus.on_synergy_activated.emit(syn["id"])
			print("[SYNERGY] 激活: %s — %s" % [syn["id"], syn.get("description", "")])


func is_active(synergy_id: String) -> bool:
	return _active_synergy_ids.has(synergy_id)


func get_active_synergies() -> Array:
	return _active_synergy_ids.duplicate()


func _tags_satisfied(required: Array, available: Array) -> bool:
	for tag in required:
		if not available.has(tag):
			return false
	return not required.is_empty()


func _apply_synergy(syn: Dictionary, pipeline: ModifierPipeline) -> void:
	var effect: Dictionary = syn.get("effect", {})
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
		_:
			pass
