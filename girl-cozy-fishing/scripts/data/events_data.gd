# events_data.gd — eventos aleatórios e passageiros que dão um empurrãozinho
# temporário. São só flavor + multiplicadores.
#
# Os efeitos ficam num sub-dicionário `effect`, lido sempre pelo effects.gd —
# no widget original cada sistema lia esse dicionário por conta própria e um
# deles esquecia de aplicar o multiplicador de valor, deixando um evento inerte.

class_name EventsData
extends RefCounted

const EVENTS := [
	{
		"id": "cardume_raro",
		"title": "Cardume raro por perto!",
		"icon": "#e8734a",
		"duration_ms": 3 * 60 * 1000,
		"weight": 20,
		"effect": {"rare_bonus_pct": 25.0},
	},
	{
		"id": "mare_cheia",
		"title": "Maré cheia — os peixes mordem rápido!",
		"icon": "#2e6e75",
		"duration_ms": 4 * 60 * 1000,
		"weight": 25,
		"effect": {"bite_wait_multiplier": 0.5},
	},
	{
		"id": "brisa_da_sorte",
		"title": "Uma brisa de sorte passou por aqui.",
		"icon": "#f2c14e",
		"duration_ms": 5 * 60 * 1000,
		"weight": 20,
		"effect": {"value_multiplier": 1.3},
	},
	{
		"id": "visita_gaivota",
		"title": "Uma gaivota curiosa pousou no barco.",
		"icon": "#f2e9e4",
		"duration_ms": 2 * 60 * 1000,
		"weight": 15,
		"effect": {"xp_multiplier": 1.5},
	},
]


static func roll_event() -> Dictionary:
	var total := 0.0
	for e in EVENTS:
		total += float(e["weight"])

	var roll := randf() * total
	for e in EVENTS:
		roll -= float(e["weight"])
		if roll <= 0.0:
			return e
	return EVENTS[0]
