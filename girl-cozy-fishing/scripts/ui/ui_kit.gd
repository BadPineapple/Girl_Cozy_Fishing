# ui_kit.gd — a paleta e as pecinhas de interface, no lugar do que era o CSS.
#
# Direção de arte: o widget mora por cima de um papel de parede qualquer. Uma
# carta bege grande (o que tinha antes) briga com qualquer fundo e domina a
# tela; uma barra escura translúcida some no ambiente e deixa o holofote na
# personagem. Daí a paleta ter só um acento forte — o coral do botão de ação —
# e todo o resto ser madeira escura com texto creme.

class_name UiKit
extends RefCounted

# --- superfícies ---
const DOCK_BG := Color(0.13, 0.09, 0.07, 0.93)      # barra de controle
const DOCK_EDGE := Color(1, 1, 1, 0.10)             # brilho de 1px no topo
const PANEL_BG := Color(0.15, 0.11, 0.08, 0.98)     # painéis (mapa, bolso, loja)
const SLOT_BG := Color(1, 1, 1, 0.06)               # linhas de lista
const SLOT_BG_ON := Color(0.48, 0.61, 0.43, 0.20)   # linha destacada

# --- tinta ---
const CREAM := Color("#f2e3c9")
const CREAM_DIM := Color(0.95, 0.89, 0.79, 0.62)
const INK := Color("#2a1c10")

# --- acentos ---
const CORAL := Color("#e8734a")
const MOSS := Color("#8fae6b")
const DRIFTWOOD := Color("#6b4a2f")
const SHELL := Color("#f2e3c9")
const SCALE_BLUE := Color("#9fd8e8")

const FONT_BODY_PATH := "res://assets/fonts/vt323.woff2"
const FONT_DISPLAY_PATH := "res://assets/fonts/press-start-2p.woff2"

static var _font_body: Font = null
static var _font_display: Font = null
static var _fonts_loaded := false


static func _load_fonts() -> void:
	if _fonts_loaded:
		return
	_fonts_loaded = true
	_font_body = _try_font(FONT_BODY_PATH)
	_font_display = _try_font(FONT_DISPLAY_PATH)


# Se a fonte não estiver importada (ou nem existir), devolve null e a interface
# cai na fonte padrão do Godot — feio, mas nada quebra.
static func _try_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		var res: Variant = load(path)
		if res is Font:
			return res
	if FileAccess.file_exists(path):
		var file := FontFile.new()
		if file.load_dynamic_font(path) == OK:
			return file
	return null


static func font_body() -> Font:
	_load_fonts()
	return _font_body


static func font_display() -> Font:
	_load_fonts()
	return _font_display


static func apply_font(control: Control, display := false, font_size := 16) -> void:
	var f := font_display() if display else font_body()
	if f != null:
		control.add_theme_font_override("font", f)
	control.add_theme_font_size_override("font_size", font_size)


static func stylebox(bg: Color, radius := 8, pad_x := 8, pad_y := 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	return sb


static func label(text: String, font_size := 16, color := CREAM, display := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	apply_font(l, display, font_size)
	return l


# variant: "primary" (coral), "soft" (verde), "quiet" (translúcido)
static func button(text: String, variant := "primary", font_size := 16, pad_x := 10) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var bg := CORAL
	var fg := Color("#3a1a0e")
	match variant:
		"soft":
			bg = MOSS
			fg = Color("#1c2b18")
		"quiet":
			bg = Color(1, 1, 1, 0.10)
			fg = CREAM

	b.add_theme_stylebox_override("normal", stylebox(bg, 8, pad_x, 5))
	b.add_theme_stylebox_override("hover", stylebox(bg.lightened(0.12), 8, pad_x, 5))
	b.add_theme_stylebox_override("pressed", stylebox(bg.darkened(0.18), 8, pad_x, 5))
	b.add_theme_stylebox_override("disabled", stylebox(Color(bg.r, bg.g, bg.b, bg.a * 0.35), 8, pad_x, 5))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", Color(fg.r, fg.g, fg.b, 0.45))
	apply_font(b, false, font_size)
	return b


static func panel(bg: Color, radius := 8, pad_x := 8, pad_y := 4) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", stylebox(bg, radius, pad_x, pad_y))
	return p


# A barra de controle: madeira escura translúcida com um fio de luz no topo,
# que é o que dá o volume sem precisar de borda grossa.
static func dock_panel(radius := 12) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := stylebox(DOCK_BG, radius, 8, 6)
	sb.border_width_top = 1
	sb.border_color = DOCK_EDGE
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 2)
	p.add_theme_stylebox_override("panel", sb)
	return p


static func progress_bar(fill: Color, track := Color(0, 0, 0, 0.35), height := 8, radius := -1) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	bar.custom_minimum_size.y = height

	var r := radius if radius >= 0 else roundi(height / 2.0)
	var bg := stylebox(track, r, 0, 0)
	var fg := stylebox(fill, r, 0, 0)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar


# Uma linha de lista: título + subtítulo à esquerda, botão à direita.
static func row_card(config: Dictionary) -> PanelContainer:
	var bg: Color = SLOT_BG_ON if config.get("highlight", false) else SLOT_BG
	var card := panel(bg, 8, 8, 5)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	row.add_child(info)

	var title := label(config.get("title", ""), 16, CREAM)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(title)

	var sub_text: String = config.get("sub", "")
	if not sub_text.is_empty():
		var sub := label(sub_text, 13, CREAM_DIM)
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(sub)

	var button_label: String = config.get("button", "")
	if not button_label.is_empty():
		var variant: String = "soft" if config.get("equipped", false) else "primary"
		var b := button(button_label, variant, 15, 9)
		b.disabled = config.get("disabled", false)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if config.has("on_click"):
			b.pressed.connect(config["on_click"])
		row.add_child(b)

	return card


# Linha de configuração: rótulo à esquerda, controle à direita.
static func setting_row(title: String, control: Control, hint := "") -> PanelContainer:
	var card := panel(SLOT_BG, 8, 8, 4)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	info.add_child(label(title, 16, CREAM))
	if not hint.is_empty():
		var h := label(hint, 13, CREAM_DIM)
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(h)
	row.add_child(info)

	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(control)
	return card


static func slider(value: int, on_changed: Callable, width := 130) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.step = 5
	s.value = value
	s.custom_minimum_size = Vector2(width, 18)
	s.focus_mode = Control.FOCUS_NONE

	var track := stylebox(Color(0, 0, 0, 0.35), 3, 0, 0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", stylebox(CORAL, 3, 0, 0))
	s.add_theme_stylebox_override("grabber_area_highlight", stylebox(CORAL.lightened(0.15), 3, 0, 0))

	# O "grabber" padrão é uma bolinha de tema; um quadradinho creme combina
	# mais com o resto e some menos na barra.
	var grabber := GradientTexture2D.new()
	grabber.width = 8
	grabber.height = 16
	var gradient := Gradient.new()
	gradient.set_color(0, CREAM)
	gradient.set_color(1, CREAM)
	grabber.gradient = gradient
	s.add_theme_icon_override("grabber", grabber)
	s.add_theme_icon_override("grabber_highlight", grabber)

	s.value_changed.connect(func(v: float): on_changed.call(int(v)))
	return s


# Botõezinhos lado a lado, um deles marcado — pra escolhas de poucas opções
# (a escala do quadro), onde um slider seria impreciso demais.
static func segmented(options: Array, current: Variant, on_pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for option in options:
		var value: Variant = option["value"]
		var b := button(String(option["label"]), "soft" if value == current else "quiet", 14, 7)
		b.disabled = value == current
		b.pressed.connect(func(): on_pick.call(value))
		row.add_child(b)
	return row


static func toggle(value: bool, on_toggled: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.button_pressed = value
	c.focus_mode = Control.FOCUS_NONE
	c.toggled.connect(func(pressed: bool): on_toggled.call(pressed))
	return c


# "3 conchas + 10 escamas" / "Grátis"
static func cost_label(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for currency in cost:
		var amount := int(cost[currency])
		if amount > 0:
			parts.append("%d %s" % [amount, currency])
	if parts.is_empty():
		return "Grátis"
	return " + ".join(parts)


static func format_number(value: int) -> String:
	# Separador de milhar no estilo pt-BR (1.234), sem depender de locale.
	var digits := str(absi(value))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if value < 0 else "") + out
