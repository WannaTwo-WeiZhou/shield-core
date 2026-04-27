# 单张能力卡片，显示在三选一界面中。
extends PanelContainer

const AbilityDefinition = preload("res://ability/ability_definition.gd")

signal card_selected(ability_id: String)

@onready var name_label: Label = $VBoxContainer/name_label
@onready var rarity_label: Label = $VBoxContainer/rarity_label
@onready var desc_label: Label = $VBoxContainer/desc_label
@onready var level_label: Label = $VBoxContainer/level_label

var _ability_id: String = ""


func setup(def: AbilityDefinition, current_level: int) -> void:
	_ability_id = def.id
	name_label.text = def.display_name
	rarity_label.text = "【%s】" % def.rarity_label()
	desc_label.text = def.description

	if current_level > 0:
		level_label.text = "Lv %d → %d（当前已持有）" % [current_level, current_level + 1]
	else:
		level_label.text = "新能力"

	# 根据稀有度设置卡片颜色
	match def.rarity:
		1:
			add_theme_stylebox_override("panel", _make_panel(Color(0.2, 0.2, 0.2, 0.9)))
		2:
			add_theme_stylebox_override("panel", _make_panel(Color(0.1, 0.2, 0.35, 0.9)))
		3:
			add_theme_stylebox_override("panel", _make_panel(Color(0.25, 0.1, 0.3, 0.9)))


func _make_panel(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.7, 0.7, 0.7, 0.6)
	return style


func _on_button_pressed() -> void:
	card_selected.emit(_ability_id)
