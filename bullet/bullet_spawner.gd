extends Node

@export var bullet_scene: PackedScene
@export var spawn_interval: float = 1.0
@export var initial_delay: float = 2.0

const SCREEN_WIDTH: float = 640.0
const SCREEN_HEIGHT: float = 960.0
const SPAWN_MARGIN: float = 50.0

var player: CharacterBody2D
var spawning: bool = true

func _ready() -> void:
	player = get_node("../player")
	await get_tree().create_timer(initial_delay).timeout
	_start_spawning()

func _start_spawning() -> void:
	while spawning:
		_spawn_bullet()
		await get_tree().create_timer(spawn_interval).timeout

var bullet_counter: int = 0

func _spawn_bullet() -> void:
	if not is_instance_valid(player):
		return
	
	bullet_counter += 1
	var bullet = bullet_scene.instantiate()
	bullet.name = "bullet_" + str(bullet_counter)
	bullet.global_position = _get_random_spawn_position()
	bullet.init(player.global_position)
	get_parent().add_child(bullet)

func _get_random_spawn_position() -> Vector2:
	var edge = randi() % 4
	var pos = Vector2.ZERO
	
	match edge:
		0: # Top
			pos.x = randf_range(SPAWN_MARGIN, SCREEN_WIDTH - SPAWN_MARGIN)
			pos.y = -SPAWN_MARGIN
		1: # Right
			pos.x = SCREEN_WIDTH + SPAWN_MARGIN
			pos.y = randf_range(SPAWN_MARGIN, SCREEN_HEIGHT - SPAWN_MARGIN)
		2: # Bottom
			pos.x = randf_range(SPAWN_MARGIN, SCREEN_WIDTH - SPAWN_MARGIN)
			pos.y = SCREEN_HEIGHT + SPAWN_MARGIN
		3: # Left
			pos.x = -SPAWN_MARGIN
			pos.y = randf_range(SPAWN_MARGIN, SCREEN_HEIGHT - SPAWN_MARGIN)
	
	return pos

func stop_spawning() -> void:
	spawning = false
