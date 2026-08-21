# shop_system.gd — vender peixe e comprar vara/isca/assistente.

class_name ShopSystem
extends RefCounted


# O multiplicador de valor do evento ativo ("brisa da sorte") é aplicado aqui,
# na venda. No widget original ele era calculado na pescaria e descartado, então
# o evento não fazia absolutamente nada.
static func fish_sell_value(state: Dictionary, fish: Dictionary) -> int:
	var mult := Effects.value_multiplier(state) * Workshop.value_mult(state)
	return maxi(1, roundi(float(fish["value"]) * mult))


static func sell_fish(state: Dictionary, fish_id: String, qty: int) -> int:
	var fish := FishData.get_fish(fish_id)
	if fish.is_empty():
		return 0

	var owned := 0
	for entry in state["inventory"]:
		if entry["fishId"] == fish_id:
			owned = int(entry["qty"])
			break

	var sell_qty := mini(qty, owned)
	if sell_qty <= 0:
		return 0

	StateFormat.remove_inventory(state, fish_id, sell_qty)
	var gain := fish_sell_value(state, fish) * sell_qty
	Economy.add_currency(state, "conchas", gain)
	state["stats"]["totalSoldConchas"] = int(state["stats"]["totalSoldConchas"]) + gain
	return gain


static func sell_all(state: Dictionary) -> int:
	var total := 0
	for entry in state["inventory"].duplicate(true):
		total += sell_fish(state, entry["fishId"], int(entry["qty"]))
	return total


static func next_rod(state: Dictionary) -> Dictionary:
	return EquipmentData.rod_by_tier(int(state["equipment"]["rodTier"]) + 1)


static func next_bait(state: Dictionary) -> Dictionary:
	return EquipmentData.bait_by_tier(int(state["equipment"]["baitTier"]) + 1)


static func buy_next_rod(state: Dictionary) -> Dictionary:
	var rod := next_rod(state)
	if rod.is_empty():
		return {"ok": false, "reason": "max"}
	if int(state["player"]["rank"]) < int(rod["rank_req"]):
		return {"ok": false, "reason": "rank"}
	if not Economy.spend(state, rod["cost"]):
		return {"ok": false, "reason": "cost"}
	state["equipment"]["rodTier"] = int(rod["tier"])
	return {"ok": true, "rod": rod}


static func buy_next_bait(state: Dictionary) -> Dictionary:
	var bait := next_bait(state)
	if bait.is_empty():
		return {"ok": false, "reason": "max"}
	if int(state["player"]["rank"]) < int(bait["rank_req"]):
		return {"ok": false, "reason": "rank"}
	if not Economy.spend(state, bait["cost"]):
		return {"ok": false, "reason": "cost"}
	state["equipment"]["baitTier"] = int(bait["tier"])
	return {"ok": true, "bait": bait}


static func buy_auto_fish_unlock(state: Dictionary) -> Dictionary:
	if bool(state["autoFish"]["unlocked"]):
		return {"ok": false, "reason": "owned"}
	if int(state["player"]["rank"]) < int(EquipmentData.AUTO_FISH_UNLOCK["rank_req"]):
		return {"ok": false, "reason": "rank"}
	if not Economy.spend(state, EquipmentData.AUTO_FISH_UNLOCK["cost"]):
		return {"ok": false, "reason": "cost"}
	state["autoFish"]["unlocked"] = true
	return {"ok": true}
