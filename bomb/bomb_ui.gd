extends CanvasLayer

const Bomb = preload("res://bomb/bomb.gd")

@onready var container: HBoxContainer = $Container
var player: CharacterBody2D
var bomb: Bomb

# B弹图标的场景（运行时动态创建）
var _bomb_icons: Array[ColorRect] = []

const ICON_SIZE: Vector2 = Vector2(30, 30)
const ICON_SPACING: float = 10.0
const AVAILABLE_COLOR: Color = Color(1.0, 0.8, 0.0, 1.0)  # 金色：可用
const UNAVAILABLE_COLOR: Color = Color(0.3, 0.3, 0.3, 0.5)  # 灰色：不可用
const RECHARGING_COLOR: Color = Color(0.6, 0.5, 0.0, 0.8)  # 暗金色：恢复中

func _ready() -> void:
	player = get_node("/root/main/player")
	bomb = player.get_node("bomb")

	# 连接信号
	bomb.bomb_count_changed.connect(_on_bomb_count_changed)

	# 创建B弹图标
	_create_bomb_icons(bomb.max_bombs)
	_update_bomb_display(bomb.current_bombs)

func _process(_delta: float) -> void:
	# 更新恢复进度显示
	if bomb.current_bombs < bomb.max_bombs:
		_update_recharge_progress()

func _create_bomb_icons(count: int) -> void:
	for i in range(count):
		var icon = ColorRect.new()
		icon.custom_minimum_size = ICON_SIZE
		icon.color = AVAILABLE_COLOR
		container.add_child(icon)
		_bomb_icons.append(icon)

func _update_bomb_display(available_bombs: int) -> void:
	for i in range(_bomb_icons.size()):
		if i < available_bombs:
			_bomb_icons[i].color = AVAILABLE_COLOR
		else:
			_bomb_icons[i].color = UNAVAILABLE_COLOR

func _update_recharge_progress() -> void:
	# 最左侧的不可用图标显示恢复进度
	var first_unavailable_idx = bomb.current_bombs
	if first_unavailable_idx < _bomb_icons.size():
		var progress = bomb.get_recharge_progress()
		# 插值颜色来显示恢复进度
		_bomb_icons[first_unavailable_idx].color = UNAVAILABLE_COLOR.lerp(RECHARGING_COLOR, progress)

func _on_bomb_count_changed(current: int, _max: int) -> void:
	_update_bomb_display(current)
