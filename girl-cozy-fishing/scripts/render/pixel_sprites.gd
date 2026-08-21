# pixel_sprites.gd — a personagem "chibi" desenhada em blocos num grid 16x20
# (cada unidade vira um quadrado de `scale` pixels), mais os ícones pequenos.
#
# Direção de arte: o widget flutua sobre um papel de parede qualquer, então todo
# sprite é desenhado em duas passadas — primeiro um contorno escuro (cada bloco
# inflado em 1 unidade), depois as cores por cima. É o que faz a personagem ter
# recorte de adesivo e não sumir num fundo claro.

class_name PixelSprites
extends RefCounted

const TRANSPARENT := Color(0, 0, 0, 0)
const OUTLINE := Color(0.10, 0.07, 0.05, 0.9)
const EYE := Color("#2b2018")
const EYE_SHINE := Color("#fdf6ec")
const BLUSH := Color(0.91, 0.53, 0.47, 0.55)

# Onde fica a ponta da vara, em unidades do grid — a linha de pesca sai daqui.
const ROD_TIP_UNIT := Vector2(15.5, 6.0)


static func _rect(ci: CanvasItem, origin: Vector2, scale: float, b: Array, color: Color, grow := 0.0) -> void:
	if color.a <= 0.0:
		return
	var pos := origin + Vector2(float(b[0]) - grow, float(b[1]) - grow) * scale
	var size := Vector2(float(b[2]) + grow * 2.0, float(b[3]) + grow * 2.0) * scale
	ci.draw_rect(Rect2(pos, size), color, true)


# opts: skin, hair, outfit, boot, accessory, hat (Color; alpha 0 = não desenha),
#       rod (bool) — se a vara aparece na mão.
static func draw_chibi(ci: CanvasItem, origin: Vector2, scale: float, opts: Dictionary) -> void:
	var skin: Color = opts.get("skin", Color("#f2d5ab"))
	var hair: Color = opts.get("hair", Color("#4a2e1a"))
	var outfit: Color = opts.get("outfit", Color("#c97b52"))
	var boot: Color = opts.get("boot", Color("#3a2718"))
	var accessory: Color = opts.get("accessory", TRANSPARENT)
	var hat: Color = opts.get("hat", TRANSPARENT)

	var skin_shade := skin.darkened(0.18)
	var outfit_shade := outfit.darkened(0.22)
	var hair_shine := hair.lightened(0.18)

	# [x, y, largura, altura, cor] — ordem de desenho de trás pra frente.
	var blocks: Array = [
		[4, 2, 8, 7, hair],          # volume do cabelo atrás
		[7, 9, 2, 1, skin_shade],    # pescoço
		[5, 4, 6, 5, skin],          # rosto
		[4, 3, 8, 2, hair],          # franja
		[5, 3, 6, 1, hair_shine],    # brilho no topo da franja
		[4, 4, 1, 6, hair],          # mecha lateral esquerda
		[11, 4, 1, 6, hair],         # mecha lateral direita
		[5, 10, 6, 6, outfit],       # torso
		[4, 11, 1, 4, outfit],       # braço esquerdo
		[11, 11, 1, 3, outfit],      # braço direito (segura a vara)
		[4, 15, 1, 1, skin],         # mão esquerda
		[11, 14, 1, 1, skin],        # mão direita
		[5, 16, 6, 2, outfit_shade], # saia/quadril
		[5, 18, 2, 2, boot],         # bota esquerda
		[9, 18, 2, 2, boot],         # bota direita
	]

	if accessory.a > 0.0:
		blocks.append([4, 10, 8, 1, accessory])  # cachecol/gola
	if hat.a > 0.0:
		blocks.append([4, 1, 8, 2, hat])         # copa
		blocks.append([3, 3, 10, 1, hat.darkened(0.12)])  # aba

	# 1ª passada: contorno (cada bloco inflado meia unidade pra fechar as bordas)
	for b in blocks:
		_rect(ci, origin, scale, b, OUTLINE, 0.5)

	# 2ª passada: as cores
	for b in blocks:
		_rect(ci, origin, scale, b, b[4])

	# rosto: olhos grandes com brilho, e um rubor discreto
	_rect(ci, origin, scale, [6, 6, 1, 2], EYE)
	_rect(ci, origin, scale, [9, 6, 1, 2], EYE)
	_rect(ci, origin, scale, [6, 6, 1, 1], EYE_SHINE)
	_rect(ci, origin, scale, [9, 6, 1, 1], EYE_SHINE)
	_rect(ci, origin, scale, [5, 8, 1, 1], BLUSH)
	_rect(ci, origin, scale, [10, 8, 1, 1], BLUSH)

	# vara: sai da mão direita e aponta pra frente. Fica sempre visível — antes
	# a personagem ficava parada de mãos vazias enquanto não pescava.
	if opts.get("rod", true):
		var grip := origin + Vector2(11.5, 14.0) * scale
		var tip := origin + ROD_TIP_UNIT * scale
		ci.draw_line(grip, tip, OUTLINE, maxf(1.0, scale * 0.75))
		ci.draw_line(grip, tip, Color("#c9a35a"), maxf(1.0, scale * 0.38))


static func draw_bobber(ci: CanvasItem, center: Vector2, radius: float) -> void:
	ci.draw_circle(center, radius + maxf(1.0, radius * 0.3), OUTLINE)
	ci.draw_circle(center, radius, Color("#e8734a"))
	ci.draw_circle(center - Vector2(0, radius * 0.55), radius * 0.5, Color("#f2e9e4"))


# Ícone de peixe pro Bolso — vetorial mesmo: fica pequeno demais pra "pixelar".
static func draw_fish_icon(ci: CanvasItem, origin: Vector2, size: float, palette: Array) -> void:
	var light := Color(palette[0])
	var mid := Color(palette[1])
	var dark := Color(palette[2])

	var tail := PackedVector2Array([
		origin + Vector2(size * 0.10, size * 0.50),
		origin + Vector2(size * 0.00, size * 0.28),
		origin + Vector2(size * 0.00, size * 0.72),
	])
	ci.draw_colored_polygon(tail, dark)
	_ellipse(ci, origin + Vector2(size * 0.45, size * 0.5), Vector2(size * 0.42, size * 0.28), mid)
	_ellipse(ci, origin + Vector2(size * 0.45, size * 0.62), Vector2(size * 0.30, size * 0.14), light)
	ci.draw_circle(origin + Vector2(size * 0.78, size * 0.46), maxf(1.0, size * 0.05), Color("#20180f"))


# Conchas: a moeda principal. Uma concha com as estrias.
static func draw_shell_coin(ci: CanvasItem, center: Vector2, radius: float) -> void:
	var body := Color("#f2e3c9")
	var line := Color("#b08a5a")
	ci.draw_circle(center, radius, body)
	for i in 3:
		var a := PI * (0.25 + 0.25 * float(i))
		ci.draw_line(
			center + Vector2(cos(a), sin(a)) * radius * 0.15,
			center + Vector2(cos(a), sin(a)) * radius * 0.95,
			line, 1.0
		)


# Sucata: o que a tralha vira na Oficina. Uma porca sextavada.
static func draw_scrap_coin(ci: CanvasItem, center: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for i in 6:
		var a := TAU * float(i) / 6.0 + PI / 6.0
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	ci.draw_colored_polygon(points, Color("#b6a893"))
	ci.draw_circle(center, radius * 0.42, Color("#4a4038"))


# Escamas: a moeda rara. Um losango que brilha.
static func draw_scale_coin(ci: CanvasItem, center: Vector2, radius: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius * 0.8, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius * 0.8, 0),
	])
	ci.draw_colored_polygon(points, Color("#9fd8e8"))
	var shine := PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius * 0.35, -radius * 0.3),
		center + Vector2(0, 0),
		center + Vector2(-radius * 0.35, -radius * 0.3),
	])
	ci.draw_colored_polygon(shine, Color("#e6f7fb"))


static func _ellipse(ci: CanvasItem, center: Vector2, radii: Vector2, color: Color) -> void:
	const STEPS := 20
	var points := PackedVector2Array()
	for i in STEPS:
		var a := TAU * float(i) / float(STEPS)
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	ci.draw_colored_polygon(points, color)
