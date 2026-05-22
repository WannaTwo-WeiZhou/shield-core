# 选能力后屏幕中央浮字提示「获得【能力名】」。
# 使用 CanvasLayer 放置在最上层，不打断战斗操作。
extends CanvasLayer

@onready var feedback_label: Label = $FeedbackLabel
var _tween: Tween = null


func _ready() -> void:
	layer = 200
	feedback_label.hide()
	# 监听能力获取信号
	AbilityManager.ability_acquired.connect(_on_ability_acquired)


func _on_ability_acquired(ability_id: String, _level: int) -> void:
	var ability_name := AbilityManager.get_ability_name(ability_id)
	feedback_label.text = "获得【%s】" % ability_name
	feedback_label.modulate = Color(1, 1, 1, 0)
	feedback_label.show()

	if _tween != null:
		_tween.kill()

	# 动画时序：淡入 0.1s → 停留 0.5s → 淡出 0.2s
	_tween = create_tween().set_parallel(false)
	# 淡入
	_tween.tween_property(feedback_label, "modulate", Color(1, 1, 1, 1), 0.1)\
		.set_ease(Tween.EASE_IN)
	# 停留
	_tween.tween_interval(0.5)
	# 淡出
	_tween.tween_property(feedback_label, "modulate", Color(1, 1, 1, 0), 0.2)\
		.set_ease(Tween.EASE_OUT)
	_tween.finished.connect(_on_feedback_done.bind(_tween), CONNECT_ONE_SHOT)


func _on_feedback_done(t: Tween) -> void:
	if t != _tween:
		return
	# 仅当已经完全淡出才隐藏，防止被新 tween 覆盖时误隐藏
	if feedback_label.modulate.a <= 0.01:
		feedback_label.hide()
