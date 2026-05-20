class_name HealthSegment
extends Panel

## 血量格子填充矩形
@onready var fill_rect: ColorRect = $FillRect

## 填充色（红）
@export var fill_color: Color = Color(0.905882, 0.298039, 0.235294, 1)
## 背景色（暗灰）
@export var bg_color: Color = Color(0.2, 0.2, 0.2, 0.8)

var _tween: Tween = null


func _ready() -> void:
	fill_rect.color = fill_color
	var style := get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.bg_color = bg_color


## 将填充比例应用到 Rect（0~1：anchor_bottom 相对父 Panel 高度）
func _apply_fill_ratio(ratio: float) -> void:
	fill_rect.anchor_left = 0.0
	fill_rect.anchor_top = 0.0
	fill_rect.anchor_right = 1.0
	fill_rect.anchor_bottom = ratio
	fill_rect.offset_left = 0.0
	fill_rect.offset_top = 0.0
	fill_rect.offset_right = 0.0
	fill_rect.offset_bottom = 0.0


## 扩容扫光动画：从 0 → 满 → 回落至指定比例（tween anchor_bottom）
func play_sweep_animation(final_ratio: float) -> void:
	final_ratio = clampf(final_ratio, 0.0, 1.0)
	if _tween and _tween.is_valid():
		_tween.kill()
	_apply_fill_ratio(0.0)
	_tween = create_tween().set_parallel(false)
	# 阶段 1：从上到下扫满全格（扩容感）
	_tween.tween_property(fill_rect, "anchor_bottom", 1.0, 0.3) \
		.set_ease(Tween.EASE_IN_OUT) \
		.set_trans(Tween.TRANS_CUBIC)
	# 阶段 2：回落至真实填充率
	_tween.tween_property(fill_rect, "anchor_bottom", final_ratio, 0.1) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)


## 立即设置填充比例（无动画）
func set_fill_immediate(ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	if _tween and _tween.is_valid():
		_tween.kill()
	if fill_rect:
		_apply_fill_ratio(ratio)
