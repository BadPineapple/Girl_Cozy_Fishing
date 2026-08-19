# economy.gd — moeda, XP e subida de rank.

class_name Economy
extends RefCounted


static func can_afford(state: Dictionary, cost: Dictionary) -> bool:
	if cost.is_empty():
		return true
	for currency in cost:
		var amount := float(cost[currency])
		if not is_finite(amount) or amount < 0.0:
			return false
		if float(state["currencies"].get(currency, 0)) < amount:
			return false
	return true


static func spend(state: Dictionary, cost: Dictionary) -> bool:
	if not can_afford(state, cost):
		return false
	for currency in cost:
		state["currencies"][currency] = int(state["currencies"].get(currency, 0)) - int(cost[currency])
	return true


static func add_currency(state: Dictionary, currency: String, amount: int) -> void:
	if amount == 0:
		return
	state["currencies"][currency] = int(state["currencies"].get(currency, 0)) + amount


# Adiciona XP e sobe de rank em cascata (um catch grande pode pular mais de um).
# Retorna quantos ranks foram ganhos, pra UI poder comemorar.
static func add_xp(state: Dictionary, amount: int) -> int:
	if amount <= 0:
		return 0
	var player: Dictionary = state["player"]
	player["xp"] = int(player["xp"]) + amount

	var ranks_gained := 0
	# O `while` só é seguro porque xpToNext é garantidamente > 0 (ver
	# sanitize_state + xp_for_rank); a checagem aqui é o cinto de segurança:
	# com um save adulterado zerando esse campo, o laço rodava pra sempre.
	while int(player["xp"]) >= int(player["xpToNext"]):
		if int(player["xpToNext"]) <= 0:
			player["xpToNext"] = StateFormat.xp_for_rank(int(player["rank"]))
			break
		player["xp"] = int(player["xp"]) - int(player["xpToNext"])
		player["rank"] = int(player["rank"]) + 1
		player["xpToNext"] = StateFormat.xp_for_rank(int(player["rank"]))
		ranks_gained += 1
	return ranks_gained
