# fish_data.gd — o que dá pra fisgar.
#
# kind: "peixe"  — o de sempre: vale conchas, dá xp
#       "achado" — curiosidade que rende escamas
#       "lixo"   — tralha que a maré trouxe. Vale quase nada vendida, mas
#                  desmonta em sucata na Oficina, que é o que paga as melhorias.
#
# location: id do lugar, ou "*" pra coisa que aparece em qualquer água — é o
# caso do lixo, que não tem pátria.
#
# rarity: "lixo" | "comum" | "incomum" | "raro" | "lendario"
# strength: quanto puxa no minigame; palette: as três cores do ícone.

class_name FishData
extends RefCounted

const ANYWHERE := "*"

const RARITY_WEIGHT := {
	"lixo": 34,
	"comum": 100,
	"incomum": 40,
	"raro": 12,
	"lendario": 2,
}

const RARITY_LABEL := {
	"lixo": "Tralha",
	"comum": "Comum",
	"incomum": "Incomum",
	"raro": "Raro",
	"lendario": "Lendário",
}

const FISH := {
	# ══════════ Casa — Ancoradouro (Brasil, porto de origem) ══════════
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

	# ══════════ Enseada dos Corais (águas de casa) ══════════
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
		"kind": "achado", "value": 4, "xp": 10, "strength": 4, "escamas": 3,
		"palette": ["#f2e9e4", "#dcd0c0", "#a89f91"],
		"flavor": "Guarda uma pérola pequena, mas brilhante.",
	},

	# ══════════ Mar Aberto (águas de casa, mais fundas) ══════════
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
		"kind": "achado", "value": 6, "xp": 15, "strength": 4, "escamas": 8,
		"palette": ["#dff0ea", "#a9cfc4", "#5c8a7d"],
		"flavor": "A tinta borrou, mas dá pra ler um pedaço da mensagem.",
	},

	# ══════════ América do Sul — Rio Amazonas ══════════
	"tucunare": {
		"id": "tucunare", "name": "Tucunaré", "location": "amazonas", "rarity": "comum",
		"value": 14, "xp": 9, "strength": 4, "palette": ["#cddb8a", "#5f9e3f", "#2c4a1c"],
	},
	"piranha": {
		"id": "piranha", "name": "Piranha-Vermelha", "location": "amazonas", "rarity": "comum",
		"value": 11, "xp": 8, "strength": 3, "palette": ["#e0a89a", "#b4453b", "#4a1d18"],
		"flavor": "Cuidado com os dedos ao tirar o anzol.",
	},
	"tambaqui": {
		"id": "tambaqui", "name": "Tambaqui", "location": "amazonas", "rarity": "incomum",
		"value": 24, "xp": 15, "strength": 6, "palette": ["#b9b3a4", "#6b6455", "#2e2b24"],
	},
	"pirarucu": {
		"id": "pirarucu", "name": "Pirarucu", "location": "amazonas", "rarity": "raro",
		"value": 58, "xp": 34, "strength": 9, "palette": ["#c5cfa8", "#6f7f4e", "#7a2a2a"],
		"flavor": "Um dos maiores peixes de escama de água doce do mundo.",
	},
	"boto_cor_de_rosa": {
		"id": "boto_cor_de_rosa", "name": "Escama do Boto-Cor-de-Rosa", "location": "amazonas", "rarity": "lendario",
		"kind": "achado", "value": 20, "xp": 40, "strength": 7, "escamas": 14,
		"palette": ["#f7c6d9", "#d97ea3", "#7d3d57"],
		"flavor": "Ele passou, olhou e deixou isso. Dizem que dá sorte.",
	},

	# ══════════ América do Norte — Grandes Lagos ══════════
	"achiga": {
		"id": "achiga", "name": "Achigã", "location": "grandes_lagos", "rarity": "comum",
		"value": 12, "xp": 8, "strength": 4, "palette": ["#cbd6a6", "#5c7a45", "#2b3a20"],
	},
	"truta_arco_iris": {
		"id": "truta_arco_iris", "name": "Truta-Arco-Íris", "location": "grandes_lagos", "rarity": "comum",
		"value": 15, "xp": 10, "strength": 4, "palette": ["#e8d6c0", "#b07f9a", "#4a4a63"],
	},
	"lucio_do_norte": {
		"id": "lucio_do_norte", "name": "Lúcio-do-Norte", "location": "grandes_lagos", "rarity": "incomum",
		"value": 28, "xp": 17, "strength": 6, "palette": ["#c3cf9a", "#5f7a48", "#2b3520"],
	},
	"salmao_real": {
		"id": "salmao_real", "name": "Salmão-Real", "location": "grandes_lagos", "rarity": "raro",
		"value": 52, "xp": 30, "strength": 8, "palette": ["#f2b49a", "#d3785c", "#5c3226"],
	},

	# ══════════ Europa — Fiordes da Noruega ══════════
	"arenque": {
		"id": "arenque", "name": "Arenque", "location": "fiordes", "rarity": "comum",
		"value": 13, "xp": 9, "strength": 3, "palette": ["#dbe4ec", "#93a6b8", "#3d4a5c"],
	},
	"bacalhau": {
		"id": "bacalhau", "name": "Bacalhau-do-Atlântico", "location": "fiordes", "rarity": "comum",
		"value": 18, "xp": 12, "strength": 5, "palette": ["#d8cfae", "#8f8560", "#3f3a28"],
	},
	"salmao_atlantico": {
		"id": "salmao_atlantico", "name": "Salmão-do-Atlântico", "location": "fiordes", "rarity": "incomum",
		"value": 32, "xp": 19, "strength": 6, "palette": ["#f4bda6", "#cf7f66", "#57342a"],
	},
	"halibute": {
		"id": "halibute", "name": "Halibute-Gigante", "location": "fiordes", "rarity": "raro",
		"value": 66, "xp": 38, "strength": 9, "palette": ["#b9bdb0", "#6b7064", "#2c302a"],
		"flavor": "Sobe do fundo como um tapete que resolveu nadar.",
	},

	# ══════════ África — Rio Nilo ══════════
	"tilapia_do_nilo": {
		"id": "tilapia_do_nilo", "name": "Tilápia-do-Nilo", "location": "nilo", "rarity": "comum",
		"value": 12, "xp": 8, "strength": 3, "palette": ["#dcd2a8", "#9b8b53", "#41381f"],
	},
	"bagre_eletrico": {
		"id": "bagre_eletrico", "name": "Bagre-Elétrico", "location": "nilo", "rarity": "comum",
		"value": 17, "xp": 12, "strength": 5, "palette": ["#cfc0a0", "#7d6a4c", "#efe07a"],
		"flavor": "Formiga na mão por uns bons minutos.",
	},
	"perca_do_nilo": {
		"id": "perca_do_nilo", "name": "Perca-do-Nilo", "location": "nilo", "rarity": "incomum",
		"value": 30, "xp": 18, "strength": 7, "palette": ["#d5dbc4", "#87906f", "#3a3f2d"],
	},
	"peixe_tigre": {
		"id": "peixe_tigre", "name": "Peixe-Tigre-Golias", "location": "nilo", "rarity": "raro",
		"value": 70, "xp": 40, "strength": 9, "palette": ["#e4dcc6", "#a3763f", "#42301a"],
	},

	# ══════════ Ásia — Rio Mekong ══════════
	"peixe_arqueiro": {
		"id": "peixe_arqueiro", "name": "Peixe-Arqueiro", "location": "mekong", "rarity": "comum",
		"value": 14, "xp": 10, "strength": 3, "palette": ["#e6e0c4", "#a89b62", "#3c3722"],
		"flavor": "Cospe água pra derrubar inseto. Errou em você por pouco.",
	},
	"carpa_dourada": {
		"id": "carpa_dourada", "name": "Carpa-Dourada", "location": "mekong", "rarity": "comum",
		"value": 16, "xp": 11, "strength": 4, "palette": ["#f7d98a", "#c9932f", "#5a4113"],
	},
	"bagre_do_mekong": {
		"id": "bagre_do_mekong", "name": "Bagre-Gigante-do-Mekong", "location": "mekong", "rarity": "incomum",
		"value": 34, "xp": 21, "strength": 8, "palette": ["#c8c3b4", "#726b5c", "#2f2b24"],
	},
	"koi_ancestral": {
		"id": "koi_ancestral", "name": "Koi Ancestral", "location": "mekong", "rarity": "lendario",
		"value": 95, "xp": 52, "strength": 8, "escamas": 6,
		"palette": ["#fdf3e0", "#e07a4a", "#3a2a24"],
		"flavor": "Tem mais idade que o barco, e muito mais paciência.",
	},

	# ══════════ Oceania — Grande Barreira de Corais ══════════
	"peixe_palhaco": {
		"id": "peixe_palhaco", "name": "Peixe-Palhaço", "location": "barreira", "rarity": "comum",
		"value": 15, "xp": 10, "strength": 2, "palette": ["#ffd9a8", "#e86c1f", "#2a2118"],
	},
	"peixe_papagaio": {
		"id": "peixe_papagaio", "name": "Peixe-Papagaio", "location": "barreira", "rarity": "comum",
		"value": 19, "xp": 12, "strength": 4, "palette": ["#8fe3d0", "#2f9fb5", "#1d4a5e"],
	},
	"barramundi": {
		"id": "barramundi", "name": "Barramundi", "location": "barreira", "rarity": "incomum",
		"value": 33, "xp": 20, "strength": 6, "palette": ["#dfe5ea", "#8ba0ae", "#3a4750"],
	},
	"garoupa_batata": {
		"id": "garoupa_batata", "name": "Garoupa-Batata", "location": "barreira", "rarity": "raro",
		"value": 72, "xp": 41, "strength": 9, "palette": ["#e5dcc8", "#9d8a6a", "#3d3527"],
		"flavor": "Do tamanho de uma geladeira e igualmente teimosa.",
	},

	# ══════════ Antártida — Mar de Weddell ══════════
	"krill_cardume": {
		"id": "krill_cardume", "name": "Cardume de Krill", "location": "weddell", "rarity": "comum",
		"value": 10, "xp": 8, "strength": 2, "palette": ["#ffd2c2", "#e8836a", "#5c2f24"],
	},
	"bacalhau_antartico": {
		"id": "bacalhau_antartico", "name": "Bacalhau-Antártico", "location": "weddell", "rarity": "comum",
		"value": 22, "xp": 14, "strength": 5, "palette": ["#dceaf2", "#8fa8b8", "#39485a"],
	},
	"peixe_de_gelo": {
		"id": "peixe_de_gelo", "name": "Peixe-de-Gelo", "location": "weddell", "rarity": "incomum",
		"value": 40, "xp": 24, "strength": 6, "palette": ["#eaf6fb", "#b4d4e4", "#5d7f96"],
		"flavor": "Sangue transparente. Não tem hemoglobina e não faz falta.",
	},
	"lula_colossal": {
		"id": "lula_colossal", "name": "Lula-Colossal", "location": "weddell", "rarity": "lendario",
		"value": 120, "xp": 65, "strength": 10, "escamas": 10,
		"palette": ["#f0c9d2", "#b06a7e", "#3e2530"],
		"flavor": "O olho dela é maior que a sua cabeça. Devolveu o olhar.",
	},

	# ══════════ Tralha — aparece em qualquer água ══════════
	"bota_velha": {
		"id": "bota_velha", "name": "Bota Velha", "location": ANYWHERE, "rarity": "lixo",
		"kind": "lixo", "value": 2, "xp": 1, "strength": 1, "scrap": 2,
		"palette": ["#6b4a2f", "#4a331f", "#2a1c10"],
		"flavor": "O clássico. Não dá pra vender, mas tem história.",
	},
	"lata_amassada": {
		"id": "lata_amassada", "name": "Lata Amassada", "location": ANYWHERE, "rarity": "lixo",
		"kind": "lixo", "value": 1, "xp": 1, "strength": 1, "scrap": 3,
		"palette": ["#dfe3e6", "#9aa3a8", "#41484d"],
		"flavor": "Alumínio é alumínio.",
	},
	"meia_solitaria": {
		"id": "meia_solitaria", "name": "Meia Solitária", "location": ANYWHERE, "rarity": "lixo",
		"kind": "lixo", "value": 1, "xp": 2, "strength": 1, "scrap": 1,
		"palette": ["#e8e2f0", "#a99fc0", "#4a4258"],
		"flavor": "Em algum lugar do mundo existe o par dela. Não aqui.",
	},
	"pneu_bicicleta": {
		"id": "pneu_bicicleta", "name": "Pneu de Bicicleta", "location": ANYWHERE, "rarity": "lixo",
		"kind": "lixo", "value": 2, "xp": 2, "strength": 3, "scrap": 4,
		"palette": ["#4a4a4a", "#2e2e2e", "#161616"],
		"flavor": "Pesa como um peixe grande e luta como um saco de pedra.",
	},
	"guarda_chuva_torto": {
		"id": "guarda_chuva_torto", "name": "Guarda-Chuva Torto", "location": ANYWHERE, "rarity": "lixo",
		"kind": "lixo", "value": 3, "xp": 2, "strength": 3, "scrap": 5,
		"palette": ["#cddde8", "#4f6f88", "#22323f"],
		"flavor": "Abriu no fundo do mar e ninguém estava lá pra ver.",
	},
	"chave_inglesa": {
		"id": "chave_inglesa", "name": "Chave Inglesa", "location": ANYWHERE, "rarity": "lixo",
		"kind": "lixo", "value": 4, "xp": 2, "strength": 2, "scrap": 7,
		"palette": ["#d2d8dc", "#8d959b", "#3b4146"],
		"flavor": "Enferrujada, mas a Oficina não faz perguntas.",
	},
	"celular_encharcado": {
		"id": "celular_encharcado", "name": "Celular Encharcado", "location": ANYWHERE, "rarity": "lixo",
		"kind": "lixo", "value": 3, "xp": 4, "strength": 1, "scrap": 8,
		"palette": ["#c9ccd1", "#3f4550", "#15181d"],
		"flavor": "Ainda tem 3% de bateria. E 41 notificações.",
	},
	"oculos_sem_lente": {
		"id": "oculos_sem_lente", "name": "Óculos Sem Lente", "location": ANYWHERE, "rarity": "lixo",
		"kind": "lixo", "value": 2, "xp": 3, "strength": 1, "scrap": 3,
		"palette": ["#e6dfd2", "#7d7568", "#2f2b25"],
		"flavor": "Alguém está lendo tudo errado desde então.",
	},
	"pato_de_borracha": {
		"id": "pato_de_borracha", "name": "Pato de Borracha", "location": ANYWHERE, "rarity": "incomum",
		"kind": "lixo", "value": 6, "xp": 8, "strength": 1, "scrap": 6,
		"palette": ["#ffe27a", "#e8a91f", "#7a4c0d"],
		"flavor": "Boiou o oceano inteiro pra chegar até aqui. Merece respeito.",
	},
	"dentadura_perdida": {
		"id": "dentadura_perdida", "name": "Dentadura Perdida", "location": ANYWHERE, "rarity": "incomum",
		"kind": "lixo", "value": 5, "xp": 9, "strength": 2, "scrap": 5,
		"palette": ["#fdf6ec", "#d8c9b4", "#b4485a"],
		"flavor": "Sorriu pra você lá do fundo. Você não sorriu de volta.",
	},
	"carrinho_supermercado": {
		"id": "carrinho_supermercado", "name": "Carrinho de Supermercado", "location": ANYWHERE, "rarity": "raro",
		"kind": "lixo", "value": 8, "xp": 18, "strength": 8, "scrap": 20,
		"palette": ["#cfd6db", "#7b858c", "#333a3f"],
		"flavor": "Como. Não faça essa pergunta. Ninguém sabe como.",
	},
}


static func get_fish(fish_id: String) -> Dictionary:
	return FISH.get(fish_id, {})


static func has_fish(fish_id: String) -> bool:
	return FISH.has(fish_id)


static func kind_of(fish: Dictionary) -> String:
	return fish.get("kind", "peixe")


static func is_trash(fish: Dictionary) -> bool:
	return kind_of(fish) == "lixo"


static func scrap_of(fish: Dictionary) -> int:
	return int(fish.get("scrap", 0))


static func escamas_of(fish: Dictionary) -> int:
	return int(fish.get("escamas", 0))


# Tralha nunca conta como raridade celebrada, mesmo o carrinho de supermercado.
static func is_rare(fish: Dictionary) -> bool:
	if is_trash(fish):
		return false
	var rarity: String = fish.get("rarity", "comum")
	return rarity == "raro" or rarity == "lendario"


# O que dá pra fisgar num lugar: o peixário de lá mais a tralha, que não tem
# pátria e aparece em qualquer água.
static func fish_for_location(location_id: String) -> Array:
	var pool: Array = []
	for key in FISH:
		var fish: Dictionary = FISH[key]
		if fish["location"] == location_id or fish["location"] == ANYWHERE:
			pool.append(fish)
	return pool


static func fish_only_for_location(location_id: String) -> Array:
	var pool: Array = []
	for key in FISH:
		var fish: Dictionary = FISH[key]
		if fish["location"] == location_id:
			pool.append(fish)
	return pool


static func all_trash() -> Array:
	var pool: Array = []
	for key in FISH:
		if is_trash(FISH[key]):
			pool.append(FISH[key])
	return pool


# Sorteia respeitando raridade + bônus de isca/melhorias.
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
