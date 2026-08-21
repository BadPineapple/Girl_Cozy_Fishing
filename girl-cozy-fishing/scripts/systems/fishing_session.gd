# fishing_session.gd — a máquina de estados do minigame de pesca.
#
#   idle ──lançar──> casting ──> waiting ──fisgou──> reeling ──pegou──> idle
#     ^                 │           │                   │
#     └── recolhendo <──┴─cancelar──┘                   └──escapou──┘
#
# `recolhendo` é uma fase curta e sem decisão: a linha volta pra vara. Serve
# tanto pro cancelamento quanto pra perda do peixe — nos dois casos a linha
# sendo recolhida é o que fecha a ação, em vez do anzol sumir do nada.
#
# Roda em memória: só o RESULTADO de uma pescaria (peixe, xp, moeda) é que mexe
# no estado persistido.

class_name FishingSession
extends RefCounted

signal phase_changed(snapshot: Dictionary)
signal fish_caught(caught: Dictionary)
signal fish_escaped(fish: Dictionary)

const CAST_MS := 700.0
const BASE_BITE_MIN_MS := 1200.0
const BASE_BITE_MAX_MS := 3200.0
const REEL_START_PCT := 38.0
const REEL_CATCH_PCT := 100.0
const RETRIEVE_MS := 420.0

signal line_retrieved  # a linha terminou de voltar (pra UI/som)

var phase: String = "idle"

var _state: Dictionary
var _timer := 0.0
var _fish: Dictionary = {}
var _reel_pct := 0.0
var _reel_decay_per_sec := 0.0
var _pull_power := 0.0


func _init(state: Dictionary) -> void:
	_state = state


func snapshot() -> Dictionary:
	return {
		"phase": phase,
		"fish": _fish,
		"reel_pct": roundi(_reel_pct),
		"fish_name": _fish.get("name", ""),
		"fish_rarity": _fish.get("rarity", ""),
	}


func start_cast() -> void:
	if phase != "idle":
		return
	phase = "casting"
	_timer = CAST_MS
	phase_changed.emit(snapshot())


# Desistir antes da fisgada. Vale enquanto a isca está indo ou esperando — em
# `reeling` já tem peixe na linha e sair fora é o cabo de guerra, não um botão.
func can_cancel() -> bool:
	return phase == "casting" or phase == "waiting"


func cancel() -> void:
	if not can_cancel():
		return
	_fish = {}
	_begin_retrieve()


# Quanto da recolhida já passou: 0 = acabou de começar, 1 = linha na vara.
func retrieve_progress() -> float:
	if phase != "recolhendo":
		return 0.0
	return clampf(1.0 - _timer / RETRIEVE_MS, 0.0, 1.0)


func _begin_retrieve() -> void:
	phase = "recolhendo"
	_timer = RETRIEVE_MS
	_reel_pct = 0.0
	phase_changed.emit(snapshot())


func pull() -> void:
	if phase != "reeling":
		return
	_reel_pct = minf(REEL_CATCH_PCT, _reel_pct + _pull_power)
	# _resolve_catch() já emite o sinal final; sem o return a UI recebia dois
	# eventos seguidos e o medidor piscava depois de fisgar.
	if _reel_pct >= REEL_CATCH_PCT:
		_resolve_catch()
		return
	phase_changed.emit(snapshot())


func tick(delta_ms: float) -> void:
	if not is_finite(delta_ms) or delta_ms <= 0.0:
		return

	match phase:
		"casting":
			_timer -= delta_ms
			if _timer <= 0.0:
				_begin_waiting()
		"waiting":
			_timer -= delta_ms
			if _timer <= 0.0:
				_begin_reeling()
		"recolhendo":
			_timer -= delta_ms
			phase_changed.emit(snapshot())
			if _timer <= 0.0:
				phase = "idle"
				line_retrieved.emit()
				phase_changed.emit(snapshot())
		"reeling":
			_reel_pct -= (_reel_decay_per_sec * delta_ms) / 1000.0
			if _reel_pct <= 0.0:
				_resolve_escape()
				return
			phase_changed.emit(snapshot())


func _begin_waiting() -> void:
	phase = "waiting"
	var mult := Effects.bite_wait_multiplier(_state)
	_timer = randf_range(BASE_BITE_MIN_MS * mult, BASE_BITE_MAX_MS * mult)
	phase_changed.emit(snapshot())


func _begin_reeling() -> void:
	_fish = FishData.roll_fish(_state["locationId"], Effects.live_rare_bonus(_state))
	if _fish.is_empty():
		phase = "idle"
		phase_changed.emit(snapshot())
		return

	var rod := EquipmentData.rod_by_tier(int(_state["equipment"]["rodTier"]))
	_pull_power = 7.0 + (float(rod.get("power", 0)) * 3.0 if not rod.is_empty() else 0.0)
	_reel_pct = REEL_START_PCT
	_reel_decay_per_sec = (6.0 + float(_fish["strength"]) * 3.2) * Workshop.reel_decay_mult(_state)
	phase = "reeling"
	phase_changed.emit(snapshot())


func _resolve_catch() -> void:
	var caught_fish := _fish
	var xp_gain := maxi(1, roundi(float(caught_fish["xp"]) * Effects.xp_multiplier(_state)))

	StateFormat.add_inventory(_state, caught_fish["id"], 1)
	var ranks_gained := Economy.add_xp(_state, xp_gain)
	var escamas := FishData.escamas_of(caught_fish)
	if escamas > 0:
		Economy.add_currency(_state, "escamas", escamas)

	_state["stats"]["totalCatches"] = int(_state["stats"]["totalCatches"]) + 1
	if FishData.is_rare(caught_fish):
		_state["stats"]["rareCatches"] = int(_state["stats"]["rareCatches"]) + 1

	phase = "idle"
	_fish = {}
	_reel_pct = 0.0
	fish_caught.emit({"fish": caught_fish, "xp_gain": xp_gain, "ranks_gained": ranks_gained})
	phase_changed.emit(snapshot())


func _resolve_escape() -> void:
	var lost := _fish
	_state["stats"]["totalEscaped"] = int(_state["stats"]["totalEscaped"]) + 1
	_fish = {}
	fish_escaped.emit(lost)
	# Perdeu o peixe: a linha é recolhida em vez de sumir de uma vez.
	_begin_retrieve()
