extends CharacterBody2D

const Experience = preload("res://experience/experience.gd")

const SPEED: float = 400.0
const MIN_X: float = 40.0
const MAX_X: float = 600.0
const MIN_Y: float = 40.0
const MAX_Y: float = 920.0

const JOYSTICK_MAX_RADIUS: float = 60.0
const JOYSTICK_DEADZONE: float = 10.0

@onready var joystick_base: Sprite2D = get_node("/root/main/joystick_canvas/joystick_base")
@onready var joystick_knob: Sprite2D = get_node("/root/main/joystick_canvas/joystick_base/joystick_knob")
@onready var shield_container: Marker2D = $shield_container
@onready var core_hitbox: Area2D = $core_hitbox
@onready var shield_left: Area2D = $shield_container/shield_left
@onready var shield_right: Area2D = $shield_container/shield_right
@onready var health: Health = $health
@onready var experience: Experience = $experience

var is_dragging: bool = false
var joystick_center: Vector2 = Vector2.ZERO
var input_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	joystick_base.visible = false
	
	# Connect collision signals
	core_hitbox.body_entered.connect(_on_core_body_entered)
	shield_left.body_entered.connect(_on_shield_left_body_entered)
	shield_right.body_entered.connect(_on_shield_right_body_entered)
	
	# Connect health signal for logging
	health.health_changed.connect(_on_health_changed)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var touch_pos = get_global_mouse_position()
		
		if event.pressed:
			is_dragging = true
			joystick_center = touch_pos
			joystick_base.global_position = joystick_center
			joystick_knob.position = Vector2.ZERO
			joystick_base.visible = true
			joystick_base.modulate.a = 0.5
			joystick_knob.modulate.a = 0.8
		else:
			is_dragging = false
			joystick_base.visible = false
			input_vector = Vector2.ZERO

func _process(delta: float) -> void:
	shield_container.rotate(PI * delta)
	if is_dragging:
		_update_joystick()
	else:
		_update_keyboard_input()

	if input_vector != Vector2.ZERO:
		_move_player(delta)

func _update_joystick() -> void:
	var current_pos = get_global_mouse_position()
	var delta = current_pos - joystick_center
	var distance = delta.length()
	
	if distance > JOYSTICK_MAX_RADIUS:
		delta = delta.normalized() * JOYSTICK_MAX_RADIUS
		distance = JOYSTICK_MAX_RADIUS
	
	joystick_knob.position = delta
	
	if distance > JOYSTICK_DEADZONE:
		input_vector = delta / JOYSTICK_MAX_RADIUS
	else:
		input_vector = Vector2.ZERO

func _update_keyboard_input() -> void:
	var keyboard_vector = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_W):
		keyboard_vector.y -= 1
	if Input.is_key_pressed(KEY_S):
		keyboard_vector.y += 1
	if Input.is_key_pressed(KEY_A):
		keyboard_vector.x -= 1
	if Input.is_key_pressed(KEY_D):
		keyboard_vector.x += 1
	
	input_vector = keyboard_vector.normalized()

func _move_player(delta: float) -> void:
	if input_vector == Vector2.ZERO:
		return
	
	velocity = input_vector * SPEED
	move_and_slide()
	
	# Clamp position within bounds
	global_position.x = clamp(global_position.x, MIN_X, MAX_X)
	global_position.y = clamp(global_position.y, MIN_Y, MAX_Y)

func _on_core_body_entered(body: Node2D) -> void:
	print("[COLLISION] player_core hit by %s (layer: %d, mask: %d)" % [
		body.name,
		body.collision_layer if body is CollisionObject2D else -1,
		body.collision_mask if body is CollisionObject2D else -1
	])
	if body.is_in_group("bullet"):
		health.take_damage()
		body.queue_free()

func _on_shield_left_body_entered(body: Node2D) -> void:
	print("[COLLISION] player_shield_left hit by %s (layer: %d, mask: %d)" % [
		body.name,
		body.collision_layer if body is CollisionObject2D else -1,
		body.collision_mask if body is CollisionObject2D else -1
	])
	_destroy_if_bullet(body)

func _on_shield_right_body_entered(body: Node2D) -> void:
	print("[COLLISION] player_shield_right hit by %s (layer: %d, mask: %d)" % [
		body.name,
		body.collision_layer if body is CollisionObject2D else -1,
		body.collision_mask if body is CollisionObject2D else -1
	])
	_destroy_if_bullet(body)

func _destroy_if_bullet(body: Node2D) -> void:
	if body.is_in_group("bullet"):
		experience.add_xp(experience.get_xp_per_bullet_hit())
		body.queue_free()

func _on_health_changed(current: int, max: int) -> void:
	print("[HEALTH] Health changed: %d/%d" % [current, max])
