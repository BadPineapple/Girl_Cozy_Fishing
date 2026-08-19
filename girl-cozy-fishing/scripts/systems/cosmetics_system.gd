# cosmetics_system.gd — comprar e equipar cosméticos (o ateliê).

class_name CosmeticsSystem
extends RefCounted


static func owns(state: Dictionary, cosmetic_id: String) -> bool:
	return state["cosmetics"]["owned"].has(cosmetic_id)


static func is_equipped(state: Dictionary, cosmetic_id: String) -> bool:
	var item := CosmeticsData.get_cosmetic(cosmetic_id)
	if item.is_empty():
		return false
	return state["cosmetics"]["equipped"].get(item["slot"], "") == cosmetic_id


static func buy_cosmetic(state: Dictionary, cosmetic_id: String) -> Dictionary:
	var item := CosmeticsData.get_cosmetic(cosmetic_id)
	if item.is_empty():
		return {"ok": false, "reason": "missing"}
	if owns(state, cosmetic_id):
		return {"ok": false, "reason": "owned"}
	if int(state["player"]["rank"]) < int(item["rank_req"]):
		return {"ok": false, "reason": "rank"}
	if not Economy.spend(state, item["cost"]):
		return {"ok": false, "reason": "cost"}
	state["cosmetics"]["owned"].append(cosmetic_id)
	return {"ok": true, "item": item}


static func equip_cosmetic(state: Dictionary, cosmetic_id: String) -> Dictionary:
	var item := CosmeticsData.get_cosmetic(cosmetic_id)
	if item.is_empty():
		return {"ok": false, "reason": "missing"}
	if not owns(state, cosmetic_id):
		return {"ok": false, "reason": "not-owned"}
	state["cosmetics"]["equipped"][item["slot"]] = cosmetic_id
	return {"ok": true, "item": item}
