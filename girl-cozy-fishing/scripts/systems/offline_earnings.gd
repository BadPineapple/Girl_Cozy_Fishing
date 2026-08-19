# offline_earnings.gd — quando o jogo abre de novo, calcula quanto o assistente
# de pesca teria rendido enquanto estava fechado (se estava ligado).
# Os peixes vão pro bolso normalmente; é a moeda da venda que espera você
# passar na loja — assim sempre tem uma surpresa te esperando.

class_name OfflineEarnings
extends RefCounted

const MAX_OFFLINE_MS := 8 * 60 * 60 * 1000.0  # teto de 8h de ausência
const INTERVAL_MULT := 1.8                     # menos eficiente que estar de olho na tela


# Devolve {} se não havia nada a receber.
static func compute(state: Dictionary, rare_bonus: float = 0.0) -> Dictionary:
	if not bool(state["autoFish"]["unlocked"]) or not bool(state["autoFish"]["enabled"]):
		return {}

	var now := GameState.now_ms()
	var elapsed := clampf(now - float(state["lastSeen"]), 0.0, MAX_OFFLINE_MS)
	var interval := AutoFish.INTERVAL_MS * INTERVAL_MULT
	var attempts := int(floor(elapsed / interval))
	if attempts <= 0:
		return {}

	var summary := {
		"attempts": attempts,
		"catches": 0,
		"xp": 0,
		"escamas": 0,
		"rare_catches": 0,
		"elapsed_ms": elapsed,
	}
	var escamas_before := int(state["currencies"]["escamas"])

	for _i in attempts:
		var result := AutoFish.simulate_catch(state, rare_bonus)
		if result.is_empty():
			continue
		summary["catches"] = int(summary["catches"]) + 1
		summary["xp"] = int(summary["xp"]) + int(result["xp_gain"])
		if FishData.is_rare(result["fish"]):
			summary["rare_catches"] = int(summary["rare_catches"]) + 1

	summary["escamas"] = int(state["currencies"]["escamas"]) - escamas_before
	return summary
