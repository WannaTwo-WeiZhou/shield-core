# speed_boost 能力专属选择反馈：3 帧拖影残像。
# 挂载为 player 子节点，监听 EventBus.on_pick_feedback，
# 当 ability_id == "speed_boost" 时在随后 3 帧生成拖影 ghost。
class_name SpeedBoostAfterimage
extends Node2D

## 拖影数量（对应 3 帧）
const GHOST_COUNT := 3
## 起始透明度（首帧）
const GHOST_ALPHA_START := 0.4
## 拖影沿反方向偏移基数（px）
const GHOST_OFFSET := 4.0
## 淡出时长（秒）
const FADE_DURATION := 0.25
## 拖影 z_index（低于玩家核心，不遮挡本体）
const GHOST_Z_INDEX := -1

var _player: CharacterBody2D
var _core_visual: ColorRect
## 预分配拖影节点池，循环复用
var _ghost_pool: Array[ColorRect] = []
var _pool_index: int = 0
## 剩余待生成拖影帧数（>0 时激活）
var _frames_remaining: int = 0


func _ready() -> void:
	# 获取玩家引用及核心视觉
	_player = get_parent() as CharacterBody2D
	_core_visual = _player.get_node("core_hitbox/core_visual") as ColorRect

	# 预分配拖影池：所有 ghost 初始隐藏，等待激活
	for i in range(GHOST_COUNT):
		var ghost := ColorRect.new()
		ghost.hide()
		ghost.size = _core_visual.size
		ghost.color = _core_visual.color
		ghost.top_level = true
		ghost.z_index = GHOST_Z_INDEX
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(ghost)
		_ghost_pool.append(ghost)

	# 仅响应 speed_boost 能力的 pick_feedback
	EventBus.on_pick_feedback.connect(_on_pick_feedback)


func _process(_delta: float) -> void:
	if _frames_remaining <= 0:
		return

	# 从池中轮取一个 ghost
	var ghost := _ghost_pool[_pool_index % GHOST_COUNT]
	_pool_index += 1

	# 快照玩家当前位置，沿移动反方向做微量偏移以强化速度感
	var offset := Vector2.ZERO
	if _player.velocity.length_squared() > 0.1:
		# 帧序号越靠后（_frames_remaining 越小），偏移越大，形成速度残影拉伸
		offset = -_player.velocity.normalized() * GHOST_OFFSET * float(GHOST_COUNT - _frames_remaining + 1)
	ghost.global_position = _player.global_position + offset

	# 逐帧递减透明度：第 1 帧最浓，第 3 帧最淡
	var alpha := GHOST_ALPHA_START * (float(_frames_remaining) / GHOST_COUNT)
	ghost.color.a = alpha
	ghost.show()

	# 启动淡出 Tween，完成后隐藏
	var tw := create_tween()
	tw.tween_property(ghost, "color:a", 0.0, FADE_DURATION)
	tw.tween_callback(ghost.hide)

	_frames_remaining -= 1


func _on_pick_feedback(ability_id: String, _level: int) -> void:
	if ability_id == "speed_boost":
		_frames_remaining = GHOST_COUNT
		_pool_index = 0
