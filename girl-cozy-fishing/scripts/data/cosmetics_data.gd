# cosmetics_data.gd — itens puramente visuais, equipáveis por categoria.
# slot: "hat" | "outfit" | "accessory"
# color: usado pelo desenho pixelado do personagem (render/pixel_sprites.gd).
# Uma string vazia significa "não desenha nada" (sem chapéu, sem acessório).

class_name CosmeticsData
extends RefCounted

const SLOTS := ["hat", "outfit", "accessory"]

const SLOT_LABEL := {
	"hat": "Chapéu",
	"outfit": "Roupa",
	"accessory": "Acessório",
}

const COSMETICS := {
	"hat_none": {"id": "hat_none", "slot": "hat", "name": "Sem chapéu", "cost": {}, "rank_req": 1, "color": ""},
	"hat_palha": {"id": "hat_palha", "slot": "hat", "name": "Chapéu de Palha", "cost": {"conchas": 40}, "rank_req": 1, "color": "#d9b26a"},
	"hat_boina": {"id": "hat_boina", "slot": "hat", "name": "Boina de Marinheiro", "cost": {"conchas": 80}, "rank_req": 4, "color": "#3d5a80"},
	"hat_coroa_conchinhas": {"id": "hat_coroa_conchinhas", "slot": "hat", "name": "Coroa de Conchinhas", "cost": {"escamas": 15}, "rank_req": 10, "color": "#f2e9e4"},

	"outfit_base": {"id": "outfit_base", "slot": "outfit", "name": "Roupa do dia a dia", "cost": {}, "rank_req": 1, "color": "#c97b52"},
	"outfit_moletom": {"id": "outfit_moletom", "slot": "outfit", "name": "Moletom Azul", "cost": {"conchas": 60}, "rank_req": 3, "color": "#4a6fa5"},
	"outfit_capa_amarela": {"id": "outfit_capa_amarela", "slot": "outfit", "name": "Capa Impermeável Amarela", "cost": {"conchas": 120}, "rank_req": 6, "color": "#f2c14e"},
	"outfit_festa": {"id": "outfit_festa", "slot": "outfit", "name": "Traje de Festa", "cost": {"escamas": 25}, "rank_req": 15, "color": "#7a4a8f"},

	"acc_none": {"id": "acc_none", "slot": "accessory", "name": "Sem acessório", "cost": {}, "rank_req": 1, "color": ""},
	"acc_cachecol": {"id": "acc_cachecol", "slot": "accessory", "name": "Cachecol Vermelho", "cost": {"conchas": 50}, "rank_req": 2, "color": "#b5382f"},
	"acc_oculos": {"id": "acc_oculos", "slot": "accessory", "name": "Óculos de Sol", "cost": {"conchas": 70}, "rank_req": 5, "color": "#2b2b2b"},
	"acc_brinco_perola": {"id": "acc_brinco_perola", "slot": "accessory", "name": "Brinco de Pérola", "cost": {"escamas": 10}, "rank_req": 8, "color": "#f2e9e4"},
}

const STARTER_COSMETICS := ["hat_none", "outfit_base", "acc_none"]

const DEFAULT_EQUIPPED := {
	"hat": "hat_none",
	"outfit": "outfit_base",
	"accessory": "acc_none",
}


static func has_cosmetic(cosmetic_id: String) -> bool:
	return COSMETICS.has(cosmetic_id)


static func get_cosmetic(cosmetic_id: String) -> Dictionary:
	return COSMETICS.get(cosmetic_id, {})


static func cosmetics_by_slot(slot: String) -> Array:
	var list: Array = []
	for key in COSMETICS:
		var item: Dictionary = COSMETICS[key]
		if item["slot"] == slot:
			list.append(item)
	return list


# "" (sem cor) devolve um Color transparente — o desenho pula peças assim.
static func color_of(cosmetic_id: String) -> Color:
	var item := get_cosmetic(cosmetic_id)
	var hex: String = item.get("color", "")
	if hex.is_empty():
		return Color(0, 0, 0, 0)
	return Color(hex)
