# workshop.gd — a Oficina: desmonta tralha em sucata, gasta sucata em melhoria,
# e responde quanto cada melhoria comprada está valendo.
#
# Os bônus são lidos daqui por quem precisa (pesca, viagem, venda, assistente),
# do mesmo jeito que Effects centraliza os bônus de evento — se cada sistema
# fosse somar por conta própria, um deles ia esquecer.

class_name Workshop
extends RefCounted


static func owns(state: Dictionary, upgrade_id: String) -> bool:
	return state["upgrades"].has(upgrade_id)


# Multiplicadores se acumulam por produto; o resto (rare_bonus_pct) por soma.
static func bonus(state: Dictionary, key: String, base: float) -> float:
	var value := base
	var additive := key.ends_with("_pct")
	for upgrade_id in state["upgrades"]:
		var upgrade := UpgradesData.get_upgrade(upgrade_id)
		if upgrade.is_empty() or not upgrade["effect"].has(key):
			continue
		var amount := float(upgrade["effect"][key])
		if additive:
			value += amount
		else:
			value *= amount
	return value


static func reel_decay_mult(state: Dictionary) -> float:
	return bonus(state, "reel_decay_mult", 1.0)


static func travel_mult(state: Dictionary) -> float:
	return bonus(state, "travel_mult", 1.0)


static func value_mult(state: Dictionary) -> float:
	return bonus(state, "value_mult", 1.0)


static func auto_interval_mult(state: Dictionary) -> float:
	return bonus(state, "auto_interval_mult", 1.0)


static func rare_bonus_pct(state: Dictionary) -> float:
	return bonus(state, "rare_bonus_pct", 0.0)


# Quanta sucata sairia se desmontasse tudo que está no bolso agora.
static func scrap_in_pocket(state: Dictionary) -> int:
	var total := 0
	for entry in state["inventory"]:
		var fish := FishData.get_fish(entry["fishId"])
		if FishData.is_trash(fish):
			total += FishData.scrap_of(fish) * int(entry["qty"])
	return total


# Desmonta toda a tralha do bolso. O peixe de verdade fica onde está — quem
# compra peixe é a loja.
static func dismantle_all(state: Dictionary) -> int:
	var gained := 0
	for entry in state["inventory"].duplicate(true):
		var fish := FishData.get_fish(entry["fishId"])
		if not FishData.is_trash(fish):
			continue
		gained += FishData.scrap_of(fish) * int(entry["qty"])
		StateFormat.remove_inventory(state, entry["fishId"], int(entry["qty"]))
	if gained > 0:
		Economy.add_currency(state, "sucata", gained)
		state["stats"]["totalScrapped"] = int(state["stats"].get("totalScrapped", 0)) + gained
	return gained


static func buy_upgrade(state: Dictionary, upgrade_id: String) -> Dictionary:
	var upgrade := UpgradesData.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return {"ok": false, "reason": "missing"}
	if owns(state, upgrade_id):
		return {"ok": false, "reason": "owned"}
	if int(state["player"]["rank"]) < int(upgrade["rank_req"]):
		return {"ok": false, "reason": "rank"}
	if not Economy.spend(state, upgrade["cost"]):
		return {"ok": false, "reason": "cost"}
	state["upgrades"].append(upgrade_id)
	return {"ok": true, "upgrade": upgrade}
