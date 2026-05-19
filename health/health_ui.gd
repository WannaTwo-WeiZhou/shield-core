extends CanvasLayer

const Health = preload("res://health/health.gd")
const HealthSegment = preload("res://health/health_segment.gd")
const CELL_HP: int = 10
const SEGMENT_SCENE = preload("res://health/health_segment.tscn")

@onready var container: HBoxContainer = $SegmentsContainer

var player: CharacterBody2D
var health: Health
var _last_known_cell_count: int = 0


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
	_last_known_cell_count = cell_count


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
	_sync_cell_count()
	_update_all_fills()


func _on_pick_feedback(ability_id: String, _level: int) -> void:
	if ability_id != "max_health_up":
		return

	# 此时 health.max_health 已被管线更新（abilities_updated 先于本信号同步发射）
	var new_count := _calc_cell_count()
	if new_count <= _last_known_cell_count:
		return

	# 为每个新增格子播放扩容扫光动画
	var cells_to_add := new_count - _last_known_cell_count
	var current_val := health.current_health
	for i in range(cells_to_add):
		var seg := _add_segment()
		var cell_index := _last_known_cell_count + i
		var cell_start := cell_index * CELL_HP
		var actual_fill := clampf(float(current_val - cell_start) / CELL_HP, 0.0, 1.0)
		seg.play_sweep_animation(actual_fill)

	_last_known_cell_count = new_count


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

	_last_known_cell_count = target


func _update_all_fills() -> void:
	var current_val := health.current_health
	for i in range(container.get_child_count()):
		var seg: HealthSegment = container.get_child(i)
		var cell_start := i * CELL_HP
		var fill := clampf(float(current_val - cell_start) / CELL_HP, 0.0, 1.0)
		seg.set_fill_immediate(fill)
