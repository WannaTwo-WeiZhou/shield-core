extends CanvasLayer

const Experience = preload("res://experience/experience.gd")

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var value_label: Label = $value_label
@onready var xp_popup_label: Label = $xp_popup_label
var player: CharacterBody2D
var experience: Experience
var _xp_popup_base_position: Vector2 = Vector2.ZERO
var _xp_popup_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_node("/root/main/player")
	experience = player.get_node("experience")
	experience.xp_changed.connect(_on_xp_changed)
	experience.level_up.connect(_on_level_up)
	experience.xp_gained.connect(_on_xp_gained)
	
	# Initialize with current values
	progress_bar.max_value = experience.xp_to_next_level
	progress_bar.value = experience.current_xp
	_refresh_value_label(experience.current_xp, experience.xp_to_next_level)
	_xp_popup_base_position = xp_popup_label.position
	xp_popup_label.hide()

func _on_xp_changed(current_xp: int, max_xp: int, level: int) -> void:
	progress_bar.max_value = max_xp
	progress_bar.value = current_xp
	_refresh_value_label(current_xp, max_xp)

func _on_level_up(new_level: int) -> void:
	print("[UI] Level up animation trigger for level %d" % new_level)
	# 通知能力管理器生成升级候选
	AbilityManager.on_player_level_up()


func _on_xp_gained(amount: int, current_xp: int, max_xp: int, level: int) -> void:
	_show_xp_gain_popup(amount)


func _refresh_value_label(current_xp: int, max_xp: int) -> void:
	value_label.text = "%d / %d" % [current_xp, max_xp]


func _show_xp_gain_popup(amount: int) -> void:
	xp_popup_label.text = "+%d XP" % amount
	xp_popup_label.position = _xp_popup_base_position
	xp_popup_label.modulate = Color(1, 1, 1, 1)
	xp_popup_label.show()

	if _xp_popup_tween != null:
		_xp_popup_tween.kill()

	_xp_popup_tween = create_tween()
	_xp_popup_tween.set_parallel(true)
	_xp_popup_tween.tween_property(
		xp_popup_label,
		"position",
		_xp_popup_base_position + Vector2(0, -18),
		0.45
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_xp_popup_tween.tween_property(
		xp_popup_label,
		"modulate",
		Color(1, 1, 1, 0),
		0.45
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_xp_popup_tween.finished.connect(_on_xp_popup_finished)


func _on_xp_popup_finished() -> void:
	xp_popup_label.hide()
	xp_popup_label.position = _xp_popup_base_position
