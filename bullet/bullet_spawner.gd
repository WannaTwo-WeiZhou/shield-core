extends Node

# 弹幕生成器：被动式 API，由 WaveDirector 调用 fire_pattern() 按弹幕群配置发射子弹。
# 不再持有自己的发射节奏，所有时间参数由 WaveDirector 决定。

@export var bullet_scene: PackedScene

const SCREEN_WIDTH: float = 640.0
const SCREEN_HEIGHT: float = 960.0
const SCREEN_CENTER: Vector2 = Vector2(SCREEN_WIDTH * 0.5, SCREEN_HEIGHT * 0.5)
const SPAWN_MARGIN: float = 50.0

var player: CharacterBody2D
var _bullet_counter: int = 0
var _inflight_token: int = 0


func _ready() -> void:
	player = get_node_or_null("../player")
	if player == null:
		push_warning("[BulletSpawner] 未找到 player 节点，将无法瞄准玩家")


# === 公共 API ==================================================================

# 立即按 pattern 配置发射一组子弹。line_burst 等需要分帧的 pattern 会启动协程。
func fire_pattern(pattern_def: Dictionary, bullet_speed: float) -> void:
	if pattern_def.is_empty():
		return
	if not is_instance_valid(player):
		return
	var shape: String = String(pattern_def.get("shape", "single"))
	match shape:
		"single":
			_fire_single(pattern_def, bullet_speed)
		"fan":
			_fire_fan(pattern_def, bullet_speed)
		"ring":
			_fire_ring(pattern_def, bullet_speed)
		"line_burst":
			_fire_line_burst(pattern_def, bullet_speed)
		_:
			push_warning("[BulletSpawner] 未知 shape: %s" % shape)


# 切换波次时调用：取消进行中的连射，避免上一波的 burst 溢出到新波次。
func cancel_inflight() -> void:
	_inflight_token += 1


# === 形状实现 ==================================================================

func _fire_single(pattern_def: Dictionary, bullet_speed: float) -> void:
	var origin: Vector2 = _resolve_spawn(pattern_def)
	var direction: Vector2 = _resolve_direction(pattern_def, origin)
	_spawn_one(origin, direction, bullet_speed)


func _fire_fan(pattern_def: Dictionary, bullet_speed: float) -> void:
	var count: int = maxi(1, int(pattern_def.get("count", 1)))
	var spread_deg: float = float(pattern_def.get("spread_deg", 0.0))
	var origin: Vector2 = _resolve_spawn(pattern_def)
	var base_dir: Vector2 = _resolve_direction(pattern_def, origin)
	if base_dir == Vector2.ZERO:
		base_dir = Vector2.DOWN
	var spread_rad: float = deg_to_rad(spread_deg)
	for i in range(count):
		var t: float = 0.0 if count == 1 else float(i) / float(count - 1)
		var angle: float = -spread_rad * 0.5 + t * spread_rad
		var dir: Vector2 = base_dir.rotated(angle)
		_spawn_one(origin, dir, bullet_speed)


func _fire_ring(pattern_def: Dictionary, bullet_speed: float) -> void:
	var count: int = maxi(1, int(pattern_def.get("count", 1)))
	var rotation_offset_deg: float = float(pattern_def.get("rotation_offset_deg", 0.0))
	var spawn_distance: float = float(pattern_def.get("spawn_distance", 0.0))
	var center: Vector2 = _resolve_spawn(pattern_def)
	var aim: String = String(pattern_def.get("aim", "outward"))
	var rotation_offset: float = deg_to_rad(rotation_offset_deg)
	for i in range(count):
		var angle: float = TAU * float(i) / float(count) + rotation_offset
		var radial: Vector2 = Vector2.RIGHT.rotated(angle)
		var origin: Vector2 = center + radial * spawn_distance
		var dir: Vector2 = radial
		if aim == "player" and is_instance_valid(player):
			dir = (player.global_position - origin).normalized()
		_spawn_one(origin, dir, bullet_speed)


func _fire_line_burst(pattern_def: Dictionary, bullet_speed: float) -> void:
	_run_line_burst(pattern_def, bullet_speed, _inflight_token)


func _run_line_burst(pattern_def: Dictionary, bullet_speed: float, token: int) -> void:
	var count: int = maxi(1, int(pattern_def.get("count", 1)))
	var interval: float = maxf(0.0, float(pattern_def.get("interval", 0.1)))
	for i in range(count):
		if token != _inflight_token:
			return
		if not is_instance_valid(player):
			return
		var origin: Vector2 = _resolve_spawn(pattern_def)
		var direction: Vector2 = _resolve_direction(pattern_def, origin)
		_spawn_one(origin, direction, bullet_speed)
		if i == count - 1 or interval <= 0.0:
			break
		await get_tree().create_timer(interval, false).timeout


# === 解析 spawn / aim ==========================================================

func _resolve_spawn(pattern_def: Dictionary) -> Vector2:
	var mode: String = String(pattern_def.get("spawn", "edge_random"))
	match mode:
		"edge_random":
			return _edge_random_position()
		"near_player":
			if is_instance_valid(player):
				return player.global_position
			return SCREEN_CENTER
		"screen_center":
			return SCREEN_CENTER
		_:
			return _edge_random_position()


func _resolve_direction(pattern_def: Dictionary, origin: Vector2) -> Vector2:
	var aim: String = String(pattern_def.get("aim", "player"))
	match aim:
		"player":
			if is_instance_valid(player):
				var d: Vector2 = player.global_position - origin
				if d.length_squared() > 0.0:
					return d.normalized()
			return Vector2.DOWN
		"outward":
			var d2: Vector2 = origin - SCREEN_CENTER
			if d2.length_squared() > 0.0:
				return d2.normalized()
			return Vector2.DOWN
		"fixed_down":
			return Vector2.DOWN
		"fixed_up":
			return Vector2.UP
		_:
			return Vector2.DOWN


func _edge_random_position() -> Vector2:
	var edge: int = randi() % 4
	var pos: Vector2 = Vector2.ZERO
	match edge:
		0:
			pos.x = randf_range(SPAWN_MARGIN, SCREEN_WIDTH - SPAWN_MARGIN)
			pos.y = -SPAWN_MARGIN
		1:
			pos.x = SCREEN_WIDTH + SPAWN_MARGIN
			pos.y = randf_range(SPAWN_MARGIN, SCREEN_HEIGHT - SPAWN_MARGIN)
		2:
			pos.x = randf_range(SPAWN_MARGIN, SCREEN_WIDTH - SPAWN_MARGIN)
			pos.y = SCREEN_HEIGHT + SPAWN_MARGIN
		3:
			pos.x = -SPAWN_MARGIN
			pos.y = randf_range(SPAWN_MARGIN, SCREEN_HEIGHT - SPAWN_MARGIN)
	return pos


# === 子弹实例化 ================================================================

func _spawn_one(spawn_pos: Vector2, direction: Vector2, bullet_speed: float) -> void:
	if bullet_scene == null:
		push_error("[BulletSpawner] bullet_scene 未配置")
		return
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	_bullet_counter += 1
	var bullet: Node = bullet_scene.instantiate()
	bullet.name = "bullet_%d" % _bullet_counter
	bullet.global_position = spawn_pos
	if bullet.has_method("init"):
		bullet.init(spawn_pos, direction.normalized(), bullet_speed)
	get_parent().add_child(bullet)
