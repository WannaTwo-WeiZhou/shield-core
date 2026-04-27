# 单张能力卡片，显示在三选一界面中。
extends PanelContainer

const AbilityDefinition = preload("res://ability/ability_definition.gd")

signal card_selected(ability_id: String)

@onready var name_label: Label = $VBoxContainer/name_label
@onready var rarity_label: Label = $VBoxContainer/rarity_label
@onready var desc_label: Label = $VBoxContainer/desc_label
@onready var level_label: Label = $VBoxContainer/level_label

var _ability_id: String = ""


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		accept_event()
		_select()


func setup(def: AbilityDefinition) -> void:
	_ability_id = def.id
	name_label.text = def.display_name
	rarity_label.text = "【%s】" % def.rarity_label()
	desc_label.text = def.description
	level_label.text = "可重复获得" if def.repeatable else "唯一能力（不可升级）"

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


func _select() -> void:
	card_selected.emit(_ability_id)
