# 惶惶（speed_boost）选择后的拖影残像反馈。
# 监听 EventBus.on_pick_feedback，在玩家位置动态生成沿移动反方向排列的渐隐残像。
extends Node

const AFTERIMAGE_COUNT := 3
const BASE_OFFSET := 8.0          # 最近残像距玩家中心的偏移（像素）
const OFFSET_STEP := 12.0         # 残像间距（像素）
const INITIAL_ALPHAS := [0.6, 0.45, 0.3]
const FADE_DURATION := 0.1         # 每个残像淡出时长（秒）
const STAGGER_DELAY := 0.02        # 残像错峰启动间隔（秒）

var _player_path: NodePath = NodePath("/root/main/player")


func _ready() -> void:
	EventBus.on_pick_feedback.connect(_on_pick_feedback)


func _on_pick_feedback(ability_id: String, _level: int) -> void:
	if ability_id != "speed_boost":
		return

	var raw = get_node_or_null(_player_path)
	if raw == null or not raw is Node2D:
		return
	var player: Node2D = raw

	var origin: Vector2 = player.global_position

	# 使用最近一次有效移动方向（静止时不会为零向量）
	var trail_dir: Vector2 = -player.get("last_move_direction")

	# 克隆玩家核心视觉的颜色
	var ghost_color: Color = Color(0.906, 0.298, 0.235, 1.0)  # 默认 #E74C3C
	var core_visual = player.get_node_or_null("core_hitbox/core_visual")
	if core_visual != null and core_visual is ColorRect:
		ghost_color = core_visual.color

	var main_node = get_node_or_null("/root/main")
	if main_node == null:
		return

	for i in range(AFTERIMAGE_COUNT):
		_create_ghost(origin, trail_dir, i, ghost_color, main_node)


func _create_ghost(origin: Vector2, trail_dir: Vector2, index: int, color: Color, parent: Node) -> void:
	var ghost := ColorRect.new()
	ghost.color = color
	ghost.size = Vector2(32, 32)
	ghost.pivot_offset = Vector2(16, 16)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 5

	# 残像沿移动反方向依次排列
	var offset: Vector2 = trail_dir * (BASE_OFFSET + index * OFFSET_STEP)
	ghost.position = origin + offset - ghost.size / 2
	ghost.modulate.a = INITIAL_ALPHAS[index]

	parent.add_child(ghost)

	# 错峰淡出
	var tween := create_tween()
	tween.tween_interval(index * STAGGER_DELAY)
	tween.tween_property(ghost, "modulate:a", 0.0, FADE_DURATION)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_callback(ghost.queue_free)
