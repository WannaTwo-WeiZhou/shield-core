class_name Experience
extends Node

signal xp_changed(current_xp: int, max_xp: int, level: int)
signal level_up(new_level: int)

const CONFIG_PATH: String = "res://experience/experience_config.json"

var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 0
var xp_per_bullet_hit: int = 10
var _level_requirements: Dictionary = {}

func _ready() -> void:
	_load_config()
	xp_to_next_level = _get_level_requirement(current_level)
	xp_changed.emit(current_xp, xp_to_next_level, current_level)

func _load_config() -> void:
	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			var data = json.data
			if data.has("level_requirements"):
				_level_requirements = data["level_requirements"]
			if data.has("xp_per_bullet_hit"):
				xp_per_bullet_hit = data["xp_per_bullet_hit"]
		else:
			push_error("Failed to parse experience config: %s" % json.get_error_message())
			_use_default_config()
	else:
		push_error("Failed to load experience config from: %s" % CONFIG_PATH)
		_use_default_config()

func _use_default_config() -> void:
	_level_requirements = {
		"1": 100,
		"2": 120,
		"3": 145,
		"4": 175,
		"5": 210
	}
	xp_per_bullet_hit = 10

func _get_level_requirement(level: int) -> int:
	var key = str(level)
	if _level_requirements.has(key):
		return _level_requirements[key]
	# Fallback: extrapolate based on last known value
	var max_known_level = 1
	for k in _level_requirements.keys():
		var lvl = int(k)
		if lvl > max_known_level:
			max_known_level = lvl
	var last_requirement = _level_requirements.get(str(max_known_level), 100)
	var growth_rate = 1.2
	return int(last_requirement * pow(growth_rate, level - max_known_level))

func add_xp(amount: int) -> void:
	current_xp += amount
	print("[XP] Gained %d XP, current: %d/%d (Level %d)" % [amount, current_xp, xp_to_next_level, current_level])
	
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		current_level += 1
		xp_to_next_level = _get_level_requirement(current_level)
		print("[LEVEL UP] Level %d! Next level requires %d XP" % [current_level, xp_to_next_level])
		level_up.emit(current_level)
	
	xp_changed.emit(current_xp, xp_to_next_level, current_level)

func get_xp_per_bullet_hit() -> int:
	return xp_per_bullet_hit
