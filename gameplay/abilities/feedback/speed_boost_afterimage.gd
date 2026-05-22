# speed_boost 能力专属选择反馈：3 帧拖影残像。
# 挂载为 player 子节点，监听 EventBus.on_pick_feedback，
# 当 ability_id == "speed_boost" 时在随后 3 帧快照玩家位置生成拖影。
# 使用 _draw() / draw_rect() 直接绘制，避免 Control 节点在 Node2D 下的兼容问题。
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

var _player: CharacterBody2D
var _core_visual: ColorRect
## 拖影队列，每项 {pos: Vector2, start_alpha: float, elapsed: float}
var _ghosts: Array[Dictionary] = []
## 剩余待捕获拖影帧数（>0 时激活快照）
var _frames_remaining: int = 0


func _ready() -> void:
	# 获取玩家引用及核心视觉
	_player = get_parent() as CharacterBody2D
	_core_visual = _player.get_node("core_hitbox/core_visual") as ColorRect
	# 拖影始终绘制在玩家本体下方
	z_index = -1

	# 仅响应 speed_boost 能力的 pick_feedback
	EventBus.on_pick_feedback.connect(_on_pick_feedback)


func _process(delta: float) -> void:
	# 帧计数器活跃时，本帧快照一个 ghost 入队
	if _frames_remaining > 0:
		_capture_ghost()
		_frames_remaining -= 1

	# 推进所有已有 ghost 的淡出计时，到期自动移除
	_advance_ghosts(delta)

	# 有可见 ghost 时触发重绘
	if not _ghosts.is_empty():
		queue_redraw()


## 在当前帧快照玩家位置，生成一个拖影条目入队
func _capture_ghost() -> void:
	# 偏移方向：沿移动反方向（拖影留在身后）
	var offset_dir := Vector2.ZERO
	if _player.velocity.length_squared() > 0.1:
		offset_dir = -_player.velocity.normalized()
	# 帧序号越靠后，偏移量越大，形成速度方向上的残影拉伸感
	var offset := offset_dir * GHOST_OFFSET * float(GHOST_COUNT - _frames_remaining + 1)
	# 起始透明度逐帧递减：第 1 帧最浓 → 第 3 帧最淡
	var alpha := GHOST_ALPHA_START * (float(_frames_remaining) / GHOST_COUNT)

	_ghosts.append({
		"pos": _player.global_position + offset,
		"start_alpha": alpha,
		"elapsed": 0.0,
	})


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
	var half: float = _core_visual.size.x / 2.0

	for g in _ghosts:
		# alpha 按存活时间线性衰减
		var progress := g["elapsed"] / FADE_DURATION
		var col := base_color
		col.a = g["start_alpha"] * (1.0 - progress)

		# 世界坐标 → 节点本地坐标（节点随玩家移动，历史位置自然形成拖尾）
		var local_pos := to_local(g["pos"])
		var rect := Rect2(
			local_pos.x - half,
			local_pos.y - half,
			_core_visual.size.x,
			_core_visual.size.y
		)
		draw_rect(rect, col)


func _on_pick_feedback(ability_id: String, _level: int) -> void:
	if ability_id == "speed_boost":
		_frames_remaining = GHOST_COUNT
