# 暂停按钮 + 暂停覆盖界面
# 右上角悬浮按钮，点击后暂停游戏并显示暂停菜单
extends CanvasLayer

@onready var pause_button: Button = %pause_button
@onready var pause_overlay: ColorRect = %pause_overlay
@onready var resume_button: Button = %resume_button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_button.pressed.connect(_on_pause_pressed)
	resume_button.pressed.connect(_on_resume_pressed)
	pause_overlay.hide()


func _on_pause_pressed() -> void:
	get_tree().paused = true
	pause_overlay.show()
	pause_button.hide()


func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_overlay.hide()
	pause_button.show()
