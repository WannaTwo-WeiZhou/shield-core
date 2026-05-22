# speed_boost 能力专属选择反馈：3 帧拖影残像。
# 挂载为 player 子节点，监听 EventBus.on_pick_feedback，
# 当 ability_id == "speed_boost" 时在随后 3 帧快照玩家位置生成拖影。
# top_level=true 使拖影留在世界坐标，玩家移动后自然形成拖尾。
class_name SpeedBoostAfterimage
extends Node2D

## 拖影数量（对应 3 帧）
const GHOST_COUNT := 3
## 起始透明度（首帧最浓）
const GHOST_ALPHA_START := 0.6
## 拖影比核心视觉每边扩大的像素量，确保同位置时仍可见
const GHOST_EXPAND := 4.0
## 淡出时长（秒）
const FADE_DURATION := 0.4

var _player: CharacterBody2D
var _core_visual: ColorRect
## 拖影队列，每项 {pos: Vector2, start_alpha: float, elapsed: float}
var _ghosts: Array[Dictionary] = []
## 剩余待捕获拖影帧数（>0 时激活快照）
var _frames_remaining: int = 0


func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	_core_visual = _player.get_node("core_hitbox/core_visual") as ColorRect
	# top_level: 拖影留在世界坐标，玩家移动后拖影自然落后
	top_level = true
	z_index = -1

	EventBus.on_pick_feedback.connect(_on_pick_feedback)


func _process(delta: float) -> void:
	if _frames_remaining > 0:
		_capture_ghost()
		_frames_remaining -= 1

	_advance_ghosts(delta)

	if not _ghosts.is_empty():
		queue_redraw()


## 在当前帧快照玩家位置，生成一个拖影条目入队
func _capture_ghost() -> void:
	# 起始透明度逐帧递减：第 1 帧最浓 → 第 3 帧最淡
	var alpha := GHOST_ALPHA_START * (float(_frames_remaining) / GHOST_COUNT)
	_ghosts.append({
		"pos": _player.global_position,
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
		_frames_remaining = GHOST_COUNT
