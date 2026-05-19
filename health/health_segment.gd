class_name HealthSegment
extends Panel

const MIN_FILL_HEIGHT_PX: float = 1.0

## 血量格子填充矩形
@onready var fill_rect: ColorRect = $FillRect

## 填充色（红）
@export var fill_color: Color = Color(0.905882, 0.298039, 0.235294, 1)
## 背景色（暗灰）
@export var bg_color: Color = Color(0.2, 0.2, 0.2, 0.8)

var _tween: Tween = null


func _ready() -> void:
	fill_rect.color = fill_color
	# 将背景色应用到 Panel 的样式
	var style := get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		style.bg_color = bg_color


## HBox 新增子节点后首帧可能尚未完成布局，size.y 会暂时为 0；
## 此时回退到 custom_minimum_size.y，避免扫光动画目标高度丢失；
## 若两者都不可用，再用 MIN_FILL_HEIGHT_PX（1px）保底，确保补间仍可见。
func _get_fill_height() -> float:
	if size.y > 0.0:
		return size.y
	if custom_minimum_size.y > 0.0:
		return custom_minimum_size.y
	# 至少保底 1px，避免目标高度为 0 导致补间不可见。
	return MIN_FILL_HEIGHT_PX


## 扩容扫光动画：从 0 → 满 → 回落至指定比例
func play_sweep_animation(final_ratio: float) -> void:
	final_ratio = clampf(final_ratio, 0.0, 1.0)
	if _tween and _tween.is_valid():
		_tween.kill()

	var fill_height := _get_fill_height()
	fill_rect.offset_bottom = 0.0
	_tween = create_tween().set_parallel(false)
	# 阶段 1：从上到下扫满全格（扩容感）
	_tween.tween_property(fill_rect, "offset_bottom", fill_height, 0.3)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_CUBIC)
	# 阶段 2：回落至真实填充率
	_tween.tween_property(fill_rect, "offset_bottom", fill_height * final_ratio, 0.1)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_CUBIC)


## 动画填充到指定比例（0 = 空, 1 = 满）
func animate_fill(ratio: float, duration: float = 0.3) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	var target_height := _get_fill_height() * ratio

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(fill_rect, "offset_bottom", target_height, duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_CUBIC)


## 立即设置填充比例（无动画）
func set_fill_immediate(ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	if fill_rect:
		fill_rect.offset_bottom = _get_fill_height() * ratio
