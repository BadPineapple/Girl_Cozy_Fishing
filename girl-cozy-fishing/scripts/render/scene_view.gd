# scene_view.gd — a cena: água, doca e personagem. Sem céu de propósito — o topo
# fica transparente e quem aparece atrás é a área de trabalho.
#
# Composição (460x166, deitado, pra viver num canto de tela):
#
#   doca ──┐                    boia          ilha distante
#          │  personagem  ·······•·······        ╭──╮
#   ═══════╧════ poste ═══════════════════════════════════
#   ~~~~~~~~~~~~~~~~ água ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# A personagem ocupa quase toda a altura (é a estrela) e a água é só uma faixa
# baixa. A linha de pesca só existe durante a pescaria: fora dela a vara fica
# recolhida na mão.

extends Control

const BASE_W := 460.0
const BASE_H := 166.0
const WATER_Y := 128.0
const CHAR_SCALE := 6.0
const CHAR_X := 55.0
const RAFT_X := -4.0
const RAFT_W := 214.0

var fishing_phase: String = "idle"
var retrieve_progress := 0.0  # 0..1 durante a fase "recolhendo"

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


static func aspect_height(width: float) -> float:
	return width * BASE_H / BASE_W


func _night_factor() -> float:
	var t := Time.get_time_dict_from_system(false)  # relógio local, não UTC
	var h := float(t["hour"]) + float(t["minute"]) / 60.0
	return (cos((h / 24.0) * TAU) + 1.0) / 2.0  # 0 = meio-dia, 1 = meia-noite


func _draw() -> void:
	var state: Dictionary = GameState.state
	if state.is_empty():
		return

	var k := size.x / BASE_W  # escala lógica -> pixels
	var night := _night_factor()
	var water := LocationsData.water_color(state["locationId"])

	_draw_island(k, night, water)
	_draw_water(k, night, water)
	_draw_raft(k, night)
	_draw_character(k, state)
	_draw_line_and_bobber(k)
	_draw_lamp_glow(k, night)


# Uma ilhota no horizonte, à direita: dá profundidade e fecha a composição do
# lado que antes era só água vazia.
func _draw_island(k: float, night: float, water: Color) -> void:
	var tint := water.darkened(0.35).lerp(Color("#0b1420"), 0.35 + night * 0.3)
	var base := WATER_Y + 1.0
	var blocks := [
		[366.0, base - 9.0, 76.0, 9.0],
		[378.0, base - 14.0, 50.0, 5.0],
		[392.0, base - 18.0, 22.0, 4.0],
		[336.0, base - 4.0, 22.0, 4.0],  # pedrinha solta
	]
	for b in blocks:
		draw_rect(Rect2(Vector2(b[0], b[1]) * k, Vector2(b[2], b[3]) * k), tint, true)


func _draw_water(k: float, night: float, water: Color) -> void:
	var surface := water.lightened(0.14).lerp(Color("#02040a"), night * 0.5)
	var deep := water.darkened(0.5).lerp(Color("#01030a"), night * 0.5)

	# Faixas horizontais em vez de gradiente: mantém o look pixelado e a borda
	# de cima não vira um corte seco contra a área de trabalho.
	const BANDS := 8
	var band_h := (BASE_H - WATER_Y) / float(BANDS)
	for i in BANDS:
		var t := float(i) / float(BANDS - 1)
		var y := WATER_Y + band_h * float(i)
		draw_rect(
			Rect2(Vector2(0, y * k), Vector2(size.x, (band_h + 1.0) * k)),
			surface.lerp(deep, t),
			true
		)

	# Linha d'água: sobe e desce de leve, em degraus de 1px. É o que faz a
	# superfície "respirar" em vez de ser um corte reto parado.
	var swell := roundf(sin(_time * 0.9) * 1.5)
	draw_rect(Rect2(Vector2(0, (WATER_Y + swell) * k), Vector2(size.x, 1.5 * k)), surface.lightened(0.4), true)

	# Ondinhas de crista: correm de verdade pra esquerda (antes iam e voltavam
	# com um seno, o que lia como tremor, não como correnteza).
	var foam := Color(1, 1, 1, 0.10)
	for row in 3:
		var y := WATER_Y + 7.0 + float(row) * 12.0
		var period := 96.0 + float(row) * 27.0
		var speed := 5.0 + float(row) * 2.5
		var x := -period + fmod(-_time * speed, period)
		var bobbing := roundf(sin(_time * 1.1 + float(row) * 1.7) * 1.0)
		while x < BASE_W:
			draw_rect(Rect2(Vector2(x, y + bobbing) * k, Vector2(15.0, 1.5) * k), foam, true)
			draw_rect(Rect2(Vector2(x + 24.0, y + bobbing) * k, Vector2(5.0, 1.5) * k), foam, true)
			x += period

	# Brilho pontual que aparece e some, como sol batendo na crista.
	for i in 3:
		var phase := _time * 0.55 + float(i) * 2.1
		var twinkle := sin(phase)
		if twinkle <= 0.55:
			continue
		var gx := fmod(78.0 + float(i) * 151.0 + floorf(phase / TAU) * 43.0, BASE_W - 20.0) + 10.0
		var gy := WATER_Y + 4.0 + float(i % 2) * 9.0
		draw_rect(
			Rect2(Vector2(gx, gy) * k, Vector2(3.0, 1.5) * k),
			Color(1, 1, 1, (twinkle - 0.55) * 0.55),
			true
		)


func _draw_raft(k: float, night: float) -> void:
	var raft_y := WATER_Y - 8.0
	var plank := Color("#7a5433")
	var plank_dark := Color("#4a331f")
	var post_x := RAFT_X + 24.0  # ponta esquerda: deixa a linha de pesca voar limpa

	# sombra da doca na água
	draw_rect(
		Rect2(Vector2(RAFT_X + 4.0, raft_y + 10.0) * k, Vector2(RAFT_W, 4.0) * k),
		Color(0, 0, 0, 0.20), true
	)

	# poste primeiro: o tabuado passa por cima da base dele
	draw_rect(Rect2(Vector2(post_x, raft_y - 34.0) * k, Vector2(7.0, 40.0) * k), plank_dark, true)
	draw_rect(Rect2(Vector2(post_x, raft_y - 34.0) * k, Vector2(2.0, 40.0) * k), plank_dark.lightened(0.15), true)
	# lanterna pendurada
	draw_rect(Rect2(Vector2(post_x - 3.0, raft_y - 42.0) * k, Vector2(13.0, 9.0) * k), plank_dark, true)
	var lamp := Color("#ffd28a") if night > 0.3 else Color("#9a8a70")
	draw_rect(Rect2(Vector2(post_x - 1.0, raft_y - 40.0) * k, Vector2(9.0, 5.0) * k), lamp, true)

	# tabuado
	draw_rect(Rect2(Vector2(RAFT_X, raft_y) * k, Vector2(RAFT_W, 10.0) * k), plank, true)
	draw_rect(Rect2(Vector2(RAFT_X, raft_y) * k, Vector2(RAFT_W, 2.0) * k), plank.lightened(0.16), true)
	draw_rect(Rect2(Vector2(RAFT_X, raft_y + 8.0) * k, Vector2(RAFT_W, 2.0) * k), plank_dark, true)
	var plank_count := 7
	for i in plank_count:
		var x := RAFT_X + float(i) * RAFT_W / float(plank_count)
		draw_rect(Rect2(Vector2(x, raft_y) * k, Vector2(1.5, 10.0) * k), plank_dark, true)

	# estaca curta afundando na água, pra doca não parecer flutuando
	draw_rect(Rect2(Vector2(RAFT_X + 40.0, raft_y + 9.0) * k, Vector2(5.0, 12.0) * k), plank_dark, true)


func _draw_character(k: float, state: Dictionary) -> void:
	var equipped: Dictionary = state["cosmetics"]["equipped"]
	var raft_y := WATER_Y - 8.0
	var bob := sin(_time * 8.0) * 1.6 if fishing_phase == "reeling" else sin(_time * 1.3) * 1.0
	var char_y := raft_y + 2.0 - 20.0 * CHAR_SCALE + bob

	# sombrinha no piso da doca, pra personagem não parecer flutuando
	draw_rect(
		Rect2(Vector2(CHAR_X + 4.0 * CHAR_SCALE, raft_y + 1.0) * k, Vector2(8.0 * CHAR_SCALE, 2.0) * k),
		Color(0, 0, 0, 0.28), true
	)

	PixelSprites.draw_chibi(self, Vector2(CHAR_X, char_y) * k, CHAR_SCALE * k, {
		"skin": Color("#f2d5ab"),
		"hair": Color("#5b3a24"),
		"outfit": CosmeticsData.color_of(equipped.get("outfit", "outfit_base")),
		"boot": Color("#2a1c10"),
		"accessory": CosmeticsData.color_of(equipped.get("accessory", "acc_none")),
		"hat": CosmeticsData.color_of(equipped.get("hat", "hat_none")),
		"rod": true,
	})


func _rod_tip() -> Vector2:
	var raft_y := WATER_Y - 8.0
	var char_y := raft_y + 2.0 - 20.0 * CHAR_SCALE
	return Vector2(CHAR_X, char_y) + PixelSprites.ROD_TIP_UNIT * CHAR_SCALE


# Fora da pescaria a linha é recolhida: a vara fica na mão, mas nada de anzol
# largado no lago. Serve também de leitura de estado — linha na água quer dizer
# que tem pescaria acontecendo.
func _draw_line_and_bobber(k: float) -> void:
	if fishing_phase == "idle":
		return

	var tip := _rod_tip()
	var wobble := 1.4
	match fishing_phase:
		"waiting": wobble = 2.2
		"reeling": wobble = 3.2
	var bobber := Vector2(tip.x + 120.0, WATER_Y + 4.0 + sin(_time * 5.0) * wobble)

	# Recolhendo: a boia desliza de volta pra ponta da vara, saindo da água no
	# caminho. É o fecho de quando se cancela o lançamento ou o peixe escapa —
	# antes o anzol simplesmente sumia.
	var retrieving := fishing_phase == "recolhendo"
	var t_retrieve := 0.0
	if retrieving:
		t_retrieve = ease(clampf(retrieve_progress, 0.0, 1.0), 0.45)
		bobber = bobber.lerp(tip, t_retrieve)

	# a linha faz uma barriga: reta demais fica sem peso. Ela se estica junto
	# com a recolhida, então a barriga vai sumindo.
	var sag := 10.0 * (1.0 - t_retrieve)
	var mid := (tip + bobber) * 0.5 + Vector2(0, sag)
	var points := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		var p := tip.lerp(mid, t).lerp(mid.lerp(bobber, t), t)
		points.append(p * k)
	draw_polyline(points, Color(0.98, 0.94, 0.85, 0.6), maxf(1.0, 1.1 * k))

	# ondinhas em volta da boia — só enquanto ela está mesmo n'água
	if bobber.y > WATER_Y:
		var ring := Color(1, 1, 1, (0.18 if fishing_phase == "waiting" else 0.10) * (1.0 - t_retrieve))
		draw_rect(Rect2(Vector2(bobber.x - 11.0, WATER_Y + 6.0) * k, Vector2(22.0, 1.5) * k), ring, true)

	PixelSprites.draw_bobber(self, bobber * k, 4.0 * k)


# Um halo curto na lanterna, só de noite. O brilho anterior era um disco
# enorme que virava uma mancha pálida por cima de tudo.
func _draw_lamp_glow(k: float, night: float) -> void:
	if night <= 0.3:
		return
	var raft_y := WATER_Y - 8.0
	var center := Vector2(RAFT_X + 27.5, raft_y - 37.0) * k
	for i in range(3, 0, -1):
		draw_circle(center, 6.0 * float(i) * k, Color(1.0, 0.84, 0.55, 0.045 * night))
