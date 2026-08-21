# upgrades_data.gd — as melhorias da Oficina, o que a tralha vira.
#
# É o que dá função pro lixo: bota velha e carrinho de supermercado desmontam em
# sucata, e sucata compra bônus permanente. Cada melhoria é única (não tem
# nível) e mexe num número específico do jogo.
#
# effect: multiplicador (1.0 = neutro) ou soma, dependendo da chave:
#   reel_decay_mult    - quanto o peixe puxa a barra pra baixo (menor = melhor)
#   travel_mult        - tempo de viagem (menor = melhor)
#   value_mult         - preço de venda (maior = melhor)
#   auto_interval_mult - intervalo do assistente (menor = melhor)
#   rare_bonus_pct     - somado ao bônus de raridade

class_name UpgradesData
extends RefCounted

const UPGRADES := {
	"molinete": {
		"id": "molinete",
		"name": "Molinete Reforçado",
		"description": "O peixe cansa antes de você: a barra cai mais devagar.",
		"cost": {"sucata": 14},
		"rank_req": 1,
		"effect": {"reel_decay_mult": 0.82},
	},
	"balde": {
		"id": "balde",
		"name": "Balde Isotérmico",
		"description": "Peixe chega fresco na balança e vale mais.",
		"cost": {"sucata": 22, "conchas": 80},
		"rank_req": 3,
		"effect": {"value_mult": 1.15},
	},
	"casco": {
		"id": "casco",
		"name": "Casco Polido",
		"description": "Menos arrasto: as viagens ficam bem mais curtas.",
		"cost": {"sucata": 30},
		"rank_req": 5,
		"effect": {"travel_mult": 0.65},
	},
	"amuleto": {
		"id": "amuleto",
		"name": "Amuleto de Escamas",
		"description": "Sorte de pescador: mais chance de coisa rara morder.",
		"cost": {"sucata": 40, "escamas": 6},
		"rank_req": 8,
		"effect": {"rare_bonus_pct": 9.0},
	},
	"radio": {
		"id": "radio",
		"name": "Rádio de Bordo",
		"description": "O assistente ouve onde o cardume está e tenta com mais frequência.",
		"cost": {"sucata": 55, "conchas": 200},
		"rank_req": 10,
		"effect": {"auto_interval_mult": 0.75},
	},
}

# Ordem de exibição na Oficina: da mais barata pra mais cara.
const ORDER := ["molinete", "balde", "casco", "amuleto", "radio"]


static func has_upgrade(upgrade_id: String) -> bool:
	return UPGRADES.has(upgrade_id)


static func get_upgrade(upgrade_id: String) -> Dictionary:
	return UPGRADES.get(upgrade_id, {})


static func all_ids() -> Array:
	return ORDER.duplicate()
