# game_state.gd — autoload "GameState": guarda a partida em andamento.
#
# Fica de propósito só com o que é de instância: o dicionário do jogo e o
# salvar. A forma do save (defaults, validação da leitura, mexer no inventário)
# mora em `StateFormat`, que é estático — misturar as duas coisas num autoload
# era o que fazia o Godot avisar sobre chamada estática por instância.

extends Node

var state: Dictionary = {}


func _ready() -> void:
	randomize()
	state = StateFormat.merge_with_defaults(SaveSystem.load_state())


func save_now() -> void:
	if state.is_empty():
		return
	state["lastSeen"] = StateFormat.now_ms()
	SaveSystem.save_state(state)
