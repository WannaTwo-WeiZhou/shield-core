# 全局战斗事件总线，注册为 Autoload 单例 "EventBus"。
# 所有能力通过订阅这里的信号响应战斗事件，而不直接耦合彼此。
extends Node

# ---------- 战斗事件 ----------
## 格挡：context 包含 player、body、以及联动标志（如 has_burn）
signal on_block(context: Dictionary)
## 命中：context 包含 attacker、target、damage
signal on_hit(context: Dictionary)
## 击杀：context 包含 attacker、target
signal on_kill(context: Dictionary)
## 受伤：context 包含 player、damage
signal on_take_damage(context: Dictionary)
## 护盾破裂
signal on_shield_break(context: Dictionary)
## 暴击
signal on_crit(context: Dictionary)

# ---------- 能力系统事件 ----------
## 获得新能力
signal on_ability_acquired(ability_id: String, level: int)
## 联动激活
signal on_synergy_activated(synergy_id: String)
## 反击螺旋触发
signal on_counter_spiral_trigger(context: Dictionary)


# --- 便捷封装：发射格挡事件并返回上下文 ---
func emit_block(player: Node, blocked_body: Node, extra: Dictionary = {}) -> Dictionary:
	var ctx: Dictionary = {"player": player, "body": blocked_body}
	ctx.merge(extra)
	on_block.emit(ctx)
	return ctx


# --- 便捷封装：发射受伤事件并返回上下文 ---
func emit_take_damage(player: Node, damage: int, extra: Dictionary = {}) -> Dictionary:
	var ctx: Dictionary = {"player": player, "damage": damage}
	ctx.merge(extra)
	on_take_damage.emit(ctx)
	return ctx


# --- 便捷封装：发射反击螺旋触发事件并返回上下文 ---
func emit_counter_spiral_trigger(player: Node, shield: Node, extra: Dictionary = {}) -> Dictionary:
	var ctx: Dictionary = {
		"player": player,
		"shield": shield,
		"ability_id": "counter_spiral"
	}
	ctx.merge(extra)
	on_counter_spiral_trigger.emit(ctx)
	return ctx
