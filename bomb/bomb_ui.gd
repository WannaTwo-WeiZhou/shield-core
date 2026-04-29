# B 弹 UI：显示充能格数和进度条
extends CanvasLayer

@onready var bomb_system: Node = get_node("/root/main/bomb_system")

const CHARGE_ICON_SIZE: float = 32.0
const CHARGE_GAP: float = 4.0

var _charge_icons: Array = []


func _ready() -> void:
	_setup_charge_icons()
	EventBus.on_bomb_charges_changed.connect(_on_charges_changed)


func _setup_charge_icons() -> void:
	var max_charges: int = bomb_system.max_charges
	for i in range(max_charges):
		var rect := ColorRect.new()
		rect.name = "charge_%d" % i
		rect.color = Color(0.8, 0.8, 0.8, 0.3) if i >= bomb_system.current_charges else Color(0.2, 0.8, 1.0, 0.9)
		rect.size = Vector2(CHARGE_ICON_SIZE, CHARGE_ICON_SIZE)
		rect.position = Vector2(120.0 + i * (CHARGE_ICON_SIZE + CHARGE_GAP), 50.0)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_charge_icons.append(rect)

	# 进度条（显示在当前有充能的那一格上方）
	var progress_bar := ColorRect.new()
	progress_bar.name = "recharge_progress"
	progress_bar.color = Color(0.2, 0.8, 1.0, 0.5)
	progress_bar.size = Vector2(CHARGE_ICON_SIZE, 4.0)
	progress_bar.position = Vector2(120.0, 46.0)
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(progress_bar)


func _process(_delta: float) -> void:
	if not is_instance_valid(bomb_system):
		return
	var progress: float = bomb_system.get_recharge_progress()
	var progress_bar := get_node_or_null("recharge_progress") as ColorRect
	if progress_bar:
		progress_bar.size.x = CHARGE_ICON_SIZE * progress


func _on_charges_changed(context: Dictionary) -> void:
	if not is_instance_valid(bomb_system):
		return

	var charges: int = context.get("charges", bomb_system.current_charges)
	var max_c: int = context.get("max", bomb_system.max_charges)

	# 动态调整充能格数量
	while _charge_icons.size() < max_c:
		var rect := ColorRect.new()
		rect.name = "charge_%d" % _charge_icons.size()
		rect.color = Color(0.8, 0.8, 0.8, 0.3)
		rect.size = Vector2(CHARGE_ICON_SIZE, CHARGE_ICON_SIZE)
		rect.position = Vector2(120.0 + _charge_icons.size() * (CHARGE_ICON_SIZE + CHARGE_GAP), 50.0)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_charge_icons.append(rect)
	while _charge_icons.size() > max_c:
		var old: ColorRect = _charge_icons.pop_back()
		old.queue_free()

	for i in range(_charge_icons.size()):
		var icon := _charge_icons[i] as ColorRect
		if i >= charges:
			icon.color = Color(0.8, 0.8, 0.8, 0.3)
		else:
			icon.color = Color(0.2, 0.8, 1.0, 0.9)

	# 更新进度条位置
	var progress_bar := get_node_or_null("recharge_progress") as ColorRect
	if progress_bar:
		var target_idx: int = mini(charges, max_c - 1) if charges > 0 else 0
		progress_bar.position.x = 120.0 + target_idx * (CHARGE_ICON_SIZE + CHARGE_GAP)
