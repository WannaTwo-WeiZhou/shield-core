# speed_boost 能力专属选择反馈：3 帧拖影残像。
# 挂载为 player 子节点，监听 EventBus.on_pick_feedback，
# 当 ability_id == "speed_boost" 时立即在玩家身后生成 3 个拖影。
# 使用"上一次有效移动向量"确定身后方向，即使触发时玩家静止也能正确偏移。
# top_level=true 使拖影固定在世界坐标。
class_name SpeedBoostAfterimage
extends Node2D

## 拖影数量
const GHOST_COUNT := 3
## 起始透明度（最近的 ghost 最浓）
const GHOST_ALPHA_START := 0.6
## 每个 ghost 沿反方向的偏移间距（px）
const GHOST_OFFSET_STEP := 12.0
## 拖影比核心视觉每边扩大的像素量
const GHOST_EXPAND := 4.0
## 淡出时长（秒）
const FADE_DURATION := 0.45
## 默认拖尾方向（玩家从未移动过时的回退方向：向下）
const DEFAULT_TRAIL_DIR := Vector2(0.0, 1.0)

var _player: CharacterBody2D
var _core_visual: ColorRect
## 拖影队列，每项 {pos: Vector2, start_alpha: float, elapsed: float}
var _ghosts: Array[Dictionary] = []
## 上一次有效移动方向（归一化），用于在玩家静止时确定拖影方向
var _last_move_dir: Vector2 = DEFAULT_TRAIL_DIR


func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	_core_visual = _player.get_node("core_hitbox/core_visual") as ColorRect
	top_level = true
	z_index = -1

	EventBus.on_pick_feedback.connect(_on_pick_feedback)


func _process(delta: float) -> void:
	# 每帧记录上一次有效移动方向
	if _player.velocity.length_squared() > 1.0:
		_last_move_dir = _player.velocity.normalized()

	_advance_ghosts(delta)

	if not _ghosts.is_empty():
		queue_redraw()


## 一次性生成全部拖影，沿上一次移动反方向依次偏移
func _spawn_ghosts() -> void:
	var trail_dir := -_last_move_dir  # 反方向 = 身后
	for i in range(GHOST_COUNT):
		# i=0 最近、最浓；i=2 最远、最淡
		var distance := GHOST_OFFSET_STEP * float(i + 1)
		var ghost_pos := _player.global_position + trail_dir * distance
		var alpha := GHOST_ALPHA_START * (1.0 - float(i) / GHOST_COUNT)
		_ghosts.append({
			"pos": ghost_pos,
			"start_alpha": alpha,
			"elapsed": 0.0,
		})
	queue_redraw()


## 推进所有 ghost 的存活计时，过期则移除
func _advance_ghosts(delta: float) -> void:
	var i := _ghosts.size() - 1
	while i >= 0:
		var g := _ghosts[i]
		g["elapsed"] += delta
		if g["elapsed"] >= FADE_DURATION:
			_ghosts.remove_at(i)
		i -= 1


## 每帧重绘：遍历队列，用 draw_rect 逐个绘制拖影残像
func _draw() -> void:
	var base_color := _core_visual.color
	var ghost_width: float = _core_visual.size.x + GHOST_EXPAND * 2.0
	var ghost_height: float = _core_visual.size.y + GHOST_EXPAND * 2.0

	for g in _ghosts:
		var progress: float = g["elapsed"] / FADE_DURATION
		var col := base_color
		col.a = g["start_alpha"] * (1.0 - progress)

		var local_pos := to_local(g["pos"])
		var rect := Rect2(local_pos.x - ghost_width / 2.0, local_pos.y - ghost_height / 2.0, ghost_width, ghost_height)
		draw_rect(rect, col)


func _on_pick_feedback(ability_id: String, _level: int) -> void:
	if ability_id == "speed_boost":
		_spawn_ghosts()
