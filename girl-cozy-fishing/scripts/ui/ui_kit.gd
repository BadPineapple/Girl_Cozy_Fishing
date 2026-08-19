# ui_kit.gd — a paleta e as pecinhas de interface, no lugar do que era o CSS.
# Tudo é montado por código: a cena principal fica sendo só um Control vazio, o
# que evita depender de um .tscn gigante e mantém o visual num arquivo só.

class_name UiKit
extends RefCounted

# Mesma paleta do widget original (as variáveis :root do CSS).
const SKY_DUSK := Color("#3b4a6b")
const TIDE_TEAL := Color("#2e6e75")
const DRIFTWOOD := Color("#6b4a2f")
const DRIFTWOOD_DARK := Color("#4a331f")
const SAND_CREAM := Color("#f2e3c9")
const EMBER_CORAL := Color("#e8734a")
const EMBER_CORAL_DARK := Color("#a94a26")
const MOSS_GREEN := Color("#7a9b6e")
const INK := Color("#2a1c10")
const PANEL_BG := Color("#f2e3c9")
const CARD_TOP := Color("#efe0bd")

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


static func stylebox(bg: Color, radius := 8, border := 0, border_color := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	if border > 0:
		sb.border_width_left = border
		sb.border_width_right = border
		sb.border_width_top = border
		sb.border_width_bottom = border
		sb.border_color = border_color
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	return sb


static func label(text: String, font_size := 16, color := INK, display := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	apply_font(l, display, font_size)
	return l


# variant: "primary" (coral), "soft" (verde), "wood" (madeira), "ghost" (escuro)
static func button(text: String, variant := "primary", font_size := 16) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var bg := EMBER_CORAL
	var fg := Color.WHITE
	match variant:
		"soft":
			bg = MOSS_GREEN
			fg = Color("#1c2b18")
		"wood":
			bg = DRIFTWOOD
			fg = SAND_CREAM
		"ghost":
			bg = Color(0.08, 0.05, 0.03, 0.55)
			fg = SAND_CREAM

	b.add_theme_stylebox_override("normal", stylebox(bg))
	b.add_theme_stylebox_override("hover", stylebox(bg.lightened(0.08)))
	b.add_theme_stylebox_override("pressed", stylebox(bg.darkened(0.15)))
	b.add_theme_stylebox_override("disabled", stylebox(Color(bg.r, bg.g, bg.b, 0.35)))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", Color(fg.r, fg.g, fg.b, 0.5))
	apply_font(b, false, font_size)
	return b


static func panel(bg: Color, radius := 8, border := 0, border_color := Color(0, 0, 0, 0)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", stylebox(bg, radius, border, border_color))
	return p


static func progress_bar(fill: Color, track := Color(0, 0, 0, 0.35), height := 10) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	bar.custom_minimum_size.y = height

	var bg := stylebox(track, roundi(height / 2.0))
	bg.content_margin_left = 0
	bg.content_margin_right = 0
	bg.content_margin_top = 0
	bg.content_margin_bottom = 0
	var fg := stylebox(fill, roundi(height / 2.0))
	fg.content_margin_left = 0
	fg.content_margin_right = 0
	fg.content_margin_top = 0
	fg.content_margin_bottom = 0

	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar


# Uma linha de lista: título + subtítulo à esquerda, botão à direita.
# É o `rowCard` do renderer.js.
static func row_card(config: Dictionary) -> PanelContainer:
	var bg := Color(0, 0, 0, 0.06)
	if config.get("highlight", false):
		bg = Color(MOSS_GREEN.r, MOSS_GREEN.g, MOSS_GREEN.b, 0.18)

	var card := panel(bg, 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	row.add_child(info)

	var title := label(config.get("title", ""), 16)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(title)

	var sub_text: String = config.get("sub", "")
	if not sub_text.is_empty():
		var sub := label(sub_text, 13, Color(INK.r, INK.g, INK.b, 0.7))
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(sub)

	var button_label: String = config.get("button", "")
	if not button_label.is_empty():
		var variant: String = "soft" if config.get("equipped", false) else "primary"
		var b := button(button_label, variant, 15)
		b.disabled = config.get("disabled", false)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if config.has("on_click"):
			b.pressed.connect(config["on_click"])
		row.add_child(b)

	return card


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
