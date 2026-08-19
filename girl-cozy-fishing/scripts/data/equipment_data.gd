# equipment_data.gd — upgrades funcionais: vara, isca e o "assistente de pesca"
# (auto-fish). Cada tier melhora um número específico do sistema de pesca.

class_name EquipmentData
extends RefCounted

const RODS := [
	{"tier": 1, "id": "vara_inicial", "name": "Vara Improvisada", "cost": {}, "rank_req": 1, "power": 1},
	{"tier": 2, "id": "vara_bambu", "name": "Vara de Bambu", "cost": {"conchas": 100}, "rank_req": 3, "power": 2},
	{"tier": 3, "id": "vara_reforcada", "name": "Vara Reforçada", "cost": {"conchas": 300, "escamas": 10}, "rank_req": 8, "power": 3},
	{"tier": 4, "id": "vara_encantada", "name": "Vara Encantada", "cost": {"escamas": 20}, "rank_req": 12, "power": 5},
]

const BAITS := [
	{"tier": 1, "id": "isca_comum", "name": "Isca Comum", "cost": {}, "rank_req": 1, "rare_bonus_pct": 0},
	{"tier": 2, "id": "isca_fresca", "name": "Isca Fresca", "cost": {"conchas": 60}, "rank_req": 3, "rare_bonus_pct": 10},
	{"tier": 3, "id": "isca_brilhante", "name": "Isca Brilhante", "cost": {"conchas": 150, "escamas": 5}, "rank_req": 8, "rare_bonus_pct": 20},
	{"tier": 4, "id": "isca_mistica", "name": "Isca Mística", "cost": {"escamas": 15}, "rank_req": 12, "rare_bonus_pct": 35},
]

const AUTO_FISH_UNLOCK := {
	"id": "assistente_pesca",
	"name": "Assistente de Pesca",
	"cost": {"conchas": 250},
	"rank_req": 8,
	"description": "Deixa a vara pescando sozinha, mesmo com você longe do teclado.",
}


static func rod_by_tier(tier: int) -> Dictionary:
	for rod in RODS:
		if int(rod["tier"]) == tier:
			return rod
	return {}


static func bait_by_tier(tier: int) -> Dictionary:
	for bait in BAITS:
		if int(bait["tier"]) == tier:
			return bait
	return {}


static func max_rod_tier() -> int:
	return int(RODS[RODS.size() - 1]["tier"])


static func max_bait_tier() -> int:
	return int(BAITS[BAITS.size() - 1]["tier"])
