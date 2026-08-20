# audio.gd — autoload "Audio": os sons do jogo, sintetizados em código.
#
# Mesma regra da arte: nenhum arquivo externo. Os efeitos são ondas curtas
# geradas na hora e a "música" é uma ambiência de mar (ruído filtrado com uma
# maré lenta por cima), tudo montado em AudioStreamWAV na inicialização.
#
# Dois barramentos, "Efeitos" e "Musica", pra cada slider das configurações
# mexer no seu — é por isso que eles existem: sem som, os controles de volume
# seriam só enfeite.

extends Node

const MIX_RATE := 22050
const SFX_BUS := "Efeitos"
const MUSIC_BUS := "Musica"

var _sfx: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _music_player: AudioStreamPlayer


func _ready() -> void:
	_ensure_buses()
	_build_sounds()
	_build_players()


func _exit_tree() -> void:
	shutdown()


# Silencia e solta os streams. Chamado no caminho real de saída (menu ou fechar
# a janela) e no _exit_tree como rede: uma reprodução viva no encerramento faz
# o Godot acusar instância vazada.
func shutdown() -> void:
	for player in _sfx_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	if is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.stream = null
	_sfx.clear()


# --- barramentos ---
func _ensure_buses() -> void:
	for bus_name in [SFX_BUS, MUSIC_BUS]:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		var index := AudioServer.bus_count
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")


# volume em 0..100
func set_bus_percent(bus_name: String, percent: int) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	var value := clampi(percent, 0, 100)
	AudioServer.set_bus_mute(index, value <= 0)
	# Curva quadrática: o meio do slider soa como "metade" pro ouvido, o que
	# uma escala linear em dB não dá.
	AudioServer.set_bus_volume_db(index, linear_to_db(pow(float(value) / 100.0, 2.0)))


func apply_settings(settings: Dictionary) -> void:
	set_bus_percent(SFX_BUS, int(settings.get("sfx", 70)))
	set_bus_percent(MUSIC_BUS, int(settings.get("music", 40)))


# --- tocar ---
func play(sound_name: String) -> void:
	if not _sfx.has(sound_name) or _sfx_players.is_empty():
		return
	# Rodízio de players: dois sons juntos não se cortam.
	var player := _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	player.stream = _sfx[sound_name]
	player.play()


func _replay_music() -> void:
	if is_instance_valid(_music_player) and _music_player.stream != null:
		_music_player.play()


func _build_players() -> void:
	for i in 4:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_sfx_players.append(player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	# Reinício pelo sinal `finished` em vez de loop_mode no WAV: o laço interno
	# mantinha uma reprodução viva no encerramento e o Godot acusava vazamento.
	_music_player.stream = _make_ambience()
	_music_player.finished.connect(_replay_music)
	add_child(_music_player)
	_music_player.play()


# --- síntese ---
func _build_sounds() -> void:
	_sfx["cast"] = _make_wav(_tone_sweep(240.0, 90.0, 0.16, 0.5))       # a isca batendo n'água
	_sfx["bite"] = _make_wav(_blips([660.0, 880.0], 0.05))              # fisgou
	_sfx["catch"] = _make_wav(_blips([523.0, 659.0, 784.0], 0.07))      # peixe no bolso
	_sfx["rank"] = _make_wav(_blips([523.0, 659.0, 784.0, 1046.0], 0.08))
	_sfx["coin"] = _make_wav(_blips([880.0, 1174.0], 0.05))
	_sfx["escape"] = _make_wav(_tone_sweep(400.0, 150.0, 0.22, 0.35))
	_sfx["click"] = _make_wav(_tone_sweep(520.0, 480.0, 0.04, 0.25))
	_sfx["reel"] = _make_wav(_tone_sweep(150.0, 260.0, 0.20, 0.28))   # molinete recolhendo


func _make_wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav


# Um tom que escorrega de uma frequência pra outra e apaga — serve de "plop".
func _tone_sweep(from_hz: float, to_hz: float, seconds: float, gain: float) -> PackedFloat32Array:
	var count := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase := 0.0
	for i in count:
		var t := float(i) / float(count)
		var hz := lerpf(from_hz, to_hz, t)
		phase += TAU * hz / float(MIX_RATE)
		var envelope := pow(1.0 - t, 2.2)
		out[i] = sin(phase) * envelope * gain
	return out


# Notinhas curtas em sequência: usado nas comemorações.
func _blips(notes: Array, note_seconds: float) -> PackedFloat32Array:
	var per := int(note_seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(per * notes.size())
	for n in notes.size():
		var phase := 0.0
		for i in per:
			var t := float(i) / float(per)
			phase += TAU * float(notes[n]) / float(MIX_RATE)
			# triangular suave, mais "fofa" que a senoide pura
			var wave := sin(phase) * 0.7 + sin(phase * 2.0) * 0.15
			out[n * per + i] = wave * pow(1.0 - t, 1.8) * 0.32
	return out


# Ambiência: ruído passa-baixa com uma maré lenta modulando o volume. As bordas
# são cruzadas pra emendar sem estalo no ponto do laço.
func _make_ambience() -> AudioStreamWAV:
	var seconds := 6.0
	var count := int(seconds * MIX_RATE)
	var fade := int(0.25 * MIX_RATE)

	var raw := PackedFloat32Array()
	raw.resize(count + fade)
	var low := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 20240819
	for i in raw.size():
		low = lerpf(low, rng.randf_range(-1.0, 1.0), 0.045)  # passa-baixa de 1 polo
		var t := float(i) / float(MIX_RATE)
		var tide := 0.55 + 0.45 * sin(TAU * t / 6.0)         # a maré indo e voltando
		raw[i] = low * tide * 0.5

	var out := PackedFloat32Array()
	out.resize(count)
	for i in count:
		out[i] = raw[i]
	for i in fade:
		var t := float(i) / float(fade)
		out[i] = lerpf(raw[count + i], raw[i], t)

	return _make_wav(out)
