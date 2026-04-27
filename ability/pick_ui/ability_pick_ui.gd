# 升级三选一界面：玩家升级时弹出，展示 3 张能力候选卡片。
# 显示期间游戏暂停，选择后恢复。
extends CanvasLayer

const AbilityCard = preload("res://ability/pick_ui/ability_card.tscn")
const AbilityDefinition = preload("res://ability/ability_definition.gd")
const AbilityInstance = preload("res://ability/ability_instance.gd")

@onready var cards_container: HBoxContainer = $background/VBoxContainer/cards_container
@onready var title_label: Label = $background/VBoxContainer/title_label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	AbilityManager.ability_selection_needed.connect(_on_ability_selection_needed)


func _on_ability_selection_needed(candidates: Array) -> void:
	_show_candidates(candidates)


func _show_candidates(candidates: Array) -> void:
	# 清除旧卡片
	for child in cards_container.get_children():
		child.queue_free()

	# 创建候选卡片
	for def: AbilityDefinition in candidates:
		var card: PanelContainer = AbilityCard.instantiate()
		cards_container.add_child(card)
		var inst: AbilityInstance = AbilityManager.get_instance(def.id)
		var current_lv := inst.current_level if inst != null else 0
		card.setup(def, current_lv)
		card.card_selected.connect(_on_card_selected)

	show()
	get_tree().paused = true


func _on_card_selected(ability_id: String) -> void:
	get_tree().paused = false
	hide()
	AbilityManager.select_ability(ability_id)
