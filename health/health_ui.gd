extends CanvasLayer

const Health = preload("res://health/health.gd")
const HealthSegment = preload("res://health/health_segment.gd")
const CELL_HP: int = 10
const SEGMENT_SCENE = preload("res://health/health_segment.tscn")

@onready var container: HBoxContainer = $SegmentsContainer

var player: CharacterBody2D
var health: Health
var _pending_added_start_index: int = -1
var _pending_added_count: int = 0


func _ready() -> void:
	player = get_node("/root/main/player")
	health = player.get_node("health")

	health.health_changed.connect(_on_health_changed)
	EventBus.on_pick_feedback.connect(_on_pick_feedback)

	_init_segments()
	_update_all_fills()


func _init_segments() -> void:
	var cell_count := _calc_cell_count()
	for i in range(cell_count):
		_add_segment()


## 按每格 CELL_HP 血量计算所需格子数（取上整）
func _calc_cell_count() -> int:
	return maxi(1, ceili(float(health.max_health) / CELL_HP))


func _add_segment() -> HealthSegment:
	var seg: HealthSegment = SEGMENT_SCENE.instantiate()
	seg.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_FILL
	seg.size_flags_vertical   = Control.SIZE_EXPAND | Control.SIZE_FILL
	container.add_child(seg)
	return seg


func _remove_segment() -> void:
	var count := container.get_child_count()
	if count > 0:
		container.get_child(count - 1).queue_free()


# ─── 信号回调 ──────────────────────────────────────────────────────────

func _on_health_changed(_current: int, _max: int) -> void:
	var before_count := container.get_child_count()
	_sync_cell_count()
	var after_count := container.get_child_count()
	# 假设：单次 health_changed 不会出现“先减后增”的格子变化（当前 max_health_up 仅增加）。
	# 若该假设被打破，区间差值可能指向错误格子，导致扫光播错目标；届时需改为记录具体节点集合。
	if after_count > before_count:
		_pending_added_start_index = before_count
		_pending_added_count = after_count - before_count
	_update_all_fills()


func _on_pick_feedback(ability_id: String, _level: int) -> void:
	if ability_id != "max_health_up":
		return

	if _pending_added_count <= 0:
		return

	var current_val := health.current_health
	for i in range(_pending_added_count):
		var cell_index := _pending_added_start_index + i
		var seg := container.get_child(cell_index) as HealthSegment
		var cell_start := cell_index * CELL_HP
		var actual_fill := clampf(float(current_val - cell_start) / CELL_HP, 0.0, 1.0)
		seg.play_sweep_animation(actual_fill)

	_pending_added_start_index = -1
	_pending_added_count = 0


# ─── 内部辅助 ──────────────────────────────────────────────────────────

func _sync_cell_count() -> void:
	var target := _calc_cell_count()
	var current := container.get_child_count()

	while current < target:
		_add_segment()
		current += 1
	while current > target:
		_remove_segment()
		current -= 1


func _update_all_fills() -> void:
	var current_val := health.current_health
	for i in range(container.get_child_count()):
		var seg: HealthSegment = container.get_child(i)
		var cell_start := i * CELL_HP
		var fill := clampf(float(current_val - cell_start) / CELL_HP, 0.0, 1.0)
		seg.set_fill_immediate(fill)
