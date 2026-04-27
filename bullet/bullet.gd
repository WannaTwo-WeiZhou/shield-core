extends CharacterBody2D

@export var speed: float = 100.0

var direction: Vector2 = Vector2.ZERO

@onready var visible_notifier: VisibleOnScreenNotifier2D = $visible_notifier

func _ready() -> void:
	visible_notifier.screen_exited.connect(_on_screen_exited)

func init(target_position: Vector2) -> void:
	direction = (target_position - global_position).normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var collision = move_and_collide(direction * speed * delta)
	if collision:
		var collider = collision.get_collider()
		if is_in_group("player_bullet") and collider and collider.is_in_group("bullet") and not collider.is_in_group("player_bullet"):
			if not collider.is_queued_for_deletion() and not is_queued_for_deletion():
				var player = AbilityManager.get_player()
				if player and player.has_method("on_enemy_bullet_destroyed"):
					player.on_enemy_bullet_destroyed(collider)
				collider.queue_free()
				queue_free()

func _on_screen_exited() -> void:
	queue_free()
