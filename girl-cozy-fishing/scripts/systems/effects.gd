# effects.gd — ponto único de leitura dos efeitos do evento ativo.
#
# No widget original cada sistema lia `state.activeEvent` por conta própria e um
# deles calculava o multiplicador de valor só pra jogar fora, deixando o evento
# "brisa da sorte" sem efeito nenhum. Centralizar aqui evita essa divergência.

class_name Effects
extends RefCounted


static func active_effect(state: Dictionary, now_ms: float = -1.0) -> Dictionary:
	var now := now_ms if now_ms >= 0.0 else StateFormat.now_ms()
	var evt: Variant = state.get("activeEvent")
	if typeof(evt) != TYPE_DICTIONARY or (evt as Dictionary).is_empty():
		return {}
	if float((evt as Dictionary).get("expiresAt", 0.0)) <= now:
		return {}
	var effect: Variant = (evt as Dictionary).get("effect")
	return effect if typeof(effect) == TYPE_DICTIONARY else {}


static func _num(value: Variant, fallback: float) -> float:
	var t := typeof(value)
	if t != TYPE_INT and t != TYPE_FLOAT:
		return fallback
	var n := float(value)
	return n if is_finite(n) else fallback


static func rare_bonus(state: Dictionary, bait_bonus_pct: float = 0.0) -> float:
	return bait_bonus_pct + _num(active_effect(state).get("rare_bonus_pct"), 0.0)


static func value_multiplier(state: Dictionary) -> float:
	return _num(active_effect(state).get("value_multiplier"), 1.0)


static func xp_multiplier(state: Dictionary) -> float:
	return _num(active_effect(state).get("xp_multiplier"), 1.0)


static func bite_wait_multiplier(state: Dictionary) -> float:
	var m := _num(active_effect(state).get("bite_wait_multiplier"), 1.0)
	return m if m > 0.0 else 1.0


# Bônus de raridade que vale agora: isca equipada + evento ativo + melhorias.
static func live_rare_bonus(state: Dictionary) -> float:
	var bait := EquipmentData.bait_by_tier(int(state["equipment"]["baitTier"]))
	var bait_bonus := float(bait.get("rare_bonus_pct", 0)) if not bait.is_empty() else 0.0
	return rare_bonus(state, bait_bonus) + Workshop.rare_bonus_pct(state)
