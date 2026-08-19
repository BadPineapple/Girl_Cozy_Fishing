# game_state.gd — autoload "GameState": a "planilha" com tudo que precisa ser
# salvo, num Dictionary simples pra ficar fácil de inspecionar e virar JSON.
#
# O arquivo de save mora em user:// e é editável pelo jogador (e pode corromper
# num desligamento), então nada que vem de lá entra no jogo sem passar por
# `sanitize_state`: um valor NaN, um id inexistente ou um xp_to_next zerado
# viram crash ou loop infinito lá na frente.

extends Node

const SAVE_VERSION := 1
const MAX_INVENTORY_QTY := 1_000_000_000

var state: Dictionary = {}


func _ready() -> void:
	randomize()
	state = merge_with_defaults(SaveSystem.load_state())


static func now_ms() -> float:
	return Time.get_unix_time_from_system() * 1000.0


static func xp_for_rank(rank: int) -> int:
	var r: int = rank if rank > 0 else 1
	return 50 + r * 25


static func default_state() -> Dictionary:
	var now := now_ms()
	return {
		"version": SAVE_VERSION,
		"createdAt": now,
		"lastSeen": now,

		"player": {
			"rank": 1,
			"xp": 0,
			"xpToNext": xp_for_rank(1),
		},

		"currencies": {
			"conchas": 20,  # moeda principal, ganha vendendo peixe
			"escamas": 0,   # moeda "rara", vem de peixes/achados especiais
		},

		"equipment": {
			"rodTier": 1,
			"baitTier": 1,
		},

		"autoFish": {
			"unlocked": false,
			"enabled": false,
		},

		"locationId": LocationsData.DEFAULT_LOCATION,
		"unlockedLocations": [LocationsData.DEFAULT_LOCATION],
		"unlockedVenues": [],  # lojas/ateliês abertos (ver venues em locations_data.gd)

		"inventory": [],  # [{fishId, qty}]

		"cosmetics": {
			"owned": CosmeticsData.STARTER_COSMETICS.duplicate(),
			"equipped": CosmeticsData.DEFAULT_EQUIPPED.duplicate(),
		},

		"activeEvent": {},  # {} = nenhum evento ativo
		"lastEventRollAt": now,

		"stats": {
			"totalCatches": 0,
			"totalEscaped": 0,
			"totalSoldConchas": 0,
			"rareCatches": 0,
		},
	}


# Aplica defaults por cima de um save antigo/incompleto, sem perder progresso.
static func merge_with_defaults(saved: Variant) -> Dictionary:
	if typeof(saved) != TYPE_DICTIONARY or (saved as Dictionary).is_empty():
		return default_state()
	return sanitize_state(_deep_merge(default_state(), saved))


static func _deep_merge(base: Variant, override: Variant) -> Variant:
	if typeof(base) == TYPE_ARRAY:
		return override if typeof(override) == TYPE_ARRAY else base
	if typeof(base) == TYPE_DICTIONARY:
		var result: Dictionary = (base as Dictionary).duplicate(true)
		var over: Dictionary = override if typeof(override) == TYPE_DICTIONARY else {}
		# Só percorre as chaves conhecidas: chave estranha vinda do arquivo é ignorada.
		for key in result:
			if over.has(key):
				result[key] = _deep_merge(result[key], over[key])
		return result
	return override if override != null else base


static func _as_int(value: Variant, fallback: int, minimum: int = 0, maximum: int = MAX_INVENTORY_QTY) -> int:
	var t := typeof(value)
	if t != TYPE_INT and t != TYPE_FLOAT and t != TYPE_STRING:
		return fallback
	var n := float(value)
	if not is_finite(n):
		return fallback
	return clampi(int(floor(n)), minimum, maximum)


static func _as_timestamp(value: Variant, fallback: float) -> float:
	var t := typeof(value)
	if t != TYPE_INT and t != TYPE_FLOAT:
		return fallback
	var n := float(value)
	if not is_finite(n) or n <= 0.0:
		return fallback
	# Save "do futuro" (relógio mexido) não pode virar crédito offline.
	return minf(n, fallback + 60000.0)


static func sanitize_state(raw: Variant) -> Dictionary:
	var s: Dictionary = raw if typeof(raw) == TYPE_DICTIONARY else default_state()
	var def := default_state()
	var now := now_ms()

	s["version"] = SAVE_VERSION
	s["createdAt"] = _as_timestamp(s.get("createdAt"), now)
	s["lastSeen"] = _as_timestamp(s.get("lastSeen"), now)
	s["lastEventRollAt"] = _as_timestamp(s.get("lastEventRollAt"), now)

	var p: Dictionary = s.get("player", {}) if typeof(s.get("player")) == TYPE_DICTIONARY else {}
	var rank := _as_int(p.get("rank"), 1, 1)
	var saved_next := _as_int(p.get("xpToNext"), 0, 0)
	s["player"] = {
		"rank": rank,
		"xp": _as_int(p.get("xp"), 0, 0),
		# xpToNext <= 0 travava o `while` de subida de rank em loop infinito.
		"xpToNext": saved_next if saved_next > 0 else xp_for_rank(rank),
	}

	var c: Dictionary = s.get("currencies", {}) if typeof(s.get("currencies")) == TYPE_DICTIONARY else {}
	s["currencies"] = {
		"conchas": _as_int(c.get("conchas"), int(def["currencies"]["conchas"]), 0),
		"escamas": _as_int(c.get("escamas"), 0, 0),
	}

	var eq: Dictionary = s.get("equipment", {}) if typeof(s.get("equipment")) == TYPE_DICTIONARY else {}
	s["equipment"] = {
		"rodTier": _as_int(eq.get("rodTier"), 1, 1, EquipmentData.max_rod_tier()),
		"baitTier": _as_int(eq.get("baitTier"), 1, 1, EquipmentData.max_bait_tier()),
	}

	var af: Dictionary = s.get("autoFish", {}) if typeof(s.get("autoFish")) == TYPE_DICTIONARY else {}
	var unlocked := bool(af.get("unlocked", false))
	s["autoFish"] = {"unlocked": unlocked, "enabled": unlocked and bool(af.get("enabled", false))}

	var unlocked_locs: Array = []
	if typeof(s.get("unlockedLocations")) == TYPE_ARRAY:
		for id in s["unlockedLocations"]:
			if typeof(id) == TYPE_STRING and LocationsData.has_location(id) and not unlocked_locs.has(id):
				unlocked_locs.append(id)
	if not unlocked_locs.has(LocationsData.DEFAULT_LOCATION):
		unlocked_locs.push_front(LocationsData.DEFAULT_LOCATION)
	s["unlockedLocations"] = unlocked_locs

	var loc_id: Variant = s.get("locationId")
	s["locationId"] = loc_id if typeof(loc_id) == TYPE_STRING and unlocked_locs.has(loc_id) else LocationsData.DEFAULT_LOCATION

	var known_venues := LocationsData.all_venue_ids()
	var venues: Array = []
	if typeof(s.get("unlockedVenues")) == TYPE_ARRAY:
		for id in s["unlockedVenues"]:
			if typeof(id) == TYPE_STRING and known_venues.has(id) and not venues.has(id):
				venues.append(id)
	s["unlockedVenues"] = venues

	# Inventário: junta duplicatas, descarta id desconhecido e quantidade inválida.
	var inv_order: Array = []
	var inv_qty: Dictionary = {}
	if typeof(s.get("inventory")) == TYPE_ARRAY:
		for entry in s["inventory"]:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var fish_id: Variant = entry.get("fishId")
			if typeof(fish_id) != TYPE_STRING or not FishData.has_fish(fish_id):
				continue
			var qty := _as_int(entry.get("qty"), 0, 0, MAX_INVENTORY_QTY)
			if qty <= 0:
				continue
			if not inv_qty.has(fish_id):
				inv_order.append(fish_id)
				inv_qty[fish_id] = 0
			inv_qty[fish_id] = mini(MAX_INVENTORY_QTY, int(inv_qty[fish_id]) + qty)
	var inventory: Array = []
	for fish_id in inv_order:
		inventory.append({"fishId": fish_id, "qty": inv_qty[fish_id]})
	s["inventory"] = inventory

	var cos: Dictionary = s.get("cosmetics", {}) if typeof(s.get("cosmetics")) == TYPE_DICTIONARY else {}
	var owned: Array = CosmeticsData.STARTER_COSMETICS.duplicate()
	if typeof(cos.get("owned")) == TYPE_ARRAY:
		for id in cos["owned"]:
			if typeof(id) == TYPE_STRING and CosmeticsData.has_cosmetic(id) and not owned.has(id):
				owned.append(id)
	var equipped: Dictionary = CosmeticsData.DEFAULT_EQUIPPED.duplicate()
	var saved_equipped: Dictionary = cos.get("equipped", {}) if typeof(cos.get("equipped")) == TYPE_DICTIONARY else {}
	for slot in equipped.keys():
		var id: Variant = saved_equipped.get(slot)
		if typeof(id) == TYPE_STRING and CosmeticsData.has_cosmetic(id) \
				and CosmeticsData.get_cosmetic(id)["slot"] == slot and owned.has(id):
			equipped[slot] = id
	s["cosmetics"] = {"owned": owned, "equipped": equipped}

	var evt: Variant = s.get("activeEvent")
	var valid_event := typeof(evt) == TYPE_DICTIONARY \
			and typeof((evt as Dictionary).get("id")) == TYPE_STRING \
			and typeof((evt as Dictionary).get("effect")) == TYPE_DICTIONARY \
			and _as_timestamp((evt as Dictionary).get("expiresAt"), 0.0) > now
	if valid_event:
		var e: Dictionary = evt
		s["activeEvent"] = {
			"id": e["id"],
			"title": e.get("title", "") if typeof(e.get("title")) == TYPE_STRING else "",
			"icon": e.get("icon", "#ffffff") if typeof(e.get("icon")) == TYPE_STRING else "#ffffff",
			"effect": e["effect"],
			"expiresAt": float(e["expiresAt"]),
		}
	else:
		s["activeEvent"] = {}

	var st: Dictionary = s.get("stats", {}) if typeof(s.get("stats")) == TYPE_DICTIONARY else {}
	s["stats"] = {
		"totalCatches": _as_int(st.get("totalCatches"), 0, 0),
		"totalEscaped": _as_int(st.get("totalEscaped"), 0, 0),
		"totalSoldConchas": _as_int(st.get("totalSoldConchas"), 0, 0),
		"rareCatches": _as_int(st.get("rareCatches"), 0, 0),
	}

	return s


# --- inventário ---
static func add_inventory(s: Dictionary, fish_id: String, qty: int = 1) -> void:
	if not FishData.has_fish(fish_id) or qty <= 0:
		return
	for entry in s["inventory"]:
		if entry["fishId"] == fish_id:
			entry["qty"] = mini(MAX_INVENTORY_QTY, int(entry["qty"]) + qty)
			return
	s["inventory"].append({"fishId": fish_id, "qty": qty})


static func remove_inventory(s: Dictionary, fish_id: String, qty: int = 1) -> bool:
	var inventory: Array = s["inventory"]
	for i in inventory.size():
		if inventory[i]["fishId"] == fish_id:
			inventory[i]["qty"] = int(inventory[i]["qty"]) - qty
			if int(inventory[i]["qty"]) <= 0:
				inventory.remove_at(i)
			return true
	return false


static func total_fish(s: Dictionary) -> int:
	var total := 0
	for entry in s["inventory"]:
		total += int(entry["qty"])
	return total


# --- save ---
func save_now() -> void:
	state["lastSeen"] = now_ms()
	SaveSystem.save_state(state)
