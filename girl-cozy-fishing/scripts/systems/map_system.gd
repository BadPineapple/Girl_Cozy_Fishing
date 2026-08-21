# map_system.gd — viajar entre locais e abrir os estabelecimentos de cada um.
#
# Viagem leva tempo: o barco sai daqui e chega lá depois de um tanto de
# segundos, proporcional à distância entre os dois pontos. Enquanto navega não
# dá pra pescar — é o custo de trocar de continente.
#
# A viagem fica guardada no save com o horário de chegada em vez de um contador
# regressivo: assim ela continua correndo com o jogo fechado, do mesmo jeito que
# o assistente de pesca, e não há como ganhar tempo fechando o jogo.

class_name MapSystem
extends RefCounted

const TRAVEL_BASE_MS := 12000.0      # sair do lugar já custa isso
const TRAVEL_PER_DISTANCE_MS := 9000.0  # e mais isso por unidade de distância


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


# --- viagem ---
static func travel_time_ms(state: Dictionary, from_id: String, to_id: String) -> float:
	var from_loc := LocationsData.get_location(from_id)
	var to_loc := LocationsData.get_location(to_id)
	var steps := absf(float(to_loc.get("distance", 0)) - float(from_loc.get("distance", 0)))
	var raw := TRAVEL_BASE_MS + steps * TRAVEL_PER_DISTANCE_MS
	return raw * Workshop.travel_mult(state)  # o Casco Polido encurta tudo


static func is_traveling(state: Dictionary, now_ms: float = -1.0) -> bool:
	var trip: Dictionary = state["travel"]
	if trip.is_empty():
		return false
	var now := now_ms if now_ms >= 0.0 else StateFormat.now_ms()
	return float(trip["arrivesAt"]) > now


static func travel_remaining_ms(state: Dictionary, now_ms: float = -1.0) -> float:
	var trip: Dictionary = state["travel"]
	if trip.is_empty():
		return 0.0
	var now := now_ms if now_ms >= 0.0 else StateFormat.now_ms()
	return maxf(0.0, float(trip["arrivesAt"]) - now)


static func travel_progress(state: Dictionary, now_ms: float = -1.0) -> float:
	var trip: Dictionary = state["travel"]
	if trip.is_empty():
		return 1.0
	var now := now_ms if now_ms >= 0.0 else StateFormat.now_ms()
	var total := float(trip["arrivesAt"]) - float(trip["startedAt"])
	if total <= 0.0:
		return 1.0
	return clampf((now - float(trip["startedAt"])) / total, 0.0, 1.0)


static func travel_destination(state: Dictionary) -> Dictionary:
	var trip: Dictionary = state["travel"]
	if trip.is_empty():
		return {}
	return LocationsData.get_location(trip["toId"])


# Zarpar. O `locationId` só muda na chegada — até lá a cena mostra de onde você
# saiu, e `settle_travel` faz o desembarque.
static func begin_travel(state: Dictionary, to_id: String) -> Dictionary:
	if not is_location_unlocked(state, to_id):
		return {"ok": false, "reason": "locked"}
	if is_traveling(state):
		return {"ok": false, "reason": "traveling"}
	if state["locationId"] == to_id:
		return {"ok": false, "reason": "already"}

	var now := StateFormat.now_ms()
	var duration := travel_time_ms(state, state["locationId"], to_id)
	state["travel"] = {
		"toId": to_id,
		"fromId": state["locationId"],
		"startedAt": now,
		"arrivesAt": now + duration,
	}
	state["stats"]["totalTrips"] = int(state["stats"].get("totalTrips", 0)) + 1
	return {"ok": true, "duration_ms": duration, "location": LocationsData.get_location(to_id)}


# Se a viagem já venceu, desembarca. Devolve o local de chegada, ou {} se não
# havia nada a concluir. Chamado no loop e na abertura do jogo.
static func settle_travel(state: Dictionary, now_ms: float = -1.0) -> Dictionary:
	var trip: Dictionary = state["travel"]
	if trip.is_empty():
		return {}
	var now := now_ms if now_ms >= 0.0 else StateFormat.now_ms()
	if float(trip["arrivesAt"]) > now:
		return {}

	var arrived: String = trip["toId"]
	state["travel"] = {}
	if is_location_unlocked(state, arrived):
		state["locationId"] = arrived
	return LocationsData.get_location(state["locationId"])


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


# "1min 20s" / "45s" — o formato curto que cabe no botão.
static func format_duration(ms: float) -> String:
	var seconds := int(ceil(maxf(0.0, ms) / 1000.0))
	if seconds < 60:
		return "%ds" % seconds
	return "%dmin %02ds" % [seconds / 60, seconds % 60]
