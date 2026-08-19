# fish_icon.gd — Control pequenininho que desenha o ícone de um peixe.
# Usado na lista do Bolso, no lugar dos <canvas> que o widget criava por item.

class_name FishIcon
extends Control

@export var palette: Array = ["#ffffff", "#888888", "#333333"]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if palette.size() < 3:
		return
	PixelSprites.draw_fish_icon(self, Vector2.ZERO, minf(size.x, size.y), palette)
