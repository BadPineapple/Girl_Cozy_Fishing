# main.gd — a tela do widget: monta a interface por código, roda o game loop e
# liga os sistemas. É o equivalente ao index.html + style.css + renderer.js do
# widget Electron, tudo num lugar só.
#
# Layout (janela fixa 340x450, sem moldura e com fundo transparente):
#   [ cena — céu transparente, a área de trabalho aparece atrás ]
#   [ painel de controle: status, botão de ação, abas Mapa e Bolso ]

extends Control

const WINDOW_SIZE := Vector2i(340, 450)
const CONTENT_MARGIN := 6
const CONTENT_W := 328.0
const SCENE_H := 256.0  # 328 * 240/308 — mantém a proporção da cena

const MAX_FRAME_DT_MS := 250.0                # trava do minigame contra saltos
const MAX_WALL_DT_MS := 8 * 60 * 60 * 1000.0  # teto da recuperação do assistente
const AUTOSAVE_SECONDS := 20.0

var state: Dictionary

var _session: FishingSession
var _auto_accumulator: Array = [0.0]
var _last_wall_ms := 0.0
var _current_venue: Dictionary = {}
var _click_through := false
var _dragging := false
var _drag_offset := Vector2i.ZERO

# --- nós construídos em _build_ui ---
var _scene_view: Control
var _toast_box: VBoxContainer
var _location_label: Label
var _rank_label: Label
var _xp_bar: ProgressBar
var _conchas_label: Label
var _escamas_label: Label
var _pocket_tab: Button
var _action_button: Button
var _reel_meter: ProgressBar
var _wait_label: Label
var _auto_row: Control
var _auto_check: CheckButton
var _panel_layer: Control
var _panels: Dictionary = {}  # id -> {root, body, title}
var _context_menu: PopupMenu


func _ready() -> void:
	state = GameState.state
	get_tree().auto_accept_quit = false  # queremos salvar antes de sair
	_setup_window()
	_build_ui()

	_session = FishingSession.new(state)
	_session.phase_changed.connect(_on_phase_changed)
	_session.fish_caught.connect(_on_fish_caught)
	_session.fish_escaped.connect(_on_fish_escaped)

	# O que o assistente rendeu enquanto o jogo estava fechado.
	var offline := OfflineEarnings.compute(state, Effects.live_rare_bonus(state))
	state["lastSeen"] = GameState.now_ms()
	_last_wall_ms = GameState.now_ms()

	_refresh_status()
	_on_phase_changed(_session.snapshot())

	var autosave := Timer.new()
	autosave.wait_time = AUTOSAVE_SECONDS
	autosave.timeout.connect(_autosave)
	add_child(autosave)
	autosave.start()

	if not offline.is_empty():
		_show_offline_panel(offline)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_game()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# Minimizar não avisa de outro jeito; salvar aqui evita perder o que
		# foi pescado desde o último autosave.
		_autosave()


func _autosave() -> void:
	if not state.is_empty():
		GameState.save_now()


func _quit_game() -> void:
	_autosave()
	get_tree().quit()


# ---------------------------------------------------------------- janela
func _setup_window() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, true)
	get_viewport().transparent_bg = true
	DisplayServer.window_set_size(WINDOW_SIZE)
	_move_to_corner("bottom-right")


func _move_to_corner(corner: String) -> void:
	var usable := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var win_size := DisplayServer.window_get_size()
	var margin := 16
	var right := usable.position.x + usable.size.x - win_size.x - margin
	var bottom := usable.position.y + usable.size.y - win_size.y - margin
	var left := usable.position.x + margin
	var top := usable.position.y + margin

	var pos := Vector2i(right, bottom)
	match corner:
		"bottom-left": pos = Vector2i(left, bottom)
		"top-right": pos = Vector2i(right, top)
		"top-left": pos = Vector2i(left, top)
	DisplayServer.window_set_position(pos)


# O widget original tinha um item de bandeja pra deixar o mouse "vazar" pra
# janela de baixo. Aqui é a mesma ideia: uma região de passagem degenerada
# (sem área) faz todo clique atravessar pra área de trabalho.
func _set_click_through(enabled: bool) -> void:
	_click_through = enabled
	if enabled:
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
	else:
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array())
	_build_context_menu()


# ---------------------------------------------------------------- interface
func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_right", CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_top", CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_bottom", CONTENT_MARGIN)
	add_child(margin)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_END  # tudo encosta embaixo
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	column.add_child(_build_scene_area())
	column.add_child(_build_console_card())

	# Camada dos painéis: o MarginContainer estica os dois filhos no mesmo
	# retângulo, então ela cobre exatamente a área útil.
	_panel_layer = Control.new()
	_panel_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_panel_layer)

	_build_panels()
	_build_context_menu()


func _build_scene_area() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(CONTENT_W, SCENE_H)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	holder.gui_input.connect(_on_scene_input)

	_scene_view = preload("res://scripts/render/scene_view.gd").new()
	_scene_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(_scene_view)

	# etiqueta do lugar, no canto de baixo da água
	var tag := UiKit.panel(Color(0, 0, 0, 0.4), 8)
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_location_label = UiKit.label("", 15, UiKit.SAND_CREAM)
	tag.add_child(_location_label)
	holder.add_child(tag)
	tag.position = Vector2(8, SCENE_H - 32)
	tag.reset_size()

	# botão de esconder (minimiza; volta pela barra de tarefas)
	var hide_button := UiKit.button("–", "ghost", 14)
	hide_button.tooltip_text = "Ocultar (volta pela barra de tarefas)"
	hide_button.pressed.connect(_on_hide_pressed)
	holder.add_child(hide_button)
	hide_button.position = Vector2(CONTENT_W - 28, 2)
	hide_button.size = Vector2(26, 24)

	# avisos flutuantes
	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast_box.offset_top = 6
	_toast_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_toast_box.add_theme_constant_override("separation", 4)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_toast_box)

	return holder


func _build_console_card() -> Control:
	var card := UiKit.panel(UiKit.CARD_TOP, 14, 3, UiKit.DRIFTWOOD)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	card.add_child(box)

	# --- barra de status (rank, xp, moedas) ---
	# No widget original isso ficava no topo da janela; agora fica logo abaixo
	# da personagem, junto das abas.
	var status := UiKit.panel(UiKit.DRIFTWOOD, 9)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 6)
	status.add_child(status_row)

	var badge := UiKit.panel(UiKit.SAND_CREAM, 6)
	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 4)
	badge.add_child(badge_row)
	var badge_title := UiKit.label("Rank", 7, Color(UiKit.INK.r, UiKit.INK.g, UiKit.INK.b, 0.7), true)
	badge_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge_row.add_child(badge_title)
	_rank_label = UiKit.label("1", 10, UiKit.INK, true)
	_rank_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge_row.add_child(_rank_label)
	status_row.add_child(badge)

	_xp_bar = UiKit.progress_bar(UiKit.MOSS_GREEN)
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_xp_bar.tooltip_text = "Experiência"
	status_row.add_child(_xp_bar)

	_conchas_label = UiKit.label("0", 15, UiKit.SAND_CREAM)
	status_row.add_child(_coin_pill(UiKit.SAND_CREAM, _conchas_label, "Conchas"))
	_escamas_label = UiKit.label("0", 15, UiKit.SAND_CREAM)
	status_row.add_child(_coin_pill(Color("#9fd8e8"), _escamas_label, "Escamas"))

	box.add_child(status)

	# --- ação principal ---
	_action_button = UiKit.button("Lançar a isca", "primary", 20)
	_action_button.custom_minimum_size.y = 40
	_action_button.pressed.connect(_on_main_action)
	box.add_child(_action_button)

	_reel_meter = UiKit.progress_bar(UiKit.MOSS_GREEN, Color(0, 0, 0, 0.25), 16)
	_reel_meter.visible = false
	box.add_child(_reel_meter)

	_wait_label = UiKit.label("à espera de uma fisgada…", 15, Color(UiKit.INK.r, UiKit.INK.g, UiKit.INK.b, 0.75))
	_wait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wait_label.visible = false
	box.add_child(_wait_label)

	# --- assistente de pesca ---
	var auto_row := HBoxContainer.new()
	auto_row.add_theme_constant_override("separation", 6)
	_auto_check = CheckButton.new()
	_auto_check.focus_mode = Control.FOCUS_NONE
	_auto_check.toggled.connect(_on_auto_fish_toggled)
	auto_row.add_child(_auto_check)
	var auto_label := UiKit.label("Assistente de pesca automática", 15)
	auto_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	auto_row.add_child(auto_label)
	auto_row.visible = false
	_auto_row = auto_row
	box.add_child(auto_row)

	# --- abas ---
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)

	var map_tab := UiKit.button("Mapa", "wood", 16)
	map_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_tab.pressed.connect(_on_map_tab)
	tabs.add_child(map_tab)

	_pocket_tab = UiKit.button("Bolso 0", "wood", 16)
	_pocket_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pocket_tab.pressed.connect(_on_pocket_tab)
	tabs.add_child(_pocket_tab)

	box.add_child(tabs)
	return card


func _coin_pill(coin_color: Color, value_label: Label, tooltip: String) -> Control:
	var pill := UiKit.panel(Color(0, 0, 0, 0.25), 10)
	pill.tooltip_text = tooltip
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	pill.add_child(row)

	var coin := ColorRect.new()
	coin.color = coin_color
	coin.custom_minimum_size = Vector2(10, 10)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(coin)
	row.add_child(value_label)
	return pill


func _on_hide_pressed() -> void:
	_autosave()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)


func _on_map_tab() -> void:
	_open_panel("map")


func _on_pocket_tab() -> void:
	_open_panel("pocket")


# ---------------------------------------------------------------- painéis
func _build_panels() -> void:
	for id in ["map", "pocket", "shop", "cosmetics", "offline"]:
		_panels[id] = _make_panel(id)


func _make_panel(id: String) -> Dictionary:
	var root := UiKit.panel(UiKit.PANEL_BG, 14, 3, UiKit.DRIFTWOOD)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.visible = false
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_layer.add_child(root)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	root.add_child(column)

	var header := UiKit.panel(UiKit.DRIFTWOOD, 8)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	header.add_child(header_row)

	var title := UiKit.label("", 18, UiKit.SAND_CREAM)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_row.add_child(title)

	if id != "offline":
		var close := UiKit.button("×", "ghost", 16)
		close.custom_minimum_size = Vector2(26, 26)
		close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		close.pressed.connect(_close_panel.bind(id))
		header_row.add_child(close)

	column.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	scroll.add_child(body)

	return {"root": root, "body": body, "title": title}


func _open_panel(id: String) -> void:
	if not _panels.has(id):
		return
	# Os painéis ocupam a janela inteira: abrir um por cima do outro deixava o
	# de baixo aberto e "preso" atrás quando o de cima fechava.
	for key in _panels:
		if key != "offline":
			_panels[key]["root"].visible = false
	_panel_layer.mouse_filter = Control.MOUSE_FILTER_STOP

	match id:
		"map": _render_map_panel()
		"pocket": _render_pocket_panel()
		"shop": _render_shop_panel()
		"cosmetics": _render_cosmetics_panel()
	_panels[id]["root"].visible = true


func _close_panel(id: String) -> void:
	if not _panels.has(id):
		return
	_panels[id]["root"].visible = false
	_autosave()

	# Saiu da loja/ateliê? Volta pro mapa, que foi de onde você entrou.
	if id == "shop" or id == "cosmetics":
		_open_panel("map")
		return

	for key in _panels:
		if _panels[key]["root"].visible:
			return
	_panel_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _section_title(text: String) -> Label:
	return UiKit.label(text, 16, Color(UiKit.INK.r, UiKit.INK.g, UiKit.INK.b, 0.85))


func _muted(text: String) -> Label:
	var l := UiKit.label(text, 15, Color(UiKit.INK.r, UiKit.INK.g, UiKit.INK.b, 0.6))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


# ---- bolso ----
func _render_pocket_panel() -> void:
	var panel: Dictionary = _panels["pocket"]
	panel["title"].text = "Bolso"
	var body: VBoxContainer = panel["body"]
	_clear(body)

	if state["inventory"].is_empty():
		body.add_child(_muted("Nenhum peixe no bolso ainda. Lança a isca!"))
		return

	for entry in state["inventory"]:
		var fish := FishData.get_fish(entry["fishId"])
		if fish.is_empty():
			continue

		var card := UiKit.panel(Color(0, 0, 0, 0.06), 8)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)

		var icon := FishIcon.new()
		icon.palette = fish["palette"]
		icon.custom_minimum_size = Vector2(34, 34)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		info.add_child(UiKit.label(fish["name"], 16))
		info.add_child(UiKit.label(
			"%s — %d conchas cada" % [FishData.RARITY_LABEL[fish["rarity"]], ShopSystem.fish_sell_value(state, fish)],
			13, Color(UiKit.INK.r, UiKit.INK.g, UiKit.INK.b, 0.7)))
		row.add_child(info)

		var qty := UiKit.panel(UiKit.DRIFTWOOD, 6)
		qty.add_child(UiKit.label("x%d" % int(entry["qty"]), 10, UiKit.SAND_CREAM, true))
		qty.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(qty)

		body.add_child(card)


# ---- mapa: estabelecimentos daqui + viagens ----
func _render_map_panel() -> void:
	var panel: Dictionary = _panels["map"]
	panel["title"].text = "Mapa"
	var body: VBoxContainer = panel["body"]
	_clear(body)

	var here := MapSystem.current_location(state)
	body.add_child(_section_title("Aqui — %s" % here["name"]))

	var venues := LocationsData.venues_for_location(here["id"])
	if venues.is_empty():
		body.add_child(_muted("Nenhum estabelecimento por aqui."))

	for venue in venues:
		var venue_id: String = venue["id"]
		var unlocked := MapSystem.is_venue_unlocked(state, venue_id)
		var rank_req := int(venue.get("unlock_rank", 1))
		var cost: Dictionary = venue.get("unlock_cost", {})
		var rank_ok := int(state["player"]["rank"]) >= rank_req
		var sub_text := ""
		if unlocked:
			sub_text = venue["description"]
		else:
			sub_text = "Fechado — requer rank %d e %s" % [rank_req, UiKit.cost_label(cost)]

		body.add_child(UiKit.row_card({
			"title": venue["name"],
			"sub": sub_text,
			"button": "Entrar" if unlocked else "Abrir",
			"disabled": not unlocked and (not rank_ok or not Economy.can_afford(state, cost)),
			"highlight": unlocked,
			"on_click": _on_venue_pressed.bind(venue_id),
		}))

	body.add_child(_section_title("Viajar"))

	for place in LocationsData.sorted_locations():
		var place_id: String = place["id"]
		var unlocked := MapSystem.is_location_unlocked(state, place_id)
		var is_here: bool = state["locationId"] == place_id
		var button_text := "Desbloquear"
		if is_here:
			button_text = "Você está aqui"
		elif unlocked:
			button_text = "Viajar"
		var sub_text := ""
		if unlocked:
			sub_text = place["description"]
		else:
			sub_text = "Requer rank %d — %s" % [int(place["unlock_rank"]), UiKit.cost_label(place["unlock_cost"])]
		var blocked: bool = is_here or (not unlocked and (
			int(state["player"]["rank"]) < int(place["unlock_rank"])
			or not Economy.can_afford(state, place["unlock_cost"])))

		body.add_child(UiKit.row_card({
			"title": place["name"],
			"sub": sub_text,
			"button": button_text,
			"disabled": blocked,
			"equipped": is_here,
			"on_click": _on_travel_pressed.bind(place_id),
		}))


func _on_venue_pressed(venue_id: String) -> void:
	if MapSystem.is_venue_unlocked(state, venue_id):
		var venue := LocationsData.venue_by_id(venue_id)
		if venue.is_empty():
			return
		_current_venue = venue
		_open_panel("cosmetics" if venue["kind"] == "cosmetics" else "shop")
		return

	var result := MapSystem.unlock_venue(state, venue_id)
	if result.get("ok", false):
		_toast("🔓 %s agora está aberto!" % result["venue"]["name"])
		_refresh_status()
		_autosave()
	_render_map_panel()


func _on_travel_pressed(location_id: String) -> void:
	if MapSystem.is_location_unlocked(state, location_id):
		MapSystem.travel_to(state, location_id)
	elif MapSystem.unlock_location(state, location_id).get("ok", false):
		MapSystem.travel_to(state, location_id)
	_render_map_panel()
	_refresh_status()
	_autosave()


# ---- loja ----
func _render_shop_panel() -> void:
	var panel: Dictionary = _panels["shop"]
	panel["title"].text = _current_venue.get("name", "Loja")
	var body: VBoxContainer = panel["body"]
	_clear(body)

	body.add_child(_section_title("Seu peixe"))
	if state["inventory"].is_empty():
		body.add_child(_muted("Volte depois de pescar algo!"))

	for entry in state["inventory"]:
		var fish := FishData.get_fish(entry["fishId"])
		if fish.is_empty():
			continue
		var unit_value := ShopSystem.fish_sell_value(state, fish)
		var bonus_tag := ""
		if unit_value > int(fish["value"]):
			bonus_tag = " (evento!)"
		body.add_child(UiKit.row_card({
			"title": "%s x %d" % [fish["name"], int(entry["qty"])],
			"sub": "%s — vale %d conchas cada%s" % [FishData.RARITY_LABEL[fish["rarity"]], unit_value, bonus_tag],
			"button": "Vender 1",
			"on_click": _on_sell_one.bind(String(fish["id"])),
		}))

	var sell_all := UiKit.button("Vender tudo", "soft", 15)
	sell_all.pressed.connect(_on_sell_all)
	body.add_child(sell_all)

	body.add_child(_section_title("Equipamento"))

	var rod := ShopSystem.next_rod(state)
	if rod.is_empty():
		body.add_child(UiKit.row_card({"title": "Vara no nível máximo"}))
	else:
		body.add_child(UiKit.row_card({
			"title": rod["name"],
			"sub": "Requer rank %d — %s" % [int(rod["rank_req"]), UiKit.cost_label(rod["cost"])],
			"button": "Comprar",
			"disabled": int(state["player"]["rank"]) < int(rod["rank_req"]) or not Economy.can_afford(state, rod["cost"]),
			"on_click": _on_buy_rod,
		}))

	var bait := ShopSystem.next_bait(state)
	if bait.is_empty():
		body.add_child(UiKit.row_card({"title": "Isca no nível máximo"}))
	else:
		body.add_child(UiKit.row_card({
			"title": bait["name"],
			"sub": "Requer rank %d — %s" % [int(bait["rank_req"]), UiKit.cost_label(bait["cost"])],
			"button": "Comprar",
			"disabled": int(state["player"]["rank"]) < int(bait["rank_req"]) or not Economy.can_afford(state, bait["cost"]),
			"on_click": _on_buy_bait,
		}))

	if not bool(state["autoFish"]["unlocked"]):
		var unlock := EquipmentData.AUTO_FISH_UNLOCK
		body.add_child(UiKit.row_card({
			"title": unlock["name"],
			"sub": "Requer rank %d — %s" % [int(unlock["rank_req"]), UiKit.cost_label(unlock["cost"])],
			"button": "Comprar",
			"disabled": int(state["player"]["rank"]) < int(unlock["rank_req"]) or not Economy.can_afford(state, unlock["cost"]),
			"on_click": _on_buy_auto_fish,
		}))


func _on_sell_one(fish_id: String) -> void:
	ShopSystem.sell_fish(state, fish_id, 1)
	_render_shop_panel()
	_refresh_status()


func _on_sell_all() -> void:
	var total := ShopSystem.sell_all(state)
	if total > 0:
		_toast("💰 +%s conchas" % UiKit.format_number(total))
	_render_shop_panel()
	_refresh_status()


func _on_buy_rod() -> void:
	ShopSystem.buy_next_rod(state)
	_render_shop_panel()
	_refresh_status()
	_autosave()


func _on_buy_bait() -> void:
	ShopSystem.buy_next_bait(state)
	_render_shop_panel()
	_refresh_status()
	_autosave()


func _on_buy_auto_fish() -> void:
	ShopSystem.buy_auto_fish_unlock(state)
	_render_shop_panel()
	_refresh_status()
	_autosave()


# ---- cosméticos (ateliê) ----
func _render_cosmetics_panel() -> void:
	var panel: Dictionary = _panels["cosmetics"]
	panel["title"].text = _current_venue.get("name", "Cosméticos")
	var body: VBoxContainer = panel["body"]
	_clear(body)

	for slot in CosmeticsData.SLOTS:
		body.add_child(_section_title(CosmeticsData.SLOT_LABEL[slot]))
		for item in CosmeticsData.cosmetics_by_slot(slot):
			var item_id: String = item["id"]
			var owned := CosmeticsSystem.owns(state, item_id)
			var equipped := CosmeticsSystem.is_equipped(state, item_id)
			var can_buy := int(state["player"]["rank"]) >= int(item["rank_req"]) \
					and Economy.can_afford(state, item["cost"])
			var button_text := "Comprar"
			if equipped:
				button_text = "Equipado"
			elif owned:
				button_text = "Equipar"
			var sub_text := ""
			if not owned:
				sub_text = "Requer rank %d — %s" % [int(item["rank_req"]), UiKit.cost_label(item["cost"])]

			body.add_child(UiKit.row_card({
				"title": item["name"],
				"sub": sub_text,
				"button": button_text,
				"disabled": equipped or (not owned and not can_buy),
				"equipped": equipped,
				"on_click": _on_cosmetic_pressed.bind(item_id),
			}))


func _on_cosmetic_pressed(cosmetic_id: String) -> void:
	# Comprar já equipa: dois cliques pra ver o item no boneco era chato.
	if CosmeticsSystem.owns(state, cosmetic_id):
		CosmeticsSystem.equip_cosmetic(state, cosmetic_id)
	elif CosmeticsSystem.buy_cosmetic(state, cosmetic_id).get("ok", false):
		CosmeticsSystem.equip_cosmetic(state, cosmetic_id)
	_render_cosmetics_panel()
	_refresh_status()
	_autosave()


# ---- resumo offline ----
func _show_offline_panel(summary: Dictionary) -> void:
	var panel: Dictionary = _panels["offline"]
	panel["title"].text = "Enquanto você estava fora…"
	var body: VBoxContainer = panel["body"]
	_clear(body)

	var hours := float(summary["elapsed_ms"]) / 3600000.0
	var parts: Array[String] = [
		"O assistente de pesca trabalhou por %.1fh." % hours,
		"Pescou %d peixe(s) (%d raro(s))." % [int(summary["catches"]), int(summary["rare_catches"])],
		"Ganhou %d de XP." % int(summary["xp"]),
	]
	if int(summary["escamas"]) > 0:
		parts.append("+%d escamas." % int(summary["escamas"]))

	var text := UiKit.label(" ".join(parts), 15)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(text)

	var ok := UiKit.button("Legal!", "soft", 16)
	ok.pressed.connect(_close_offline_panel)
	body.add_child(ok)

	_panel_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	panel["root"].visible = true


func _close_offline_panel() -> void:
	_panels["offline"]["root"].visible = false
	_close_panel("offline")


# ---------------------------------------------------------------- game loop
func _process(delta: float) -> void:
	var frame_dt := minf(MAX_FRAME_DT_MS, delta * 1000.0)

	# O assistente conta pelo relógio de parede, não pelo tempo de frame: com a
	# janela minimizada o processamento pode parar, e aí ele parava junto.
	var now := GameState.now_ms()
	var wall_dt := clampf(now - _last_wall_ms, 0.0, MAX_WALL_DT_MS)
	_last_wall_ms = now

	_session.tick(frame_dt)

	var results := AutoFish.tick(state, wall_dt, Effects.live_rare_bonus(state), _auto_accumulator)
	if not results.is_empty():
		if results.size() == 1:
			_toast("🤖 Assistente pescou: %s" % results[0]["fish"]["name"])
		else:
			_toast("🤖 Assistente pescou %d peixes" % results.size())
		_refresh_status()

	var event := EventsEngine.tick(state, now)
	if not event.is_empty():
		_toast("✨ %s" % event["title"])

	if _scene_view != null:
		_scene_view.fishing_phase = _session.phase


func _on_main_action() -> void:
	if _session.phase == "idle":
		_session.start_cast()
	elif _session.phase == "reeling":
		_session.pull()


func _on_phase_changed(snapshot: Dictionary) -> void:
	_reel_meter.visible = false
	_wait_label.visible = false
	_action_button.disabled = false

	match snapshot["phase"]:
		"idle":
			_action_button.text = "Lançar a isca"
		"casting":
			_action_button.text = "Lançando…"
			_action_button.disabled = true
		"waiting":
			_action_button.text = "Aguardando…"
			_action_button.disabled = true
			_wait_label.visible = true
		"reeling":
			_action_button.text = "Puxar!"
			_reel_meter.visible = true
			_reel_meter.value = float(snapshot["reel_pct"])


func _on_fish_caught(caught: Dictionary) -> void:
	var fish: Dictionary = caught["fish"]
	var tag := ""
	if FishData.is_rare(fish):
		tag = " (%s!)" % FishData.RARITY_LABEL[fish["rarity"]]
	_toast("🎣 Pescou: %s%s" % [fish["name"], tag])
	if int(caught["ranks_gained"]) > 0:
		_toast("⭐ Subiu para o rank %d!" % int(state["player"]["rank"]))
	_refresh_status()


func _on_fish_escaped(fish: Dictionary) -> void:
	if fish.is_empty():
		_toast("Escapou...")
	else:
		_toast("%s escapou..." % fish["name"])


func _on_auto_fish_toggled(pressed: bool) -> void:
	# Sem o unlocked a linha nem aparece, mas o estado é o que manda.
	var enabled := bool(state["autoFish"]["unlocked"]) and pressed
	state["autoFish"]["enabled"] = enabled
	_auto_check.set_pressed_no_signal(enabled)
	_auto_accumulator[0] = 0.0
	_autosave()


func _refresh_status() -> void:
	_rank_label.text = str(int(state["player"]["rank"]))
	_xp_bar.value = minf(100.0, float(state["player"]["xp"]) / maxf(1.0, float(state["player"]["xpToNext"])) * 100.0)
	_conchas_label.text = UiKit.format_number(int(state["currencies"]["conchas"]))
	_escamas_label.text = UiKit.format_number(int(state["currencies"]["escamas"]))
	_location_label.text = MapSystem.current_location(state)["name"]
	_pocket_tab.text = "Bolso %s" % UiKit.format_number(GameState.total_fish(state))
	_auto_row.visible = bool(state["autoFish"]["unlocked"])
	_auto_check.set_pressed_no_signal(bool(state["autoFish"]["enabled"]))


# ---------------------------------------------------------------- avisos
func _toast(text: String) -> void:
	var card := UiKit.panel(Color(0.08, 0.055, 0.03, 0.85), 8)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UiKit.label(text, 14, UiKit.SAND_CREAM)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(l)
	_toast_box.add_child(card)

	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(card, "modulate:a", 0.0, 0.6)
	tween.tween_callback(card.queue_free)


# ---------------------------------------------------------------- arrastar e menu
func _on_scene_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
			if mb.pressed:
				_drag_offset = DisplayServer.mouse_get_position() - DisplayServer.window_get_position()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_context_menu.position = DisplayServer.mouse_get_position()
			_context_menu.popup()
	elif event is InputEventMouseMotion and _dragging:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - _drag_offset)


func _build_context_menu() -> void:
	if _context_menu == null:
		_context_menu = PopupMenu.new()
		add_child(_context_menu)
		_context_menu.id_pressed.connect(_on_context_menu)
	_context_menu.clear()
	_context_menu.add_item("Maré — pesca cozy", 0)
	_context_menu.set_item_disabled(0, true)
	_context_menu.add_separator()
	if _click_through:
		_context_menu.add_item("Desativar clique-atravessa", 1)
	else:
		_context_menu.add_item("Ativar clique-atravessa (não atrapalha o mouse)", 1)
	_context_menu.add_separator()
	_context_menu.add_item("Canto inferior direito", 10)
	_context_menu.add_item("Canto inferior esquerdo", 11)
	_context_menu.add_item("Canto superior direito", 12)
	_context_menu.add_item("Canto superior esquerdo", 13)
	_context_menu.add_separator()
	_context_menu.add_item("Sair", 99)
	_context_menu.reset_size()


func _on_context_menu(id: int) -> void:
	match id:
		1: _set_click_through(not _click_through)
		10: _move_to_corner("bottom-right")
		11: _move_to_corner("bottom-left")
		12: _move_to_corner("top-right")
		13: _move_to_corner("top-left")
		99: _quit_game()
