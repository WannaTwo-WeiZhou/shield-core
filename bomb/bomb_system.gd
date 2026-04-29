# B 弹（清屏炸弹）系统
# 核心逻辑：双击/按 Space 触发清屏，随时间恢复充能。
# 作为 main.tscn 的子节点挂载（非 Autoload）。
extends Node

const DOUBLE_TAP_TIME: float = 0.28
const DOUBLE_TAP_DISTANCE: float = 60.0
const WHITE_FLASH_DURATION: float = 0.15
const WHITE_FLASH_ALPHA_MAX: float = 0.6
# Mobile browsers synthesize a MouseButton event immediately after ScreenTouch;
# suppress it to avoid a single tap being counted twice.
const TOUCH_TO_MOUSE_SUPPRESS_SECS: float = 0.5

var current_charges: int = 3 : get = get_current_charges
var max_charges: int = 3
var recharge_seconds: float = 30.0

var _recharge_timer: float = 0.0
var _white_flash_timer: float = 0.0
var _enabled: bool = true

# Touch double-tap state (InputEventScreenTouch only)
var _last_tap_time: float = -1.0
var _last_tap_position: Vector2 = Vector2.ZERO
# Mouse double-tap state (InputEventMouseButton only, kept separate to avoid cross-contamination)
var _last_mouse_tap_time: float = -1.0
var _last_mouse_tap_position: Vector2 = Vector2.ZERO
# Last real ScreenTouch timestamp, used to suppress synthetic mouse events that follow touch.
var _last_touch_event_time: float = -1.0

# 白屏闪
var _white_flash: ColorRect = null


func _ready() -> void:
	_refresh_from_pipeline()
	_setup_white_flash()
	reset()


func _setup_white_flash() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 300
	canvas.name = "bomb_flash_canvas"
	add_child(canvas)

	var rect := ColorRect.new()
	rect.name = "white_flash"
	rect.color = Color.WHITE
	rect.modulate.a = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	_white_flash = rect


func _input(event: InputEvent) -> void:
	if not _enabled:
		return

	var now := Time.get_ticks_msec() / 1000.0

	if event is InputEventScreenTouch and event.pressed:
		# Real touch event — record time and run touch double-tap check.
		_last_touch_event_time = now
		_handle_tap(now, event.position, true)
	elif event is InputEventMouseButton and event.pressed:
		# Suppress synthetic MouseButton injected by Godot's "emulate mouse from touch"
		# or by the browser. The synthetic event arrives within milliseconds of the real
		# ScreenTouch, so any MouseButton within 0.5 s of the last ScreenTouch is ignored.
		if now - _last_touch_event_time < TOUCH_TO_MOUSE_SUPPRESS_SECS:
			return
		_handle_tap(now, get_viewport().get_mouse_position(), false)


# Handle one press event for double-tap detection.
# is_touch=true  → uses the touch state  (_last_tap_time / _last_tap_position)
# is_touch=false → uses the mouse state  (_last_mouse_tap_time / _last_mouse_tap_position)
# Touch and mouse states are kept separate so a synthetic mouse event generated from a
# touch can never pair with a real mouse event (or vice-versa) to produce a false double-tap.
func _handle_tap(now: float, pos: Vector2, is_touch: bool) -> void:
	if current_charges <= 0:
		if is_touch:
			_last_tap_time = -1.0
		else:
			_last_mouse_tap_time = -1.0
		return

	var last_time := _last_tap_time if is_touch else _last_mouse_tap_time
	var last_pos  := _last_tap_position if is_touch else _last_mouse_tap_position

	if last_time >= 0.0 and (now - last_time) <= DOUBLE_TAP_TIME:
		if pos.distance_to(last_pos) <= DOUBLE_TAP_DISTANCE:
			_trigger_bomb()
			get_viewport().set_input_as_handled()
			if is_touch:
				_last_tap_time = -1.0
			else:
				_last_mouse_tap_time = -1.0
			return

	if is_touch:
		_last_tap_time = now
		_last_tap_position = pos
	else:
		_last_mouse_tap_time = now
		_last_mouse_tap_position = pos


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return
	if current_charges <= 0:
		return

	# 键盘 Space 键触发
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		_trigger_bomb()
		get_viewport().set_input_as_handled()
		return


func _process(delta: float) -> void:
	if not _enabled:
		return

	# 充能
	if current_charges < max_charges:
		_recharge_timer += delta
		while _recharge_timer >= recharge_seconds and current_charges < max_charges:
			_recharge_timer -= recharge_seconds
			current_charges += 1
			EventBus.on_bomb_charges_changed.emit({
				"charges": current_charges,
				"max": max_charges,
				"recharge_progress": _recharge_timer / recharge_seconds if current_charges < max_charges else 1.0
			})
	else:
		_recharge_timer = 0.0

	# 白屏闪渐隐
	if _white_flash_timer > 0.0:
		_white_flash_timer -= delta
		var t: float = clampf(_white_flash_timer / WHITE_FLASH_DURATION, 0.0, 1.0)
		_white_flash.modulate.a = lerp(0.0, WHITE_FLASH_ALPHA_MAX, t)
		if _white_flash_timer <= 0.0:
			_white_flash.modulate.a = 0.0


func _trigger_bomb() -> void:
	if not _enabled or current_charges <= 0:
		return

	current_charges -= 1
	_recharge_timer = 0.0

	# 清屏：遍历 bullet 组，跳过 player_bullet
	for bullet in get_tree().get_nodes_in_group("bullet"):
		if bullet.is_queued_for_deletion():
			continue
		if bullet.is_in_group("player_bullet"):
			continue
		bullet.queue_free()

	# 取消 spawner in-flight 连射协程
	var spawner = get_node_or_null("../bullet_spawner")
	if spawner and spawner.has_method("cancel_inflight"):
		spawner.cancel_inflight()

	# 白屏闪
	_white_flash.modulate.a = WHITE_FLASH_ALPHA_MAX
	_white_flash_timer = WHITE_FLASH_DURATION

	# 发射事件
	EventBus.on_bomb_used.emit({"charges_remaining": current_charges})
	EventBus.on_bomb_charges_changed.emit({
		"charges": current_charges,
		"max": max_charges,
		"recharge_progress": 0.0
	})

	print("[BOMB] B 弹触发，剩余 %d/%d 发" % [current_charges, max_charges])


func _refresh_from_pipeline() -> void:
	var capacity_bonus := int(AbilityManager.pipeline.get_attribute("bomb_capacity_bonus"))
	max_charges = 3 + capacity_bonus

	var recharge_bonus := AbilityManager.pipeline.get_attribute("bomb_recharge_seconds_bonus")
	recharge_seconds = maxf(1.0, 30.0 - recharge_bonus)


func disable() -> void:
	_enabled = false
	_white_flash.modulate.a = 0.0


func reset() -> void:
	current_charges = max_charges
	_recharge_timer = 0.0
	_white_flash.modulate.a = 0.0
	_white_flash_timer = 0.0
	_enabled = true
	_last_tap_time = -1.0
	_last_mouse_tap_time = -1.0
	_last_touch_event_time = -1.0
	EventBus.on_bomb_charges_changed.emit({
		"charges": current_charges,
		"max": max_charges,
		"recharge_progress": 1.0
	})


func get_current_charges() -> int:
	return current_charges


func get_recharge_progress() -> float:
	if current_charges >= max_charges:
		return 1.0
	return clampf(_recharge_timer / recharge_seconds, 0.0, 1.0)
