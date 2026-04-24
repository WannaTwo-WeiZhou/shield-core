# 能力管理器，注册为 Autoload 单例 "AbilityManager"。
# 负责：加载定义、管理实例、生成候选、驱动管线与联动。
class_name AbilityManager
extends Node

## 候选生成完毕，需要显示三选一界面（Array[AbilityDefinition]）
signal ability_selection_needed(candidates: Array)
## 能力已获取或升级
signal ability_acquired(ability_id: String, level: int)
## 能力列表变更（UI 刷新用）
signal abilities_updated()

const CONFIG_PATH := "res://ability/abilities_config.json"

## id -> AbilityDefinition
var _definitions: Dictionary = {}
## id -> AbilityInstance
var _instances: Dictionary = {}

## 统一修饰器管线（外部可读取）
var pipeline: ModifierPipeline = ModifierPipeline.new()
var _synergy_resolver: SynergyResolver = SynergyResolver.new()

## 玩家节点引用（由 player.gd 注册）
var _player: Node = null


func _ready() -> void:
	_load_definitions()
	_synergy_resolver.load_config()


# ─── 加载 ────────────────────────────────────────────────────────────────────

func _load_definitions() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if not file:
		push_error("[AbilityManager] 无法打开 abilities_config.json")
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("[AbilityManager] 解析失败: %s" % json.get_error_message())
		file.close()
		return
	file.close()
	for entry in json.data.get("abilities", []):
		var def := AbilityDefinition.from_dict(entry)
		_definitions[def.id] = def
	print("[AbilityManager] 已加载 %d 个能力定义" % _definitions.size())


# ─── 升级三选一 ───────────────────────────────────────────────────────────────

## 由经验系统在升级时调用
func on_player_level_up(new_level: int) -> void:
	var candidates := _generate_candidates(3)
	print("[AbilityManager] Lv%d 升级候选: %s" % [
		new_level,
		candidates.map(func(d: AbilityDefinition) -> String: return d.id)
	])
	ability_selection_needed.emit(candidates)


# ─── 选择能力 ─────────────────────────────────────────────────────────────────

## 玩家从 UI 选择一个能力后调用
func select_ability(ability_id: String) -> void:
	if _instances.has(ability_id):
		var inst: AbilityInstance = _instances[ability_id]
		if not inst.is_maxed():
			inst.upgrade()
			print("[AbilityManager] 升级 %s → Lv%d" % [ability_id, inst.current_level])
			EventBus.on_ability_upgraded.emit(ability_id, inst.current_level)
	else:
		var def: AbilityDefinition = _definitions.get(ability_id, null)
		if def == null:
			push_error("[AbilityManager] 未知能力 id: %s" % ability_id)
			return
		var inst := AbilityInstance.new(def)
		_instances[ability_id] = inst
		print("[AbilityManager] 获得新能力: %s" % ability_id)
		EventBus.on_ability_acquired.emit(ability_id, 1)

	_rebuild_pipeline()
	var final_inst := get_instance(ability_id)
	ability_acquired.emit(ability_id, final_inst.current_level if final_inst else 1)
	abilities_updated.emit()


# ─── 查询 ─────────────────────────────────────────────────────────────────────

func get_instance(ability_id: String) -> AbilityInstance:
	return _instances.get(ability_id, null)


func has_ability(ability_id: String) -> bool:
	return _instances.has(ability_id)


func get_all_instances() -> Array:
	return _instances.values()


## 返回当前所有能力标签的扁平集合（去重）
func get_all_tags() -> Array:
	var tags: Array = []
	for inst: AbilityInstance in _instances.values():
		for tag in inst.definition.tags:
			if not tags.has(tag):
				tags.append(tag)
	return tags


func register_player(player: Node) -> void:
	_player = player


func get_player() -> Node:
	return _player


# ─── 内部：管线重建 ────────────────────────────────────────────────────────────

func _rebuild_pipeline() -> void:
	pipeline.reset()
	for inst: AbilityInstance in _instances.values():
		_apply_instance_to_pipeline(inst)
	_synergy_resolver.evaluate(get_all_tags(), pipeline, EventBus)
	print("[AbilityManager] 管线已重建 | 属性: %s | 活跃联动: %s" % [
		pipeline.debug_get_bonuses(),
		_synergy_resolver.get_active_synergies()
	])


func _apply_instance_to_pipeline(inst: AbilityInstance) -> void:
	var data := inst.get_current_data()
	# 数值属性（直接注册加成）
	for key in ["speed_bonus", "bullet_speed_bonus", "damage_bonus", "block_xp_bonus"]:
		if data.has(key):
			pipeline.add_attribute(key, float(data[key]))
	# 标签效果（供事件系统读取）
	for tag in inst.definition.affects_tags:
		pipeline.add_tag_effect(tag, {"ability_id": inst.get_id(), "data": data})


# ─── 内部：候选生成 ────────────────────────────────────────────────────────────

func _generate_candidates(count: int) -> Array:
	var pool := _build_candidate_pool()
	if pool.is_empty():
		return []
	var selected: Array = []
	var remaining := pool.duplicate()
	for _i in range(mini(count, remaining.size())):
		var total_weight := 0
		for entry in remaining:
			total_weight += entry["weight"]
		if total_weight <= 0:
			break
		var roll := randi() % total_weight
		var cumulative := 0
		for j in range(remaining.size()):
			cumulative += remaining[j]["weight"]
			if roll < cumulative:
				selected.append(remaining[j]["def"])
				remaining.remove_at(j)
				break
	return selected


func _build_candidate_pool() -> Array:
	var pool: Array = []
	for def: AbilityDefinition in _definitions.values():
		var inst: AbilityInstance = _instances.get(def.id, null)
		if inst == null or not inst.is_maxed():
			var w := def.weight
			if inst != null:
				# 已拥有但未满级：降低权重，避免升级选项垄断候选池
				w = int(w * 0.6)
			pool.append({"def": def, "weight": w})
	return pool
