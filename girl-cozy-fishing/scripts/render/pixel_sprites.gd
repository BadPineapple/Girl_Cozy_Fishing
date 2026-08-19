# pixel_sprites.gd — desenha personagens "chibi" blocados num grid 16x20 (cada
# unidade vira um quadrado de `scale` pixels — dá o look pixel art sem depender
# de nenhum arquivo de imagem externo) e o ícone de peixe do bolso.

class_name PixelSprites
extends RefCounted

const TRANSPARENT := Color(0, 0, 0, 0)


static func _block(ci: CanvasItem, origin: Vector2, scale: float, ux: float, uy: float, uw: float, uh: float, color: Color) -> void:
	if color.a <= 0.0:
		return
	var pos := origin + Vector2(ux, uy) * scale
	ci.draw_rect(Rect2(pos, Vector2(uw, uh) * scale), color, true)


# opts: skin, hair, outfit, boot, accessory, hat (Color; alpha 0 = não desenha)
static func draw_chibi(ci: CanvasItem, origin: Vector2, scale: float, opts: Dictionary) -> void:
	var skin: Color = opts.get("skin", Color("#e8c9a0"))
	var hair: Color = opts.get("hair", Color("#4a2e1a"))
	var outfit: Color = opts.get("outfit", Color("#c97b52"))
	var boot: Color = opts.get("boot", Color("#3a2718"))
	var accessory: Color = opts.get("accessory", TRANSPARENT)
	var hat: Color = opts.get("hat", TRANSPARENT)
	var eye := Color("#2b2018")

	_block(ci, origin, scale, 4, 3, 8, 4, hair)     # massa de cabelo atrás da cabeça
	_block(ci, origin, scale, 5, 6, 6, 5, skin)     # rosto
	_block(ci, origin, scale, 4, 6, 1, 6, hair)     # mecha lateral esquerda
	_block(ci, origin, scale, 11, 6, 1, 6, hair)    # mecha lateral direita
	_block(ci, origin, scale, 6, 8, 1, 1, eye)      # olho esquerdo
	_block(ci, origin, scale, 9, 8, 1, 1, eye)      # olho direito
	_block(ci, origin, scale, 5, 11, 6, 7, outfit)  # torso/roupa
	_block(ci, origin, scale, 6, 17, 1, 2, boot)    # pé esquerdo
	_block(ci, origin, scale, 9, 17, 1, 2, boot)    # pé direito
	_block(ci, origin, scale, 4, 11, 8, 1, accessory)  # faixa/echarpe na gola
	_block(ci, origin, scale, 4, 1, 8, 2, hat)         # chapéu


static func draw_bobber(ci: CanvasItem, center: Vector2, radius: float) -> void:
	ci.draw_circle(center, radius, Color("#e8734a"))
	ci.draw_circle(center - Vector2(0, radius * 0.6), radius * 0.6, Color("#f2e9e4"))


# Ícone de peixe pro bolso — vetorial mesmo: fica pequeno demais pra valer a
# pena "pixelar".
static func draw_fish_icon(ci: CanvasItem, origin: Vector2, size: float, palette: Array) -> void:
	var light := Color(palette[0])
	var mid := Color(palette[1])
	var dark := Color(palette[2])

	# corpo
	_draw_ellipse(ci, origin + Vector2(size * 0.45, size * 0.5), Vector2(size * 0.42, size * 0.28), mid)
	# barriga clara
	_draw_ellipse(ci, origin + Vector2(size * 0.45, size * 0.62), Vector2(size * 0.30, size * 0.14), light)
	# cauda
	var tail := PackedVector2Array([
		origin + Vector2(size * 0.10, size * 0.50),
		origin + Vector2(size * 0.00, size * 0.30),
		origin + Vector2(size * 0.00, size * 0.70),
	])
	ci.draw_colored_polygon(tail, dark)
	# olho
	ci.draw_circle(origin + Vector2(size * 0.78, size * 0.46), maxf(1.0, size * 0.05), Color("#20180f"))


static func _draw_ellipse(ci: CanvasItem, center: Vector2, radii: Vector2, color: Color) -> void:
	const STEPS := 20
	var points := PackedVector2Array()
	for i in STEPS:
		var a := TAU * float(i) / float(STEPS)
		points.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	ci.draw_colored_polygon(points, color)
