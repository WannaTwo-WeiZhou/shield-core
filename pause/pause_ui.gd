# 暂停按钮 + 暂停覆盖界面
# 右上角悬浮按钮，点击后暂停游戏并显示暂停菜单
# GM 模式：从暂停界面进入，直接获取任意能力
extends CanvasLayer

const AbilityDefinition = preload("res://ability/ability_definition.gd")

@onready var pause_button: Button = %pause_button
@onready var pause_overlay: ColorRect = %pause_overlay
@onready var resume_button: Button = %resume_button
@onready var pause_menu_vbox: VBoxContainer = %PauseMenuVBox
@onready var gm_button: Button = %gm_button
@onready var gm_panel: CenterContainer = %gm_panel
@onready var gm_back_button: Button = %gm_back_button
@onready var gm_ability_list: VBoxContainer = %gm_ability_list

var _ability_list_built: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	gm_button.pressed.connect(_on_gm_pressed)
	gm_back_button.pressed.connect(_on_gm_back_pressed)
	pause_overlay.hide()


func _on_pause_pressed() -> void:
	get_tree().paused = true
	pause_overlay.show()
	pause_button.hide()


func _on_resume_pressed() -> void:
	_close_pause()


func _on_gm_pressed() -> void:
	if not _ability_list_built:
		_build_ability_list()
		_ability_list_built = true
	pause_menu_vbox.hide()
	gm_panel.show()


func _on_gm_back_pressed() -> void:
	gm_panel.hide()
	pause_menu_vbox.show()


func _on_gm_ability_selected(ability_id: String) -> void:
	AbilityManager.select_ability(ability_id)
	_close_pause()


func _close_pause() -> void:
	get_tree().paused = false
	pause_overlay.hide()
	pause_button.show()


func _build_ability_list() -> void:
	# 清空旧内容
	for child in gm_ability_list.get_children():
		child.queue_free()

	# 从 AbilityManager 读取所有能力定义
	var ability_ids: Array = AbilityManager.get_all_definition_ids()
	ability_ids.sort()

	for ability_id_variant in ability_ids:
		var ability_id := String(ability_id_variant)
		var def: AbilityDefinition = AbilityManager.get_ability_definition(ability_id)
		if def == null:
			continue
		var btn := Button.new()
		btn.text = "%s\n%s" % [def.display_name, def.description]
		btn.flat = false
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(360, 72)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.tooltip_text = def.description

		# 样式
		var theme_normal := StyleBoxFlat.new()
		theme_normal.bg_color = Color(0.25, 0.25, 0.3, 0.8)
		theme_normal.corner_radius_top_left = 6
		theme_normal.corner_radius_top_right = 6
		theme_normal.corner_radius_bottom_right = 6
		theme_normal.corner_radius_bottom_left = 6

		var theme_hover := StyleBoxFlat.new()
		theme_hover.bg_color = Color(0.35, 0.35, 0.45, 0.85)
		theme_hover.corner_radius_top_left = 6
		theme_hover.corner_radius_top_right = 6
		theme_hover.corner_radius_bottom_right = 6
		theme_hover.corner_radius_bottom_left = 6

		btn.add_theme_stylebox_override("normal", theme_normal)
		btn.add_theme_stylebox_override("hover", theme_hover)
		btn.add_theme_stylebox_override("pressed", theme_hover)

		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))

		var captured_id: String = ability_id
		btn.pressed.connect(func():
			_on_gm_ability_selected(captured_id)
		)

		gm_ability_list.add_child(btn)
