class_name Health
extends Node

signal health_changed(current: int, max: int)
signal health_depleted()

@export var max_health: int = 100
@export var damage_per_hit: int = 10

var current_health: int:
	set(value):
		var old = current_health
		current_health = clamp(value, 0, max_health)
		if old != current_health:
			health_changed.emit(current_health, max_health)
			if current_health <= 0:
				health_depleted.emit()

func _ready() -> void:
	reset()

func take_damage(amount: int = damage_per_hit) -> void:
	current_health -= amount

func heal(amount: int) -> void:
	current_health += amount

func set_max_health(value: int) -> void:
	var old_max := max_health
	var old_current := current_health
	max_health = maxi(1, value)
	current_health = clamp(old_current, 0, max_health)
	if old_max != max_health and old_current == current_health:
		health_changed.emit(current_health, max_health)

func reset() -> void:
	current_health = max_health
