extends CharacterBody2D

const SPEED: float = 400.0
const MIN_X: float = 40.0
const MAX_X: float = 600.0
const MIN_Y: float = 40.0
const MAX_Y: float = 920.0

const JOYSTICK_MAX_RADIUS: float = 60.0
const JOYSTICK_DEADZONE: float = 10.0

@onready var joystick_base: Sprite2D = $joystick_base
@onready var joystick_knob: Sprite2D = $joystick_base/joystick_knob
@onready var shield_container: Marker2D = $shield_container

var is_dragging: bool = false
var joystick_center: Vector2 = Vector2.ZERO
var input_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
	joystick_base.visible = false

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

func _move_player(delta: float) -> void:
	if input_vector == Vector2.ZERO:
		return
	
	velocity = input_vector * SPEED
	move_and_slide()
	
	# Clamp position within bounds
	global_position.x = clamp(global_position.x, MIN_X, MAX_X)
	global_position.y = clamp(global_position.y, MIN_Y, MAX_Y)
