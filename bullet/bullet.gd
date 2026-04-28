extends CharacterBody2D

@export var speed: float = 100.0

var direction: Vector2 = Vector2.ZERO

@onready var visible_notifier: VisibleOnScreenNotifier2D = $visible_notifier

func _ready() -> void:
	visible_notifier.screen_exited.connect(_on_screen_exited)

# 由 BulletSpawner 调用：spawn_pos 是出生点，dir 是单位方向向量，bullet_speed 覆盖默认速度。
func init(spawn_pos: Vector2, dir: Vector2, bullet_speed: float = -1.0) -> void:
	global_position = spawn_pos
	if dir.length_squared() <= 0.0:
		dir = Vector2.DOWN
	direction = dir.normalized()
	rotation = direction.angle()
	if bullet_speed > 0.0:
		speed = bullet_speed

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
