extends CanvasLayer

@onready var progress_bar: ProgressBar = $ProgressBar
var player: CharacterBody2D

func _ready() -> void:
	player = get_node("/root/main/player")
	player.health.health_changed.connect(_on_health_changed)
	progress_bar.max_value = player.health.max_health
	progress_bar.value = player.health.current_health

func _on_health_changed(current: int, max: int) -> void:
	progress_bar.max_value = max
	progress_bar.value = current
