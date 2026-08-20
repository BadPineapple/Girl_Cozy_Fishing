# screenshot.gd — sobe a interface de verdade, espera assentar e salva um PNG.
# Serve pra conferir layout e cor sem precisar ficar abrindo o jogo na mão.
#
#   Godot_v4.7.2-stable_win64_console.exe --path . tests/screenshot.tscn
#
# Precisa de janela de verdade (não roda em --headless, que não rasteriza).
# O PNG sai com fundo transparente, igual o widget é na tela.

extends Node

const SETTLE_SECONDS := 1.2


func _ready() -> void:
	var main: Node = preload("res://main.tscn").instantiate()
	add_child(main)

	await get_tree().create_timer(SETTLE_SECONDS).timeout

	# --panel=map abre um painel antes de capturar
	# --cast lança a isca; --retrieve lança e cancela, pra flagrar a recolhida
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--panel="):
			main.call("_open_panel", arg.trim_prefix("--panel="))
			# o painel entra com uma animação curta; espera ela terminar
			await get_tree().create_timer(0.4).timeout
		elif arg == "--esc":
			# Abre o mapa e manda um Esc de verdade pelo Input, pra conferir que
			# o atalho fecha o painel (teclado não dá pra testar em headless).
			main.call("_open_panel", "map")
			await get_tree().create_timer(0.4).timeout
			var before: bool = main.get("_panels")["map"]["root"].visible
			var key := InputEventKey.new()
			key.keycode = KEY_ESCAPE
			key.physical_keycode = KEY_ESCAPE
			key.pressed = true
			Input.parse_input_event(key)
			await get_tree().create_timer(0.4).timeout
			var after: bool = main.get("_panels")["map"]["root"].visible
			print("esc: mapa aberto antes=%s, depois=%s -> %s" % [before, after, "OK" if before and not after else "FALHOU"])
		elif arg == "--cast":
			main.call("_on_main_action")
			await get_tree().create_timer(1.2).timeout
		elif arg == "--retrieve":
			main.call("_on_main_action")   # lança
			await get_tree().create_timer(1.0).timeout
			main.call("_on_main_action")   # cancela
			await get_tree().create_timer(0.18).timeout
	await RenderingServer.frame_post_draw

	var image := get_viewport().get_texture().get_image()
	var suffix := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--panel="):
			suffix = "-" + arg.trim_prefix("--panel=")
		elif arg.begins_with("--"):
			suffix = "-" + arg.trim_prefix("--")
	var target := "user://shot%s.png" % suffix
	var err := image.save_png(target)
	if err == OK:
		print("captura salva em: %s" % ProjectSettings.globalize_path(target))
	else:
		printerr("falha ao salvar a captura: %s" % err)
	get_tree().quit()
