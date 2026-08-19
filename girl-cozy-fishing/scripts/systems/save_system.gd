# save_system.gd — autoload "SaveSystem": leitura e escrita do progresso em
# user://mare-save.json.
#
# A escrita é feita em etapas pra nunca deixar o jogador sem save: grava num
# .tmp, promove o save atual a .bak, coloca o .tmp no lugar e só então descarta
# o .bak. Um desligamento no meio de qualquer etapa deixa pelo menos um arquivo
# íntegro em disco — o carregamento sabe procurar pelo .bak.

extends Node

const SAVE_PATH := "user://mare-save.json"
const TMP_PATH := "user://mare-save.json.tmp"
const BAK_PATH := "user://mare-save.json.bak"
const CORRUPT_PATH := "user://mare-save.json.corrupt"
const MAX_SAVE_BYTES := 2 * 1024 * 1024  # save legítimo tem alguns KB


func save_state(state: Dictionary) -> bool:
	var json := JSON.stringify(state)
	if json.is_empty() or json.length() > MAX_SAVE_BYTES:
		push_warning("[mare] save inválido ou grande demais; nada foi gravado")
		return false

	var tmp := FileAccess.open(TMP_PATH, FileAccess.WRITE)
	if tmp == null:
		push_warning("[mare] não consegui abrir o arquivo temporário de save: %s" % FileAccess.get_open_error())
		return false
	tmp.store_string(json)
	tmp.close()

	var dir := DirAccess.open("user://")
	if dir == null:
		return false

	if dir.file_exists(SAVE_PATH.get_file()):
		if dir.file_exists(BAK_PATH.get_file()):
			dir.remove(BAK_PATH.get_file())
		dir.rename(SAVE_PATH.get_file(), BAK_PATH.get_file())

	var err := dir.rename(TMP_PATH.get_file(), SAVE_PATH.get_file())
	if err != OK:
		# Deu errado na troca: devolve o backup pro lugar antes de desistir.
		if dir.file_exists(BAK_PATH.get_file()):
			dir.rename(BAK_PATH.get_file(), SAVE_PATH.get_file())
		push_warning("[mare] falha ao gravar o save: %s" % err)
		return false

	if dir.file_exists(BAK_PATH.get_file()):
		dir.remove(BAK_PATH.get_file())
	return true


func load_state() -> Dictionary:
	var data := _read_json(SAVE_PATH)
	if not data.is_empty():
		return data

	# Save principal ilegível ou ausente: tenta o backup da última troca.
	var backup := _read_json(BAK_PATH)
	if not backup.is_empty():
		push_warning("[mare] save principal indisponível; recuperado do backup")
		return backup

	return {}


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	if file.get_length() > MAX_SAVE_BYTES:
		file.close()
		push_warning("[mare] arquivo de save grande demais, ignorado: %s" % path)
		return {}
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		# Guarda uma cópia pro caso de dar pra recuperar à mão e segue o jogo
		# do zero, em vez de travar na abertura.
		_quarantine(path)
		push_warning("[mare] save ilegível movido para %s" % CORRUPT_PATH)
		return {}
	return parsed


func _quarantine(path: String) -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	if dir.file_exists(CORRUPT_PATH.get_file()):
		dir.remove(CORRUPT_PATH.get_file())
	dir.rename(path.get_file(), CORRUPT_PATH.get_file())


# Caminho real em disco, útil pra mostrar pro jogador onde está o progresso.
func save_location() -> String:
	return ProjectSettings.globalize_path(SAVE_PATH)
