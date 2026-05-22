# speed_boost 选择反馈：全屏放射速度线动画。
# 监听 EventBus.on_pick_feedback，为 speed_boost 能力提供 3 秒速度线视觉反馈。
# 使用 _draw() + 三角形几何绘制剪纸风格硬边线条，兼容 GL Compatibility。
extends Control

# ─── 线条配置 ─────────────────────────────────────────────────────────────────

const LINE_COUNT := 48
const BASE_WIDTH := 2.5               # 线根宽度（px）
const TIP_WIDTH := 0.0                # 尖端宽度（锐角收尾）
const CENTER_GAP := 40.0              # 中心呼吸口半径（px）
const LINE_COLOR := Color(0.88, 0.94, 1.0, 1.0)  # 淡青白底色，alpha 动态乘入
const ALPHA_OUTER := 0.12             # 外围短线最低 alpha
const ALPHA_INNER := 0.72             # 靠近中心长线最高 alpha

# ─── 动画时序 ─────────────────────────────────────────────────────────────────

const PHASE1_DURATION := 0.3          # 切入：弹出至 60% 长度
const PHASE2_DURATION := 2.2          # 保持：整体慢旋+单线微颤
const PHASE3_DURATION := 0.5          # 消退：向边框快速收拢
const TOTAL_DURATION := 3.0
const TARGET_PROGRESS := 0.6          # 阶段 1 结束时的长度比例

# ─── 微动参数 ─────────────────────────────────────────────────────────────────

const ROTATION_DEGREES := 10.0
const JITTER_AMPLITUDE := 1.5         # 单线颤动幅度（px）
const JITTER_SPEED := 4.0             # 颤动频率
const ANGLE_JITTER_DEG := 2.0         # 单线方向随机偏移（°）

# ─── 运行时状态 ───────────────────────────────────────────────────────────────

var _screen_center: Vector2 = Vector2.ZERO
var _screen_rect: Rect2 = Rect2()
var _half_diagonal: float = 0.0
var _lines: Array[Dictionary] = []

var _tween: Tween = null
var _anim_progress: float = 0.0
var _rotation_angle: float = 0.0
var _elapsed: float = 0.0
var _is_playing: bool = false


# ═══════════════════════════════════════════════════════════════════════════════
# 生命周期
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	hide()
	# 订阅专属反馈事件
	EventBus.on_pick_feedback.connect(_on_pick_feedback)


# ═══════════════════════════════════════════════════════════════════════════════
# 预计算
# ═══════════════════════════════════════════════════════════════════════════════

func _precompute_lines() -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var vsize := viewport_rect.size
	_screen_rect = Rect2(Vector2.ZERO, vsize)
	_screen_center = vsize / 2.0
	_half_diagonal = _screen_center.length()
	
	_lines.clear()
	var angle_step := TAU / LINE_COUNT
	
	for i in range(LINE_COUNT):
		var base_angle := angle_step * i
		# 每线 ±2° 随机偏移，避免过于规则的机械感
		var angle := base_angle + deg_to_rad(randf_range(-ANGLE_JITTER_DEG, ANGLE_JITTER_DEG))
		var start := _closest_border_point(_screen_center, angle)
		var direction := (_screen_center - start).normalized()
		
		# base_ratio：外短内长的随机分布，值域 [0.15, 0.85]
		var base_ratio := randf_range(0.15, 0.85)
		# 颤动相位随机偏移，避免所有线同步颤动
		var jitter_phase := randf() * TAU
		# 宽度微差 ±0.3px，模拟手工裁切
		var line_width := BASE_WIDTH + randf_range(-0.3, 0.3)
		
		_lines.append({
			"start": start,
			"direction": direction,
			"base_ratio": base_ratio,
			"line_width": line_width,
			"jitter_phase": jitter_phase,
		})


func _closest_border_point(center: Vector2, angle: float) -> Vector2:
	var dir := Vector2.RIGHT.rotated(angle)
	var r := _screen_rect
	var best_t := INF
	var best_point := center + dir * _half_diagonal * 2.0  # fallback
	
	# 四边线段
	var edges: Array[Dictionary] = [
		{"p0": r.position, "p1": Vector2(r.end.x, r.position.y)},                     # top
		{"p0": Vector2(r.end.x, r.position.y), "p1": r.end},                          # right
		{"p0": r.end, "p1": Vector2(r.position.x, r.end.y)},                          # bottom
		{"p0": Vector2(r.position.x, r.end.y), "p1": r.position},                     # left
	]
	
	for edge in edges:
		var t := _ray_segment_intersect(center, dir, edge["p0"], edge["p1"])
		if t > 0.001 and t < best_t:
			best_t = t
			best_point = center + dir * t
	
	return best_point


func _ray_segment_intersect(ray_o: Vector2, ray_d: Vector2, seg_a: Vector2, seg_b: Vector2) -> float:
	var seg_d := seg_b - seg_a
	var cross := ray_d.x * seg_d.y - ray_d.y * seg_d.x
	if absf(cross) < 0.0001:
		return INF
	var t := ((seg_a.x - ray_o.x) * seg_d.y - (seg_a.y - ray_o.y) * seg_d.x) / cross
	var u := ((seg_a.x - ray_o.x) * ray_d.y - (seg_a.y - ray_o.y) * ray_d.x) / cross
	if t > 0.0 and u >= 0.0 and u <= 1.0:
		return t
	return INF


# ═══════════════════════════════════════════════════════════════════════════════
# 事件响应
# ═══════════════════════════════════════════════════════════════════════════════

func _on_pick_feedback(ability_id: String, _level: int) -> void:
	if ability_id != "speed_boost":
		return
	
	# 每次触发重新预计算线条分布（适配可能的窗口尺寸变化）
	_precompute_lines()
	
	# 重置状态
	_anim_progress = 0.0
	_rotation_angle = 0.0
	_elapsed = 0.0
	_is_playing = true
	
	show()
	
	# 杀掉旧 Tween
	if _tween != null:
		_tween.kill()
	
	_tween = create_tween().set_parallel(false)
	
	# 阶段 1：切入 0→0.3s，弹出至 60% 长度
	_tween.tween_method(_set_anim_progress, 0.0, TARGET_PROGRESS, PHASE1_DURATION)\
		.set_ease(Tween.EASE_OUT)
	
	# 阶段 2：保持 0.3→2.5s，整体旋转 + 微颤在 _process 中驱动
	_tween.tween_interval(PHASE2_DURATION)
	
	# 阶段 3：消退 2.5→3.0s，从中心向边框快速收拢
	_tween.tween_method(_set_anim_progress, TARGET_PROGRESS, 0.0, PHASE3_DURATION)\
		.set_ease(Tween.EASE_IN)
	
	_tween.finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)


func _on_animation_finished() -> void:
	_is_playing = false
	hide()
	_tween = null


func _set_anim_progress(value: float) -> void:
	_anim_progress = value


# ═══════════════════════════════════════════════════════════════════════════════
# 逐帧
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not _is_playing:
		return
	
	_elapsed += delta
	
	# 仅在阶段 2 期间累加旋转
	if _elapsed > PHASE1_DURATION and _elapsed <= PHASE1_DURATION + PHASE2_DURATION:
		var phase2_elapsed := _elapsed - PHASE1_DURATION
		var rot_fraction := clampf(phase2_elapsed / PHASE2_DURATION, 0.0, 1.0)
		_rotation_angle = deg_to_rad(lerpf(0.0, ROTATION_DEGREES, rot_fraction))
	elif _elapsed > PHASE1_DURATION + PHASE2_DURATION:
		# 阶段 3 保持旋转角不再增长
		_rotation_angle = deg_to_rad(ROTATION_DEGREES)
	
	queue_redraw()


# ═══════════════════════════════════════════════════════════════════════════════
# 绘制
# ═══════════════════════════════════════════════════════════════════════════════

func _draw() -> void:
	if _lines.is_empty():
		return
	
	for line: Dictionary in _lines:
		var start: Vector2 = line["start"]
		var direction: Vector2 = line["direction"]
		var base_ratio: float = line["base_ratio"]
		var line_width: float = line["line_width"]
		var jitter_phase: float = line["jitter_phase"]
		
		# 当前帧终点（受 anim_progress 控制长度）
		var max_length := base_ratio * _half_diagonal
		var current_length := max_length * _anim_progress
		var tip := start + direction * current_length
		
		# 整体旋转（绕屏幕中心）
		if absf(_rotation_angle) > 0.0001:
			tip = _rotate_around(tip, _screen_center, _rotation_angle)
			start = _rotate_around(start, _screen_center, _rotation_angle)
			direction = (_screen_center - start).normalized()
		
		# 单线微颤（垂直于方向）
		if _anim_progress > 0.0:
			var jitter := sin(_elapsed * JITTER_SPEED + jitter_phase) * JITTER_AMPLITUDE
			var perp := direction.rotated(PI / 2.0)
			tip += perp * jitter * _anim_progress
		
		# 中心呼吸口：不进入 CENTER_GAP 半径内
		var to_center := tip - _screen_center
		var dist_to_center := to_center.length()
		if dist_to_center < CENTER_GAP and dist_to_center > 0.0:
			tip = _screen_center + to_center.normalized() * CENTER_GAP
		
		# Alpha = 按 base_ratio 在 [ALPHA_OUTER, ALPHA_INNER] 间线性映射
		var alpha := lerpf(ALPHA_OUTER, ALPHA_INNER, base_ratio)
		alpha = clampf(alpha * _anim_progress, 0.0, 1.0)
		var color := Color(LINE_COLOR, alpha)
		
		# 构建梯形 / 三角：四顶点 → 两个三角形
		var perp := direction.rotated(PI / 2.0)
		var p1 := start + perp * line_width
		var p2 := start - perp * line_width
		var p3 := tip - perp * TIP_WIDTH
		var p4 := tip + perp * TIP_WIDTH
		
		draw_colored_polygon(PackedVector2Array([p1, p2, p3]), color)
		draw_colored_polygon(PackedVector2Array([p1, p3, p4]), color)


func _rotate_around(point: Vector2, pivot: Vector2, angle: float) -> Vector2:
	var rel := point - pivot
	return pivot + Vector2(
		rel.x * cos(angle) - rel.y * sin(angle),
		rel.x * sin(angle) + rel.y * cos(angle)
	)
