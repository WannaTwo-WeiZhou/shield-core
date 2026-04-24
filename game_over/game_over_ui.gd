extends CanvasLayer

@onready var player: Node = get_node("/root/main/player")
@onready var bullet_spawner: Node = get_node("/root/main/bullet_spawner")
@onready var overlay: ColorRect = $overlay
@onready var again_label: Label = $again_label

var is_game_over: bool = false

func _ready() -> void:
	overlay.visible = false
	again_label.visible = false
	
	if player and player.has_node("health"):
		var health = player.get_node("health")
		health.health_depleted.connect(_on_health_depleted)

func _on_health_depleted() -> void:
	if is_game_over:
		return
	
	is_game_over = true
	
	# Stop bullet spawning
	if bullet_spawner and bullet_spawner.has_method("stop_spawning"):
		bullet_spawner.stop_spawning()
	
	# Destroy all bullets
	for bullet in get_tree().get_nodes_in_group("bullet"):
		bullet.queue_free()
	
	# Show game over UI
	overlay.visible = true
	again_label.visible = true

func _input(event: InputEvent) -> void:
	if not is_game_over:
		return
	
	var should_restart = false
	
	# Check for screen touch or mouse click
	if event is InputEventScreenTouch:
		if event.pressed:
			should_restart = true
	elif event is InputEventMouseButton:
		if event.pressed:
			should_restart = true
	# Check for any key press
	elif event is InputEventKey:
		if event.pressed and not event.echo:
			should_restart = true
	
	if should_restart:
		get_tree().reload_current_scene()
