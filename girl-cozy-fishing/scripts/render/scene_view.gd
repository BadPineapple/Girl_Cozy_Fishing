# scene_view.gd — desenha só o que é "o mundo mesmo": a água, a jangada e a
# personagem. O céu foi removido de propósito — o topo fica transparente e quem
# aparece atrás é a própria área de trabalho.
#
# O ciclo dia/noite continua vivo pelo relógio do sistema, agora tingindo a água
# e acendendo um brilho quente na jangada.
#
# Tudo é desenhado num espaço lógico de 308x240 e escalado pra largura real do
# Control, então a proporção nunca é esticada (no widget original a cena era
# achatada em ~43% por causa de uma altura fixa no CSS).

extends Control

const BASE_W := 308.0
const BASE_H := 240.0
const CHAR_SCALE := 7.0
const WATER_Y := BASE_H * 0.62

var fishing_phase: String = "idle"

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func base_aspect_height(width: float) -> float:
	return width * BASE_H / BASE_W


func _night_factor() -> float:
	var t := Time.get_time_dict_from_system()
	var h := float(t["hour"]) + float(t["minute"]) / 60.0
	return (cos((h / 24.0) * TAU) + 1.0) / 2.0  # 0 = meio-dia, 1 = meia-noite


func _draw() -> void:
	var state: Dictionary = GameState.state
	if state.is_empty():
		return

	var k := size.x / BASE_W  # escala lógica -> pixels
	var night := _night_factor()
	var water := LocationsData.water_color(state["locationId"])

	# --- água ---
	# Faixas horizontais no lugar de um gradiente: mantém o look pixelado e a
	# borda de cima não vira um corte seco contra a área de trabalho.
	var water_top := water.lerp(Color("#02040a"), night * 0.55)
	var water_bottom := Color("#05141a").lerp(Color("#01030a"), night * 0.4)
	const BANDS := 12
	var band_h := (BASE_H - WATER_Y) / float(BANDS)
	for i in BANDS:
		var t := float(i) / float(BANDS - 1)
		var y := WATER_Y + band_h * float(i)
		draw_rect(
			Rect2(Vector2(0, y * k), Vector2(size.x, (band_h + 1.0) * k)),
			water_top.lerp(water_bottom, t),
			true
		)

	# --- ondulações ---
	var ripple := Color(1, 1, 1, 0.08 + 0.04 * sin(_time))
	for i in 3:
		var ly := WATER_Y + 16.0 + float(i) * 18.0 + sin(_time * 0.8 + float(i)) * 2.0
		var points := PackedVector2Array()
		var x := 0.0
		while x <= BASE_W:
			points.append(Vector2(x, ly + sin(_time * 1.4 + x * 0.08 + float(i)) * 2.5) * k)
			x += 12.0
		draw_polyline(points, ripple, maxf(1.0, k), false)

	# --- jangada/doca ---
	var raft_y := WATER_Y - 6.0
	var raft_x := BASE_W * 0.12
	var raft_w := BASE_W * 0.76
	draw_rect(Rect2(Vector2(raft_x, raft_y) * k, Vector2(raft_w, 12.0) * k), Color("#6b4a2f"), true)
	for i in 8:
		var plank_x := raft_x + float(i) * raft_w / 8.0
		draw_rect(Rect2(Vector2(plank_x, raft_y) * k, Vector2(2.0, 12.0) * k), Color("#4a331f"), true)

	# O vendedor não fica mais na jangada: ele atende no estabelecimento dele
	# (ver `venues` em data/locations_data.gd), que se visita pelo Mapa.

	# --- personagem ---
	var equipped: Dictionary = state["cosmetics"]["equipped"]
	var char_bob := sin(_time * 9.0) * 2.0 if fishing_phase == "reeling" else sin(_time * 1.4) * 1.6
	var char_x := BASE_W * 0.18
	var char_y := raft_y - 128.0 + char_bob

	PixelSprites.draw_chibi(self, Vector2(char_x, char_y) * k, CHAR_SCALE * k, {
		"skin": Color("#f2d5ab"),
		"hair": Color("#3a2718"),
		"outfit": CosmeticsData.color_of(equipped.get("outfit", "outfit_base")),
		"boot": Color("#2a1c10"),
		"accessory": CosmeticsData.color_of(equipped.get("accessory", "acc_none")),
		"hat": CosmeticsData.color_of(equipped.get("hat", "hat_none")),
	})

	# --- vara + boia, só quando não está ociosa ---
	if fishing_phase != "idle":
		var rod_tip := Vector2(char_x + CHAR_SCALE * 15.0, char_y + CHAR_SCALE * 10.0)
		var bobber_bob := sin(_time * 6.0) * 2.0 if fishing_phase == "waiting" else sin(_time * 2.0) * 1.5
		var bobber := Vector2(minf(BASE_W - 24.0, rod_tip.x + 46.0), WATER_Y + 10.0 + bobber_bob)
		draw_line(rod_tip * k, bobber * k, Color("#c9a35a"), maxf(1.0, 1.4 * k))
		PixelSprites.draw_bobber(self, bobber * k, 5.0 * k)

	# --- brilho quente da lamparina imaginária, à noite ---
	if night > 0.35:
		var glow_center := Vector2(char_x + 30.0, raft_y - 10.0) * k
		for i in range(6, 0, -1):
			var r := 15.0 * float(i) * k
			draw_circle(glow_center, r, Color(1.0, 0.77, 0.43, 0.03 * night))
