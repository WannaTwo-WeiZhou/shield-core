extends CanvasLayer

@onready var progress_bar: ProgressBar = $ProgressBar
var player: CharacterBody2D

func _ready() -> void:
	player = get_node("/root/main/player")
	player.experience.xp_changed.connect(_on_xp_changed)
	player.experience.level_up.connect(_on_level_up)
	
	# Initialize with current values
	progress_bar.max_value = player.experience.xp_to_next_level
	progress_bar.value = player.experience.current_xp

func _on_xp_changed(current_xp: int, max_xp: int, level: int) -> void:
	progress_bar.max_value = max_xp
	progress_bar.value = current_xp

func _on_level_up(new_level: int) -> void:
	print("[UI] Level up animation trigger for level %d" % new_level)
	# 通知能力管理器生成升级候选
	AbilityManager.on_player_level_up(new_level)
