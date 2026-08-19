# map_system.gd — viajar entre locais e abrir os estabelecimentos de cada um.
# A loja abre junto com o local; o ateliê precisa ser desbloqueado à parte.

class_name MapSystem
extends RefCounted


static func is_location_unlocked(state: Dictionary, location_id: String) -> bool:
	return state["unlockedLocations"].has(location_id)


static func unlock_location(state: Dictionary, location_id: String) -> Dictionary:
	if not LocationsData.has_location(location_id):
		return {"ok": false, "reason": "missing"}
	if is_location_unlocked(state, location_id):
		return {"ok": false, "reason": "owned"}
	var loc := LocationsData.get_location(location_id)
	if int(state["player"]["rank"]) < int(loc["unlock_rank"]):
		return {"ok": false, "reason": "rank"}
	if not Economy.spend(state, loc["unlock_cost"]):
		return {"ok": false, "reason": "cost"}
	state["unlockedLocations"].append(location_id)
	return {"ok": true, "location": loc}


static func travel_to(state: Dictionary, location_id: String) -> Dictionary:
	if not is_location_unlocked(state, location_id):
		return {"ok": false, "reason": "locked"}
	state["locationId"] = location_id
	return {"ok": true}


static func is_venue_unlocked(state: Dictionary, venue_id: String) -> bool:
	var venue := LocationsData.venue_by_id(venue_id)
	if venue.is_empty():
		return false
	if bool(venue.get("always_open", false)):
		return is_location_unlocked(state, venue["location_id"])
	return state["unlockedVenues"].has(venue_id)


static func unlock_venue(state: Dictionary, venue_id: String) -> Dictionary:
	var venue := LocationsData.venue_by_id(venue_id)
	if venue.is_empty():
		return {"ok": false, "reason": "missing"}
	if is_venue_unlocked(state, venue_id):
		return {"ok": false, "reason": "owned"}
	if not is_location_unlocked(state, venue["location_id"]):
		return {"ok": false, "reason": "locked"}
	if int(state["player"]["rank"]) < int(venue.get("unlock_rank", 1)):
		return {"ok": false, "reason": "rank"}
	if not Economy.spend(state, venue.get("unlock_cost", {})):
		return {"ok": false, "reason": "cost"}
	state["unlockedVenues"].append(venue_id)
	return {"ok": true, "venue": venue}


static func current_location(state: Dictionary) -> Dictionary:
	return LocationsData.get_location(state["locationId"])
