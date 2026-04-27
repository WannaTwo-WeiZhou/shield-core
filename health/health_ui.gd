extends CanvasLayer

const Health = preload("res://health/health.gd")

@onready var progress_bar: ProgressBar = $ProgressBar
var player: CharacterBody2D
var health: Health

func _ready() -> void:
	player = get_node("/root/main/player")
	health = player.get_node("health")
	health.health_changed.connect(_on_health_changed)
	progress_bar.max_value = health.max_health
	progress_bar.value = health.current_health

func _on_health_changed(current: int, max: int) -> void:
	progress_bar.max_value = max
	progress_bar.value = current
