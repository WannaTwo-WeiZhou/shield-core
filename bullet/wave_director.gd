extends Node

# 弹幕波次驱动器：从 wave_config.json 读取波次与弹幕群（pattern）配置，
# 驱动 BulletSpawner 在每一波的发射阶段按指定 pattern 发射弹幕群。
#
# 波次状态机：PREP --(prep_time)--> FIRING --(duration)--> 下一波 PREP
# 当跑完最后一波后从 loop_from_wave 折回，并按 loop_speed_step / loop_interval_mul 递增难度。

const CONFIG_PATH: String = "res://bullet/wave_config.json"
const WAIT_STEP_SEC: float = 0.05

@export var spawner_path: NodePath = NodePath("../bullet_spawner")
@export var debug_skip_key: bool = false

var _patterns: Dictionary = {}
var _waves: Array = []
var _loop_from_wave: int = 0
var _loop_speed_step: float = 0.0
var _loop_interval_mul: float = 1.0

var _spawner: Node = null
var _current_index: int = 0
var _loop_count: int = 0
var _running: bool = true
var _state: String = "idle"  # idle / prep / firing
var _phase_token: int = 0
var _skip_cooldown: float = 0.0


func _ready() -> void:
	_spawner = get_node_or_null(spawner_path)
	if _spawner == null:
		push_error("[WaveDirector] 未找到 BulletSpawner: %s" % spawner_path)
		return
	_load_config()
	if _waves.is_empty():
		push_warning("[WaveDirector] 波次配置为空，弹幕系统不会生成子弹")
		return
	_run_wave_loop()


func _load_config() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("[WaveDirector] 无法打开 %s" % CONFIG_PATH)
		return
	var json := JSON.new()
	var parse_err := json.parse(file.get_as_text())
	file.close()
	if parse_err != OK:
		push_error("[WaveDirector] 解析失败: %s" % json.get_error_message())
		return
	var data: Dictionary = json.data
	_patterns = data.get("patterns", {})
	_waves = data.get("waves", [])
	_loop_from_wave = int(data.get("loop_from_wave", 0))
	_loop_speed_step = float(data.get("loop_speed_step", 0.0))
	_loop_interval_mul = float(data.get("loop_interval_mul", 1.0))
	print("[WaveDirector] 配置加载完成：%d 个 pattern，%d 个 wave" % [
		_patterns.size(),
		_waves.size()
	])


func _run_wave_loop() -> void:
	while _running:
		if _waves.is_empty():
			return
		if _current_index >= _waves.size():
			_current_index = clampi(_loop_from_wave, 0, _waves.size() - 1)
			_loop_count += 1
			print("[WaveDirector] 进入第 %d 轮循环，回到第 %d 波" % [_loop_count, _current_index])
		await _execute_wave(_current_index)
		_current_index += 1


func _execute_wave(index: int) -> void:
	var wave_def: Dictionary = _waves[index]
	var wave_id: String = String(wave_def.get("id", "w%d" % index))
	var prep_time: float = maxf(0.0, float(wave_def.get("prep_time", 0.0)))
	var duration: float = maxf(0.0, float(wave_def.get("duration", 0.0)))
	var fire_interval_base: float = maxf(0.05, float(wave_def.get("fire_interval", 1.0)))
	var bullet_speed_base: float = float(wave_def.get("bullet_speed", 100.0))
	var pattern_id: String = String(wave_def.get("pattern", ""))
	var pattern_def: Dictionary = _patterns.get(pattern_id, {})
	if pattern_def.is_empty():
		push_warning("[WaveDirector] 波次 %s 引用的 pattern 不存在: %s" % [wave_id, pattern_id])

	var fire_interval: float = maxf(0.05, fire_interval_base * pow(_loop_interval_mul, _loop_count))
	var bullet_speed: float = bullet_speed_base + _loop_speed_step * _loop_count

	_phase_token += 1
	var token: int = _phase_token

	# === PREP ===
	_state = "prep"
	EventBus.on_wave_prep_started.emit({
		"wave_id": wave_id,
		"index": index,
		"loop": _loop_count,
		"prep_time": prep_time,
		"duration": duration,
		"pattern_id": pattern_id,
	})
	print("[WaveDirector] 准备波次 %s（loop=%d）：prep=%.1fs，duration=%.1fs，interval=%.2fs，speed=%.0f，pattern=%s" % [
		wave_id, _loop_count, prep_time, duration, fire_interval, bullet_speed, pattern_id
	])
	var prep_cancelled: bool = await _wait_seconds(prep_time, token)
	if prep_cancelled or not _running:
		_state = "idle"
		return

	# === FIRING ===
	_state = "firing"
	EventBus.on_wave_started.emit({
		"wave_id": wave_id,
		"index": index,
		"loop": _loop_count,
		"duration": duration,
		"fire_interval": fire_interval,
		"bullet_speed": bullet_speed,
		"pattern_id": pattern_id,
	})
	print("[WaveDirector] 开始发射 %s" % wave_id)

	var elapsed: float = 0.0
	while elapsed < duration and _running and _phase_token == token:
		if _spawner != null and _spawner.has_method("fire_pattern"):
			_spawner.fire_pattern(pattern_def, bullet_speed)
		var step: float = minf(fire_interval, maxf(0.0, duration - elapsed))
		if step <= 0.0:
			break
		var cancelled: bool = await _wait_seconds(step, token)
		if cancelled:
			break
		elapsed += step

	# 切到下一波前清理 spawner 中尚未发射完的 burst
	if _spawner != null and _spawner.has_method("cancel_inflight"):
		_spawner.cancel_inflight()

	EventBus.on_wave_ended.emit({
		"wave_id": wave_id,
		"index": index,
		"loop": _loop_count,
	})
	print("[WaveDirector] 波次结束 %s" % wave_id)
	_state = "idle"


# 可被 _phase_token 变化中断的等待。返回 true 表示被中断。
func _wait_seconds(seconds: float, token: int) -> bool:
	var remaining: float = seconds
	while remaining > 0.0:
		if _phase_token != token or not _running:
			return true
		var step: float = minf(WAIT_STEP_SEC, remaining)
		await get_tree().create_timer(step, false).timeout
		remaining -= step
	return false


# ─── 调试接口 ─────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _skip_cooldown > 0.0:
		_skip_cooldown -= delta
	if debug_skip_key and Input.is_key_pressed(KEY_N) and _skip_cooldown <= 0.0:
		_request_skip_to_next_wave()


func _request_skip_to_next_wave() -> void:
	_skip_cooldown = 0.5
	_phase_token += 1
	if _spawner != null and _spawner.has_method("cancel_inflight"):
		_spawner.cancel_inflight()
	print("[WaveDirector] 调试：手动跳到下一波")


func stop() -> void:
	_running = false
	_phase_token += 1
	if _spawner != null and _spawner.has_method("cancel_inflight"):
		_spawner.cancel_inflight()
