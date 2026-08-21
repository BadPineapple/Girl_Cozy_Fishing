# locations_data.gd — o mapa: um ponto por continente, mais as águas de casa.
#
# `home: true` marca o Ancoradouro, que é a base — é lá que fica a Oficina, onde
# a tralha pescada vira melhoria. Todo o resto se alcança viajando de lá.
#
# `distance` é a régua da viagem: quanto maior a diferença entre dois lugares,
# mais tempo o barco leva (ver MapSystem.travel_time_ms).
#
# `venues`: os estabelecimentos que existem ali.
#   kind: "shop" (vende/compra) | "cosmetics" (ateliê) | "workshop" (oficina)
#   always_open: já funciona assim que o local é desbloqueado.

class_name LocationsData
extends RefCounted

const DEFAULT_LOCATION := "ancoradouro"

const LOCATIONS := {
	# ──────────────── casa ────────────────
	"ancoradouro": {
		"id": "ancoradouro",
		"name": "Ancoradouro",
		"continent": "Casa",
		"home": true,
		"order": 0,
		"distance": 0,
		"unlock_rank": 1,
		"unlock_cost": {},
		"water": "#2e6e75",
		"description": "Sua base: cais de madeira, oficina nos fundos e o mar logo ali.",
		"vendor": {
			"name": "Seu Tico",
			"palette": ["#caa06b", "#7a5230", "#3a2718"],
			"lines": [
				"Bom dia! Bora ver o que a maré trouxe hoje.",
				"Trouxe tralha? A oficina aceita tudo.",
				"Isca fresquinha rende peixe mais graúdo.",
			],
		},
		"venues": [
			{
				"id": "loja_ancoradouro", "kind": "shop", "name": "Barraca do Seu Tico",
				"description": "Compra seu peixe e vende vara, isca e miudezas.",
				"always_open": true, "unlock_rank": 1, "unlock_cost": {},
			},
			{
				"id": "oficina", "kind": "workshop", "name": "Oficina do Cais",
				"description": "Desmonta a tralha em sucata e transforma sucata em melhoria.",
				"always_open": true, "unlock_rank": 1, "unlock_cost": {},
			},
		],
	},
	"enseada": {
		"id": "enseada",
		"name": "Enseada dos Corais",
		"continent": "Casa",
		"order": 1,
		"distance": 1,
		"unlock_rank": 4,
		"unlock_cost": {"conchas": 120},
		"water": "#1f7a8c",
		"description": "Logo depois da ponta: água clara e recife raso.",
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
				"id": "loja_enseada", "kind": "shop", "name": "Quiosque da Marina",
				"description": "Paga um pouquinho melhor pelos achados do recife.",
				"always_open": true, "unlock_rank": 1, "unlock_cost": {},
			},
			{
				"id": "atelie_enseada", "kind": "cosmetics", "name": "Ateliê da Marina",
				"description": "Chapéus e roupas costurados na varanda, de frente pro mar.",
				"always_open": false, "unlock_rank": 6, "unlock_cost": {"conchas": 120},
			},
		],
	},
	"mar_aberto": {
		"id": "mar_aberto",
		"name": "Mar Aberto",
		"continent": "Casa",
		"order": 2,
		"distance": 2,
		"unlock_rank": 8,
		"unlock_cost": {"conchas": 320, "escamas": 8},
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
				"id": "loja_mar_aberto", "kind": "shop", "name": "Convés da Capitã Ori",
				"description": "Negocia de tudo, desde que você chegue inteiro.",
				"always_open": true, "unlock_rank": 1, "unlock_cost": {},
			},
			{
				"id": "bau_capita", "kind": "cosmetics", "name": "Baú da Capitã",
				"description": "O que ela guardou de tanta viagem — e topa dividir.",
				"always_open": false, "unlock_rank": 14, "unlock_cost": {"escamas": 12},
			},
		],
	},

	# ──────────────── um por continente ────────────────
	"amazonas": {
		"id": "amazonas",
		"name": "Rio Amazonas",
		"continent": "América do Sul",
		"order": 3,
		"distance": 3,
		"unlock_rank": 10,
		"unlock_cost": {"conchas": 400},
		"water": "#4a5f33",
		"description": "Água barrenta e quente, mata dos dois lados, peixe grande embaixo.",
		"vendor": {
			"name": "Dona Zica",
			"palette": ["#c9a27a", "#6f4a2c", "#332013"],
			"lines": [
				"O rio dá e o rio leva, meu bem.",
				"Piranha é braba, mas frita bem.",
				"Se vir o boto, cumprimenta que ele gosta.",
			],
		},
		"venues": [
			{
				"id": "loja_amazonas", "kind": "shop", "name": "Flutuante da Dona Zica",
				"description": "Uma casa boiando com balança, gelo e café.",
				"always_open": true, "unlock_rank": 1, "unlock_cost": {},
			},
		],
	},
	"grandes_lagos": {
		"id": "grandes_lagos",
		"name": "Grandes Lagos",
		"continent": "América do Norte",
		"order": 4,
		"distance": 4,
		"unlock_rank": 13,
		"unlock_cost": {"conchas": 520, "escamas": 6},
		"water": "#2f5f7a",
		"description": "Lago tão grande que tem horizonte. Água fria e limpa.",
		"vendor": {
			"name": "Hank",
			"palette": ["#b34a3a", "#6b2b22", "#2c1310"],
			"lines": [
				"Pega no raiar do dia, é quando eles sobem.",
				"Já vi lúcio levar embora vara e tudo.",
				"Tem chocolate quente na garrafa, se quiser.",
			],
		},
		"venues": [
			{
				"id": "loja_grandes_lagos", "kind": "shop", "name": "Loja de Iscas do Hank",
				"description": "Galpão de madeira, cheiro de verniz e minhoca.",
				"always_open": true, "unlock_rank": 1, "unlock_cost": {},
			},
		],
	},
	"fiordes": {
		"id": "fiordes",
		"name": "Fiordes da Noruega",
		"continent": "Europa",
		"order": 5,
		"distance": 5,
		"unlock_rank": 16,
		"unlock_cost": {"conchas": 640, "escamas": 10},
		"water": "#20596b",
		"description": "Paredões de pedra caindo direto na água escura e funda.",
		"vendor": {
			"name": "Ingrid",
			"palette": ["#e5d2b0", "#8d6f4a", "#3a2c1c"],
			"lines": [
				"Aqui o fundo desce mais do que você imagina.",
				"Bacalhau seco guarda o inverno inteiro.",
				"Se o vento virar, volta pro cais.",
			],
		},
		"venues": [
			{
				"id": "loja_fiordes", "kind": "shop", "name": "Cais da Ingrid",
				"description": "Casinha vermelha sobre estacas, com balança de ferro.",
				"always_open": true, "unlock_rank": 1, "unlock_cost": {},
			},
			{
				"id": "atelie_fiordes", "kind": "cosmetics", "name": "Tricô da Ingrid",
				"description": "Lã grossa pra quem pesca com a mão gelada.",
				"always_open": false, "unlock_rank": 18, "unlock_cost": {"conchas": 300, "escamas": 8},
			},
		],
	},
	"nilo": {
		"id": "nilo",
		"name": "Rio Nilo",
		"continent": "África",
		"order": 6,
		"distance": 6,
		"unlock_rank": 19,
		"unlock_cost": {"conchas": 760, "escamas": 14},
		"water": "#4f6b4a",
		"description": "Margem de junco, sol pesado e uma corrente que não descansa.",
		"vendor": {
			"name": "Amani",
			"palette": ["#e0b070", "#8a5a2e", "#3b2413"],
			"lines": [
				"O rio é o mais velho aqui. Respeita ele.",
				"Perca boa é a que vem antes do meio-dia.",
				"Não encosta no bagre. Sério.",
			],
		},
		"venues": [
			{
				"id": "loja_nilo", "kind": "shop", "name": "Feluca do Amani",
				"description": "Um barco de vela que também é balcão.",
				"always_open": true, "unlock_rank": 1, "unlock_cost": {},
			},
		],
	},
	"mekong": {
		"id": "mekong",
		"name": "Rio Mekong",
		"continent": "Ásia",
		"order": 7,
		"distance": 7,
		"unlock_rank": 22,
		"unlock_cost": {"conchas": 900, "escamas": 18},
		"water": "#6b6234",
		"description": "Mercado flutuante de manhã, gigantes de bigode no fundo.",
		"vendor": {
			"name": "Sunan",
			"palette": ["#e8c07a", "#9a6b32", "#3d2a15"],
			"lines": [
				"Peixe grande aqui é do tamanho de gente.",
				"Compra chá antes de lançar. Espera é longa.",
				"A carpa dourada aparece pra quem tem calma.",
			],
		},
		"venues": [
			{
				"id": "loja_mekong", "kind": "shop", "name": "Barco do Sunan",
				"description": "Vende no meio do mercado flutuante, remando entre clientes.",
				"always_open": true, "unlock_rank": 1, "unlock_cost": {},
			},
		],
	},
	"barreira": {
		"id": "barreira",
		"name": "Grande Barreira de Corais",
		"continent": "Oceania",
		"order": 8,
		"distance": 8,
		"unlock_rank": 25,
		"unlock_cost": {"conchas": 1100, "escamas": 24},
		"water": "#158a9e",
		"description": "Água turquesa rasa por cima de uma cidade de coral.",
		"vendor": {
			"name": "Kaia",
			"palette": ["#7fd8c8", "#2c8a7c", "#134039"],
			"lines": [
				"Olha sem pisar, o coral leva anos pra crescer.",
				"Garoupa velha aqui já viu de tudo.",
				"Devolve o pequeno, ele volta grande.",
			],
		},
		"venues": [
			{
				"id": "loja_barreira", "kind": "shop", "name": "Píer da Kaia",
				"description": "Píer de tábua clara, com caixa térmica e protetor solar.",
				"always_open": true, "unlock_rank": 1, "unlock_cost": {},
			},
			{
				"id": "atelie_barreira", "kind": "cosmetics", "name": "Barraca da Kaia",
				"description": "Roupa leve e chapéu de aba larga, pro sol de rachar.",
				"always_open": false, "unlock_rank": 27, "unlock_cost": {"conchas": 500, "escamas": 16},
			},
		],
	},
	"weddell": {
		"id": "weddell",
		"name": "Mar de Weddell",
		"continent": "Antártida",
		"order": 9,
		"distance": 10,
		"unlock_rank": 30,
		"unlock_cost": {"conchas": 1500, "escamas": 35},
		"water": "#1b3b52",
		"description": "Furo no gelo, silêncio total e coisas enormes lá embaixo.",
		"vendor": {
			"name": "Dr. Halvard",
			"palette": ["#d8e4ee", "#5d738a", "#26313d"],
			"lines": [
				"Anota tudo que pescar, isso aqui é ciência.",
				"O peixe-de-gelo não tem hemoglobina. Fascinante.",
				"Não fique mais de dez minutos com a luva fora.",
			],
		},
		"venues": [
			{
				"id": "loja_weddell", "kind": "shop", "name": "Estação do Dr. Halvard",
				"description": "Contêiner aquecido que compra amostra e vende equipamento.",
				"always_open": true, "unlock_rank": 1, "unlock_cost": {},
			},
		],
	},
}


static func has_location(location_id: String) -> bool:
	return LOCATIONS.has(location_id)


static func get_location(location_id: String) -> Dictionary:
	return LOCATIONS.get(location_id, LOCATIONS[DEFAULT_LOCATION])


static func home_id() -> String:
	for key in LOCATIONS:
		if bool(LOCATIONS[key].get("home", false)):
			return key
	return DEFAULT_LOCATION


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
