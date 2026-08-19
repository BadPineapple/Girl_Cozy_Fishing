# events_engine.gd — de tempos em tempos sorteia um eventinho passageiro
# (ver data/events_data.gd) que dá um bônus temporário. A frequência é só
# tempero: não deixa o jogo mais difícil, só mais gostoso de acompanhar.

class_name EventsEngine
extends RefCounted

const CHECK_COOLDOWN_MS := 5 * 60 * 1000.0  # não tenta rolar de novo antes disso
const ROLL_CHANCE := 0.35                    # chance de "dar evento" a cada checagem


# Devolve o evento que começou agora, ou {} se nada aconteceu.
static func tick(state: Dictionary, now_ms: float) -> Dictionary:
	var active: Variant = state.get("activeEvent")
	if typeof(active) == TYPE_DICTIONARY and not (active as Dictionary).is_empty():
		if float((active as Dictionary).get("expiresAt", 0.0)) <= now_ms:
			state["activeEvent"] = {}
		else:
			return {}

	if now_ms - float(state["lastEventRollAt"]) < CHECK_COOLDOWN_MS:
		return {}

	state["lastEventRollAt"] = now_ms
	if randf() > ROLL_CHANCE:
		return {}

	var def := EventsData.roll_event()
	state["activeEvent"] = {
		"id": def["id"],
		"title": def["title"],
		"icon": def["icon"],
		"effect": def["effect"],
		"expiresAt": now_ms + float(def["duration_ms"]),
	}
	return state["activeEvent"]
