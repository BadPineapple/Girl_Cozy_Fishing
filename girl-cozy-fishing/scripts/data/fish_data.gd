# fish_data.gd — catálogo de peixes (e achados curiosos) por localização.
# rarity: "comum" | "incomum" | "raro" | "lendario"
# strength: quanto o peixe "puxa" durante o minigame (afeta o decaimento da barra)
# palette: cores do desenho pixelado (ver render/pixel_sprites.gd)
#
# Porte do src/data/fish.js do widget Electron. Os ids são os mesmos de lá,
# então um save antigo continua sendo lido sem perder peixe.

class_name FishData
extends RefCounted

const RARITY_WEIGHT := {
	"comum": 100,
	"incomum": 40,
	"raro": 12,
	"lendario": 2,
}

const RARITY_LABEL := {
	"comum": "Comum",
	"incomum": "Incomum",
	"raro": "Raro",
	"lendario": "Lendário",
}

const FISH := {
	# --- Ancoradouro (início) ---
	"lambari": {
		"id": "lambari", "name": "Lambari", "location": "ancoradouro", "rarity": "comum",
		"value": 3, "xp": 2, "strength": 1, "palette": ["#c9d6a3", "#8fae5a", "#4a5c2e"],
	},
	"tilapia_cais": {
		"id": "tilapia_cais", "name": "Tilápia-do-Cais", "location": "ancoradouro", "rarity": "comum",
		"value": 4, "xp": 3, "strength": 2, "palette": ["#a9c4c9", "#5f8f96", "#2e4a4e"],
	},
	"robalo_listrado": {
		"id": "robalo_listrado", "name": "Robalo-Listrado", "location": "ancoradouro", "rarity": "incomum",
		"value": 9, "xp": 6, "strength": 3, "palette": ["#d9d3c1", "#8a8570", "#3a3830"],
	},
	"bota_velha": {
		"id": "bota_velha", "name": "Bota Velha", "location": "ancoradouro", "rarity": "raro",
		"value": 2, "xp": 1, "strength": 1, "palette": ["#6b4a2f", "#4a331f", "#2a1c10"],
		"flavor": "Não dá pra vender por muito, mas tem uma história pra contar.",
	},

	# --- Enseada ---
	"peixe_borboleta": {
		"id": "peixe_borboleta", "name": "Peixe-Borboleta", "location": "enseada", "rarity": "comum",
		"value": 6, "xp": 4, "strength": 2, "palette": ["#f2c94c", "#e07a5f", "#3d405b"],
	},
	"caranguejo_violinista": {
		"id": "caranguejo_violinista", "name": "Caranguejo-Violinista", "location": "enseada", "rarity": "incomum",
		"value": 12, "xp": 8, "strength": 4, "palette": ["#e8734a", "#b3492a", "#5c2413"],
	},
	"estrela_rosea": {
		"id": "estrela_rosea", "name": "Estrela-do-Mar Rósea", "location": "enseada", "rarity": "raro",
		"value": 22, "xp": 14, "strength": 5, "palette": ["#f4a6c1", "#d1477e", "#7a2148"],
	},
	"concha_perolada": {
		"id": "concha_perolada", "name": "Concha Perolada", "location": "enseada", "rarity": "raro",
		"value": 4, "xp": 10, "strength": 4, "escamas": 3, "palette": ["#f2e9e4", "#dcd0c0", "#a89f91"],
		"flavor": "Guarda uma pérola pequena, mas brilhante.",
	},

	# --- Mar Aberto ---
	"atum_prateado": {
		"id": "atum_prateado", "name": "Atum-Prateado", "location": "mar_aberto", "rarity": "incomum",
		"value": 18, "xp": 12, "strength": 5, "palette": ["#c7d3e0", "#7c93ab", "#374861"],
	},
	"peixe_lanterna": {
		"id": "peixe_lanterna", "name": "Peixe-Lanterna", "location": "mar_aberto", "rarity": "raro",
		"value": 35, "xp": 20, "strength": 7, "palette": ["#ffe066", "#e8a33d", "#4a3418"],
	},
	"serpente_profundezas": {
		"id": "serpente_profundezas", "name": "Serpente-das-Profundezas", "location": "mar_aberto", "rarity": "lendario",
		"value": 80, "xp": 45, "strength": 9, "palette": ["#4a2e6b", "#2d1a45", "#160d24"],
	},
	"garrafa_bilhete": {
		"id": "garrafa_bilhete", "name": "Garrafa com Bilhete", "location": "mar_aberto", "rarity": "raro",
		"value": 6, "xp": 15, "strength": 4, "escamas": 8, "palette": ["#dff0ea", "#a9cfc4", "#5c8a7d"],
		"flavor": "A tinta borrou, mas dá pra ler um pedaço da mensagem.",
	},
}


static func get_fish(fish_id: String) -> Dictionary:
	return FISH.get(fish_id, {})


static func has_fish(fish_id: String) -> bool:
	return FISH.has(fish_id)


static func fish_for_location(location_id: String) -> Array:
	var pool: Array = []
	for key in FISH:
		var fish: Dictionary = FISH[key]
		if fish["location"] == location_id:
			pool.append(fish)
	return pool


static func escamas_of(fish: Dictionary) -> int:
	return int(fish.get("escamas", 0))


static func is_rare(fish: Dictionary) -> bool:
	var rarity: String = fish.get("rarity", "comum")
	return rarity == "raro" or rarity == "lendario"


# Sorteia um peixe daquela localização, respeitando raridade + bônus de isca.
static func roll_fish(location_id: String, rare_bonus_pct: float = 0.0) -> Dictionary:
	var pool := fish_for_location(location_id)
	if pool.is_empty():
		return {}

	var weights: Array[float] = []
	var total := 0.0
	for fish in pool:
		var w := float(RARITY_WEIGHT.get(fish["rarity"], 1))
		if is_rare(fish):
			w *= 1.0 + rare_bonus_pct / 100.0
		weights.append(w)
		total += w

	var roll := randf() * total
	for i in pool.size():
		roll -= weights[i]
		if roll <= 0.0:
			return pool[i]
	return pool[pool.size() - 1]


static func palette_color(fish: Dictionary, index: int) -> Color:
	var palette: Array = fish.get("palette", ["#ffffff", "#888888", "#333333"])
	var hex: String = palette[clampi(index, 0, palette.size() - 1)]
	return Color(hex)
