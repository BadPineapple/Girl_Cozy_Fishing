# coin_icon.gd — os ícones de moeda desenhados, no lugar dos quadradinhos
# coloridos que existiam antes. Concha para a moeda comum, escama para a rara:
# a forma diferencia à distância, a cor sozinha não diferenciava.

class_name CoinIcon
extends Control

@export var kind: String = "conchas"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(11, 11)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	match kind:
		"escamas":
			PixelSprites.draw_scale_coin(self, center, radius)
		"sucata":
			PixelSprites.draw_scrap_coin(self, center, radius)
		_:
			PixelSprites.draw_shell_coin(self, center, radius)
