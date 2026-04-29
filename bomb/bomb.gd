# B弹资源管理系统
# 管理B弹的充能数量和自动恢复
extends Node

signal bomb_count_changed(current: int, max: int)
signal bomb_used()
signal bomb_recharged()

@export var max_bombs: int = 3  # 最多可积攒的B弹数量
@export var recharge_time: float = 30.0  # 每发B弹的恢复时间（秒）

var current_bombs: int = 3  # 当前可用的B弹数量
var _recharge_timer: float = 0.0  # 当前恢复计时器

func _ready() -> void:
	current_bombs = max_bombs
	_recharge_timer = 0.0
	bomb_count_changed.emit(current_bombs, max_bombs)

func _process(delta: float) -> void:
	# 只在未满充能时计时
	if current_bombs < max_bombs:
		# recharge_time 配置异常（<=0）时直接立即补满，避免除零或卡死
		if recharge_time <= 0.0:
			_recharge_timer = 0.0
			current_bombs = max_bombs
			bomb_recharged.emit()
			bomb_count_changed.emit(current_bombs, max_bombs)
			return
		_recharge_timer += delta
		if _recharge_timer >= recharge_time:
			_recharge_timer = 0.0
			current_bombs += 1
			bomb_recharged.emit()
			bomb_count_changed.emit(current_bombs, max_bombs)
			print("[BOMB] B弹已恢复，当前: %d/%d" % [current_bombs, max_bombs])

# 使用一发B弹，返回是否成功使用
func use_bomb() -> bool:
	if current_bombs <= 0:
		return false

	current_bombs -= 1
	bomb_used.emit()
	bomb_count_changed.emit(current_bombs, max_bombs)
	print("[BOMB] 使用B弹，剩余: %d/%d" % [current_bombs, max_bombs])
	return true

# 获取当前B弹数量
func get_current_bombs() -> int:
	return current_bombs

# 获取最大B弹数量
func get_max_bombs() -> int:
	return max_bombs

# 获取当前恢复进度（0.0-1.0）
func get_recharge_progress() -> float:
	if current_bombs >= max_bombs:
		return 0.0
	if recharge_time <= 0.0:
		return 1.0
	return clampf(_recharge_timer / recharge_time, 0.0, 1.0)

# 重置B弹数量（例如游戏重新开始时）
func reset() -> void:
	current_bombs = max_bombs
	_recharge_timer = 0.0
	bomb_count_changed.emit(current_bombs, max_bombs)
