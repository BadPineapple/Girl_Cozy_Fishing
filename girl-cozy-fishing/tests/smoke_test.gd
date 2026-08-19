# smoke_test.gd — checagem rápida dos sistemas sem abrir janela.
# Rode com:  Godot_v4.7.2-stable_win64_console.exe --headless --path . tests/smoke_test.tscn
#
# Não é um framework de teste: é o mesmo roteiro que valida as regras do jogo
# (pescaria, evento de valor, save corrompido, assistente, lugares) e imprime o
# resultado, pra dar pra conferir a porta do Electron num comando só.

extends Node

var _failures := 0


func _ready() -> void:
	print("== Maré — teste de fumaça ==")

	_test_fishing_loop()
	_test_event_value_multiplier()
	_test_corrupt_save_does_not_hang()
	_test_auto_fish_catchup()
	_test_offline_earnings()
	_test_cannot_buy_without_money()
	_test_venues()
	_test_save_round_trip()

	print("")
	if _failures == 0:
		print("TUDO OK")
	else:
		printerr("%d verificação(ões) falharam" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("  ok   | %s %s" % [label, detail])
	else:
		_failures += 1
		printerr("  FALHA| %s %s" % [label, detail])


func _fresh_state() -> Dictionary:
	return GameState.merge_with_defaults({})


func _test_fishing_loop() -> void:
	print("\n[1] ciclo completo de pesca")
	var state := _fresh_state()
	var session := FishingSession.new(state)
	var catches := [0]
	session.fish_caught.connect(func(_c): catches[0] += 1)

	for i in 500:
		if session.phase == "idle":
			session.start_cast()
		if session.phase == "reeling":
			session.pull()
		session.tick(100.0)

	_check("pescou alguma coisa", catches[0] > 0, "(%d fisgadas)" % catches[0])
	_check("peixe foi pro bolso", not state["inventory"].is_empty())
	_check("estatística bate com as fisgadas", int(state["stats"]["totalCatches"]) == catches[0])


func _test_event_value_multiplier() -> void:
	print("\n[2] evento de valor afeta a venda (o bug do widget original)")
	var state := _fresh_state()
	state["inventory"] = [{"fishId": "lambari", "qty": 10}]

	var plain := ShopSystem.sell_fish(state, "lambari", 5)
	state["activeEvent"] = {
		"id": "brisa_da_sorte", "title": "t", "icon": "#fff",
		"effect": {"value_multiplier": 1.3},
		"expiresAt": GameState.now_ms() + 60000.0,
	}
	var boosted := ShopSystem.sell_fish(state, "lambari", 5)
	_check("venda com evento rende mais", boosted > plain, "(%d -> %d)" % [plain, boosted])


func _test_corrupt_save_does_not_hang() -> void:
	print("\n[3] save corrompido não trava a subida de rank")
	var state := GameState.merge_with_defaults({"player": {"rank": 3, "xp": 999, "xpToNext": 0}})
	_check("xpToNext consertado na leitura", int(state["player"]["xpToNext"]) > 0,
		"(%d)" % int(state["player"]["xpToNext"]))
	Economy.add_xp(state, 5000)
	_check("subiu de rank sem travar", int(state["player"]["rank"]) > 3, "(rank %d)" % int(state["player"]["rank"]))

	var junk := GameState.merge_with_defaults({
		"player": {"rank": "abc"},
		"currencies": {"conchas": -50},
		"locationId": "lugar_que_nao_existe",
		"inventory": [{"fishId": "inexistente", "qty": 5}, {"fishId": "lambari", "qty": "3"}, {"fishId": "lambari", "qty": 2}],
		"cosmetics": {"equipped": {"hat": "outfit_festa"}},
		"unlockedVenues": ["venue_falso"],
	})
	_check("rank inválido vira 1", int(junk["player"]["rank"]) == 1)
	_check("moeda negativa vira 0", int(junk["currencies"]["conchas"]) == 0)
	_check("local desconhecido volta pro ancoradouro", junk["locationId"] == "ancoradouro")
	_check("inventário limpo e somado", junk["inventory"].size() == 1 and int(junk["inventory"][0]["qty"]) == 5,
		str(junk["inventory"]))
	_check("cosmético no slot errado é ignorado", junk["cosmetics"]["equipped"]["hat"] == "hat_none")
	_check("venue inexistente descartado", junk["unlockedVenues"].is_empty())


func _test_auto_fish_catchup() -> void:
	print("\n[4] assistente conta pelo relógio de parede")
	var state := _fresh_state()
	state["autoFish"] = {"unlocked": true, "enabled": true}
	var acc := [0.0]

	var none := AutoFish.tick(state, 1000.0, 0.0, acc)
	_check("1s não dispara tentativa", none.is_empty())

	var results := AutoFish.tick(state, AutoFish.INTERVAL_MS * 12.0, 0.0, acc)
	_check("9 minutos rendem várias fisgadas", results.size() > 0, "(%d peixes)" % results.size())

	state["autoFish"]["enabled"] = false
	_check("desligado não pesca", AutoFish.tick(state, 999999.0, 0.0, acc).is_empty())


func _test_offline_earnings() -> void:
	print("\n[5] ganhos offline")
	var state := _fresh_state()
	state["autoFish"] = {"unlocked": true, "enabled": true}
	state["lastSeen"] = GameState.now_ms() - 3.0 * 3600.0 * 1000.0

	var summary := OfflineEarnings.compute(state, 10.0)
	_check("3h fora rendem alguma coisa", not summary.is_empty() and int(summary["catches"]) > 0,
		"(%d de %d tentativas)" % [int(summary.get("catches", 0)), int(summary.get("attempts", 0))])

	var capped := _fresh_state()
	capped["autoFish"] = {"unlocked": true, "enabled": true}
	capped["lastSeen"] = GameState.now_ms() - 100.0 * 3600.0 * 1000.0
	var capped_summary := OfflineEarnings.compute(capped, 0.0)
	var max_attempts := int(OfflineEarnings.MAX_OFFLINE_MS / (AutoFish.INTERVAL_MS * OfflineEarnings.INTERVAL_MULT))
	_check("ausência longa respeita o teto de 8h", int(capped_summary["attempts"]) <= max_attempts,
		"(%d tentativas, teto %d)" % [int(capped_summary["attempts"]), max_attempts])


func _test_cannot_buy_without_money() -> void:
	print("\n[6] sem grana não compra")
	var state := _fresh_state()
	state["currencies"] = {"conchas": 0, "escamas": 0}
	state["player"]["rank"] = 20

	var before := int(state["equipment"]["rodTier"])
	var result := ShopSystem.buy_next_rod(state)
	_check("vara recusada por custo", not result.get("ok", false) and result.get("reason", "") == "cost")
	_check("tier não mudou", int(state["equipment"]["rodTier"]) == before)
	_check("cosmético recusado", not CosmeticsSystem.buy_cosmetic(state, "hat_palha").get("ok", false))
	_check("moeda não ficou negativa", int(state["currencies"]["conchas"]) >= 0)


func _test_venues() -> void:
	print("\n[7] lojas e ateliês como lugares")
	var state := _fresh_state()
	_check("loja do ancoradouro já aberta", MapSystem.is_venue_unlocked(state, "loja_ancoradouro"))
	_check("ateliê da enseada fechado", not MapSystem.is_venue_unlocked(state, "atelie_enseada"))
	_check("não abre ateliê de local bloqueado",
		MapSystem.unlock_venue(state, "atelie_enseada").get("reason", "") == "locked")

	state["player"]["rank"] = 8
	state["currencies"]["conchas"] = 1000
	MapSystem.unlock_location(state, "enseada")
	MapSystem.travel_to(state, "enseada")
	_check("loja da enseada abriu com o local", MapSystem.is_venue_unlocked(state, "loja_enseada"))

	var conchas_before := int(state["currencies"]["conchas"])
	var opened := MapSystem.unlock_venue(state, "atelie_enseada")
	_check("ateliê abre com rank e grana", opened.get("ok", false))
	_check("cobrou o preço", int(state["currencies"]["conchas"]) < conchas_before,
		"(%d -> %d)" % [conchas_before, int(state["currencies"]["conchas"])])
	_check("não cobra duas vezes", MapSystem.unlock_venue(state, "atelie_enseada").get("reason", "") == "owned")


func _test_save_round_trip() -> void:
	print("\n[8] salvar e carregar de verdade")

	# Este teste escreve no save de verdade, então o progresso existente é
	# guardado antes e devolvido no fim — rodar o teste não pode custar a
	# pescaria de ninguém.
	var previous := ""
	if FileAccess.file_exists(SaveSystem.SAVE_PATH):
		previous = FileAccess.get_file_as_string(SaveSystem.SAVE_PATH)

	var state := _fresh_state()
	state["player"]["rank"] = 7
	state["currencies"]["conchas"] = 1234
	GameState.add_inventory(state, "peixe_lanterna", 3)
	state["unlockedVenues"] = ["atelie_enseada"]

	_check("gravou o arquivo", SaveSystem.save_state(state))
	var loaded := GameState.merge_with_defaults(SaveSystem.load_state())
	_check("rank preservado", int(loaded["player"]["rank"]) == 7)
	_check("moeda preservada", int(loaded["currencies"]["conchas"]) == 1234)
	_check("peixe preservado", GameState.total_fish(loaded) == 3)
	_check("ateliê continua aberto", loaded["unlockedVenues"].has("atelie_enseada"))
	_check("nenhum .tmp sobrou", not FileAccess.file_exists(SaveSystem.TMP_PATH))
	print("  (arquivo em %s)" % SaveSystem.save_location())

	# devolve o save que estava lá antes (ou some com o do teste)
	if previous.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.SAVE_PATH))
	else:
		var file := FileAccess.open(SaveSystem.SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(previous)
			file.close()
	_check("save original devolvido",
		previous.is_empty() != FileAccess.file_exists(SaveSystem.SAVE_PATH))
