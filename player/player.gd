extends CharacterBody2D

const Experience = preload("res://experience/experience.gd")
const Health = preload("res://health/health.gd")
const AbilityInstance = preload("res://ability/ability_instance.gd")

const BASE_SPEED: float = 400.0
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

# 生命恢复计时器（由 health_regen 能力驱动）
var _regen_timer: float = 0.0

func _ready() -> void:
	joystick_base.visible = false

	# Connect collision signals
	core_hitbox.body_entered.connect(_on_core_body_entered)
	shield_left.body_entered.connect(_on_shield_left_body_entered)
	shield_right.body_entered.connect(_on_shield_right_body_entered)

	# Connect health signal for logging
	health.health_changed.connect(_on_health_changed)

	# 注册到能力管理器，使能力效果可访问玩家
	AbilityManager.register_player(self)

	# 订阅能力变更事件，刷新属性
	AbilityManager.abilities_updated.connect(_on_abilities_updated)


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

	# 测试功能：U 键直接触发升级
	if Input.is_key_pressed(KEY_U):
		AbilityManager.on_player_level_up()

	if input_vector != Vector2.ZERO:
		_move_player(delta)

	_process_health_regen(delta)


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

	# 应用速度加成（来自 speed_boost 等能力）
	var speed := BASE_SPEED + AbilityManager.pipeline.get_attribute("speed_bonus")
	velocity = input_vector * speed
	move_and_slide()

	# Clamp position within bounds
	global_position.x = clamp(global_position.x, MIN_X, MAX_X)
	global_position.y = clamp(global_position.y, MIN_Y, MAX_Y)


# ─── 生命恢复 ──────────────────────────────────────────────────────────────

func _process_health_regen(delta: float) -> void:
	var inst := AbilityManager.get_instance("health_regen")
	if inst == null:
		return
	var data := inst.get_current_data()
	var interval: float = data.get("regen_interval", 5.0)
	_regen_timer += delta
	if _regen_timer >= interval:
		_regen_timer = 0.0
		var amount: int = int(data.get("regen_amount", 2))
		health.heal(amount)
		print("[REGEN] 恢复 %d 点生命，当前: %d/%d" % [amount, health.current_health, health.max_health])


# ─── 碰撞处理 ───────────────────────────────────────────────────────────────────

func _on_core_body_entered(body: Node2D) -> void:
	print("[COLLISION] player_core hit by %s (layer: %d, mask: %d)" % [
		body.name,
		body.collision_layer if body is CollisionObject2D else -1,
		body.collision_mask if body is CollisionObject2D else -1
	])
	if body.is_in_group("bullet"):
		health.take_damage()
		EventBus.emit_take_damage(self, health.damage_per_hit)
		body.queue_free()


func _on_shield_left_body_entered(body: Node2D) -> void:
	print("[COLLISION] player_shield_left hit by %s (layer: %d, mask: %d)" % [
		body.name,
		body.collision_layer if body is CollisionObject2D else -1,
		body.collision_mask if body is CollisionObject2D else -1
	])
	_handle_shield_hit(body, shield_left)


func _on_shield_right_body_entered(body: Node2D) -> void:
	print("[COLLISION] player_shield_right hit by %s (layer: %d, mask: %d)" % [
		body.name,
		body.collision_layer if body is CollisionObject2D else -1,
		body.collision_mask if body is CollisionObject2D else -1
	])
	_handle_shield_hit(body, shield_right)


func _handle_shield_hit(body: Node2D, shield: Area2D) -> void:
	if not body.is_in_group("bullet"):
		return

	# ── 暴击格挡：有几率双倍 XP ────────────────────────────────────────────────────────
	var xp_multiplier := 1
	var crit_inst := AbilityManager.get_instance("crit_block")
	if crit_inst != null:
		var crit_data := crit_inst.get_current_data()
		if randf() < crit_data.get("crit_chance", 0.0):
			xp_multiplier = 2
			print("[CRIT BLOCK] 暴击格挡！双倍 XP")

	var base_xp := experience.get_xp_per_bullet_hit()
	var block_xp := base_xp * xp_multiplier
	experience.add_xp(block_xp)

	# ── 发射格挡事件 + 统一消费 on_block 修饰器
	var block_ctx := EventBus.emit_block(self, body, {
		"shield": shield,
		"xp_awarded": block_xp
	})
	_apply_event_modifiers("on_block", block_ctx)

	# ── 盾反：将子弹反弹
	var reflect_inst := AbilityManager.get_instance("shield_reflect")
	if reflect_inst != null:
		var reflect_data := reflect_inst.get_current_data()
		if randf() < reflect_data.get("reflect_chance", 0.0):
			_reflect_bullet(body, shield)
			_apply_event_modifiers("on_reflect", {
				"player": self,
				"bullet": body,
				"shield": shield
			})
			return  # 已反弹，不销毁

	body.queue_free()


func _reflect_bullet(bullet: Node2D, shield: Area2D) -> void:
	# 以盾牌中心为法线，将子弹方向反转
	var to_bullet: Vector2 = (bullet.global_position - shield.global_position).normalized()
	if "direction" in bullet:
		# 重新设置方向：朝离开盾牌的方向
		bullet.direction = to_bullet
		bullet.rotation = to_bullet.angle()
		bullet.add_to_group("player_bullet")
		if "speed" in bullet:
			# 预留属性通道：联动可进一步二次改写 speed
			bullet.speed = bullet.speed + AbilityManager.pipeline.get_attribute("bullet_speed_bonus")
		print("[REFLECT] 子弹被反弹！方向: %s" % to_bullet)
	else:
		bullet.queue_free()


func _apply_event_modifiers(event_name: String, context: Dictionary) -> void:
	for modifier: Dictionary in AbilityManager.pipeline.get_event_modifiers(event_name):
		_apply_single_event_modifier(event_name, modifier, context)


func _apply_single_event_modifier(event_name: String, modifier: Dictionary, context: Dictionary) -> void:
	var action: String = modifier.get("action", "")
	match action:
		"heal":
			var amount := int(modifier.get("amount", 0))
			if amount > 0:
				health.heal(amount)
				print("[EVENT:%s] 恢复 %d 点生命" % [event_name, amount])
		"bonus_xp":
			var amount := int(modifier.get("amount", 0))
			if amount > 0:
				experience.add_xp(amount)
				print("[EVENT:%s] 额外获得 %d XP" % [event_name, amount])
		"reflect_speed_multiplier":
			var bullet = context.get("bullet", null)
			if bullet != null and "speed" in bullet:
				var multiplier := float(modifier.get("multiplier", 1.0))
				bullet.speed = bullet.speed * multiplier
				print("[EVENT:%s] 反弹子弹速度 x%.2f" % [event_name, multiplier])
		"burn_on_reflect":
			var bullet = context.get("bullet", null)
			if bullet != null:
				bullet.set_meta("burn_on_hit", true)
				bullet.set_meta("burn_damage", int(modifier.get("burn_damage", 0)))
				bullet.set_meta("burn_duration", float(modifier.get("burn_duration", 0.0)))
				print("[EVENT:%s] 反弹子弹附带燃烧标记" % event_name)
		_:
			push_warning("[Player] 未支持的事件修饰动作: %s" % action)


func _on_health_changed(current: int, max: int) -> void:
	print("[HEALTH] Health changed: %d/%d" % [current, max])


# ─── 能力变更回调 ──────────────────────────────────────────────────────────────────

func _on_abilities_updated() -> void:
	print("[Player] 能力已更新，当前标签: %s" % AbilityManager.get_all_tags())
