# locations_data.gd — o "mapa": pontos que o jogador desbloqueia e visita.
# Cada local tem sua paisagem (paleta da água), seu peixário, um NPC vendedor
# com falas originais e os `venues`: os estabelecimentos que existem ali.
# Loja e ateliê não são abas — são lugares aonde se vai.
#
# venue.kind: "shop" (vender peixe / comprar equipamento) | "cosmetics" (ateliê)
# venue.always_open: true = já funciona assim que o local é desbloqueado.
# Sem always_open, o lugar precisa ser aberto uma vez (rank + custo).

class_name LocationsData
extends RefCounted

const DEFAULT_LOCATION := "ancoradouro"

const LOCATIONS := {
	"ancoradouro": {
		"id": "ancoradouro",
		"name": "Ancoradouro",
		"order": 0,
		"unlock_rank": 1,
		"unlock_cost": {},
		"water": "#2e6e75",
		"description": "Onde tudo começou: um cais de madeira gasto pelo tempo.",
		"vendor": {
			"name": "Seu Tico",
			"palette": ["#caa06b", "#7a5230", "#3a2718"],
			"lines": [
				"Bom dia! Bora ver o que a maré trouxe hoje.",
				"Essa vara aí já pescou muita coisa boa, viu.",
				"Isca fresquinha rende peixe mais graúdo.",
			],
		},
		"venues": [
			{
				"id": "loja_ancoradouro",
				"kind": "shop",
				"name": "Barraca do Seu Tico",
				"description": "Compra seu peixe e vende vara, isca e miudezas.",
				"always_open": true,
				"unlock_rank": 1,
				"unlock_cost": {},
			},
		],
	},
	"enseada": {
		"id": "enseada",
		"name": "Enseada dos Corais",
		"order": 1,
		"unlock_rank": 5,
		"unlock_cost": {"conchas": 150},
		"water": "#1f7a8c",
		"description": "Águas mais claras, recifes logo abaixo da superfície.",
		"vendor": {
			"name": "Marina",
			"palette": ["#e8a3c0", "#a3486b", "#4a1f33"],
			"lines": [
				"Cuidado com os caranguejos, eles beliscam!",
				"Já achei conchas lindas por aqui, guarda uma pra mim?",
				"A água tá um espelho hoje. Boa sorte na pesca.",
			],
		},
		"venues": [
			{
				"id": "loja_enseada",
				"kind": "shop",
				"name": "Quiosque da Marina",
				"description": "Paga um pouquinho melhor pelos achados do recife.",
				"always_open": true,
				"unlock_rank": 1,
				"unlock_cost": {},
			},
			{
				"id": "atelie_enseada",
				"kind": "cosmetics",
				"name": "Ateliê da Marina",
				"description": "Chapéus e roupas costurados na varanda, de frente pro mar.",
				"always_open": false,
				"unlock_rank": 6,
				"unlock_cost": {"conchas": 120},
			},
		],
	},
	"mar_aberto": {
		"id": "mar_aberto",
		"name": "Mar Aberto",
		"order": 2,
		"unlock_rank": 12,
		"unlock_cost": {"conchas": 500, "escamas": 20},
		"water": "#0f2e42",
		"description": "Longe da costa, onde moram os peixes de verdade.",
		"vendor": {
			"name": "Capitã Ori",
			"palette": ["#6b7fa3", "#2e3b5c", "#161c2e"],
			"lines": [
				"Águas fundas guardam coisas que a costa nunca vê.",
				"Já vi uma sombra enorme passar ali embaixo outro dia...",
				"Garrafa com bilhete de novo? Alguém tá mandando recado.",
			],
		},
		"venues": [
			{
				"id": "loja_mar_aberto",
				"kind": "shop",
				"name": "Convés da Capitã Ori",
				"description": "Negocia de tudo, desde que você chegue inteiro.",
				"always_open": true,
				"unlock_rank": 1,
				"unlock_cost": {},
			},
			{
				"id": "bau_capita",
				"kind": "cosmetics",
				"name": "Baú da Capitã",
				"description": "O que ela guardou de tanta viagem — e topa dividir.",
				"always_open": false,
				"unlock_rank": 14,
				"unlock_cost": {"escamas": 12},
			},
		],
	},
}


static func has_location(location_id: String) -> bool:
	return LOCATIONS.has(location_id)


static func get_location(location_id: String) -> Dictionary:
	return LOCATIONS.get(location_id, LOCATIONS[DEFAULT_LOCATION])


static func sorted_locations() -> Array:
	var list: Array = []
	for key in LOCATIONS:
		list.append(LOCATIONS[key])
	list.sort_custom(func(a, b): return int(a["order"]) < int(b["order"]))
	return list


static func venues_for_location(location_id: String) -> Array:
	var loc := get_location(location_id)
	return loc.get("venues", [])


# Devolve o venue com o local dele junto (o id é único no jogo inteiro).
static func venue_by_id(venue_id: String) -> Dictionary:
	for key in LOCATIONS:
		for venue in LOCATIONS[key].get("venues", []):
			if venue["id"] == venue_id:
				var copy: Dictionary = venue.duplicate(true)
				copy["location_id"] = key
				return copy
	return {}


static func all_venue_ids() -> Array:
	var ids: Array = []
	for key in LOCATIONS:
		for venue in LOCATIONS[key].get("venues", []):
			ids.append(venue["id"])
	return ids


static func water_color(location_id: String) -> Color:
	return Color(get_location(location_id).get("water", "#2e6e75"))
