# auto_fish.gd — o "assistente de pesca": enquanto ligado, tenta uma pescaria
# automática de tempos em tempos, sem o minigame manual. Rende menos XP que
# pescar na mão (pra manual continuar valendo a pena), mas os peixes valem o
# mesmo quando vendidos.

class_name AutoFish
extends RefCounted

const INTERVAL_MS := 45000.0   # uma tentativa a cada ~45s — cozy, não metralhadora
const XP_MULT := 0.55
const MAX_CATCHUP_ATTEMPTS := 800  # ~10h de recuperação; teto só pra não travar o frame


static func success_chance(state: Dictionary) -> float:
	var rod := EquipmentData.rod_by_tier(int(state["equipment"]["rodTier"]))
	var power := float(rod.get("power", 1)) if not rod.is_empty() else 1.0
	return minf(0.9, 0.5 + power * 0.06)


static func simulate_catch(state: Dictionary, rare_bonus: float = 0.0) -> Dictionary:
	if randf() >= success_chance(state):
		return {}

	var fish := FishData.roll_fish(state["locationId"], rare_bonus)
	if fish.is_empty():
		return {}

	StateFormat.add_inventory(state, fish["id"], 1)
	var xp_gain := maxi(1, roundi(float(fish["xp"]) * XP_MULT))
	Economy.add_xp(state, xp_gain)

	var escamas := FishData.escamas_of(fish)
	if escamas > 0:
		Economy.add_currency(state, "escamas", maxi(1, roundi(float(escamas) * 0.5)))

	state["stats"]["totalCatches"] = int(state["stats"]["totalCatches"]) + 1
	if FishData.is_rare(fish):
		state["stats"]["rareCatches"] = int(state["stats"]["rareCatches"]) + 1

	return {"fish": fish, "xp_gain": xp_gain}


# `accumulator` guarda quanto tempo passou desde a última tentativa; fica fora
# do estado persistido de propósito.
#
# delta_ms deve vir do relógio de parede, não do tempo de frame: com a janela
# minimizada o processamento pode parar, e no widget original o assistente
# parava junto sem que o cálculo offline cobrisse o buraco.
# Devolve a lista de fisgadas deste tick (vazia se nenhuma).
static func tick(state: Dictionary, delta_ms: float, rare_bonus: float, accumulator: Array) -> Array:
	if not bool(state["autoFish"]["unlocked"]) or not bool(state["autoFish"]["enabled"]):
		accumulator[0] = 0.0
		return []
	if not is_finite(delta_ms) or delta_ms <= 0.0:
		return []

	accumulator[0] = float(accumulator[0]) + delta_ms

	var results: Array = []
	var attempts := 0
	while float(accumulator[0]) >= INTERVAL_MS and attempts < MAX_CATCHUP_ATTEMPTS:
		accumulator[0] = float(accumulator[0]) - INTERVAL_MS
		attempts += 1
		var result := simulate_catch(state, rare_bonus)
		if not result.is_empty():
			results.append(result)

	if attempts >= MAX_CATCHUP_ATTEMPTS:
		accumulator[0] = 0.0
	return results
