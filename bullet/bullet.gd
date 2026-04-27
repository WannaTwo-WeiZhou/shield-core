extends CharacterBody2D

@export var speed: float = 100.0

var direction: Vector2 = Vector2.ZERO

@onready var visible_notifier: VisibleOnScreenNotifier2D = $visible_notifier

func _ready() -> void:
	visible_notifier.screen_exited.connect(_on_screen_exited)

func init(target_position: Vector2) -> void:
	direction = (target_position - global_position).normalized()
	rotation = direction.angle()

func _process(delta: float) -> void:
	position += direction * speed * delta

func _on_screen_exited() -> void:
	queue_free()
