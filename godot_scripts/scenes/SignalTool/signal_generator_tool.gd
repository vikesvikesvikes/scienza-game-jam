@tool
extends Node

## Arraste o arquivo de áudio (.ogg ou .wav) para cá no Inspector
@export var audio_file: AudioStream

## Clique aqui para ativar o processo de análise e geração do .tres
@export var generate_signal_resource: bool = false:
	set(value):
		if value and not Engine.is_editor_hint():
			return
		if value and audio_file:
			_start_analysis()

# Limites de frequência sugeridos para os 5 canais (em Hz)
# Muito Grave (1200-2400), Grave (2400-3600), Neutro (3600-4800), Agudo (4800-7000), Muito Agudo (7000-11000)
const F_LIMITS = [1200.0, 2400.0, 3600.0, 4800.0, 7000.0, 11000.0]
const WINDOW_DURATION = 0.25 # Analisa o áudio a cada 250ms (duração de cada nota)

var _player: AudioStreamPlayer
var _analyzer: AudioEffectSpectrumAnalyzerInstance
var _generated_sequence: Array[int] = []
var _timer: float = 0.0
var _bus_index: int

func _start_analysis() -> void:
	print("• Iniciando análise de: ", audio_file.resource_path)
	_generated_sequence.clear()
	_timer = 0.0
	
	# Configura um Bus de áudio temporário e em silêncio para não estourar no seu ouvido
	_bus_index = AudioServer.bus_count
	AudioServer.add_bus(_bus_index)
	AudioServer.set_bus_name(_bus_index, "SignalAnalysisBus")
	AudioServer.set_bus_volume_db(_bus_index, -80.0) # Silêncio
	
	# Adiciona o efeito de análise no Bus
	var effect = AudioEffectSpectrumAnalyzer.new()
	AudioServer.add_bus_effect(_bus_index, effect)
	
	# Cria o player de áudio dinamicamente
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.bus = "SignalAnalysisBus"
	_player.stream = audio_file
	
	# Pega a instância do analisador
	_analyzer = AudioServer.get_bus_effect_instance(_bus_index, 0)
	
	_player.play()
	set_process(true)

func _process(delta: float) -> void:
	# Evita rodar a validação se o player sequer foi instanciado
	if _player == null:
		set_process(false)
		return
		
	if not _player.playing:
		_finish_analysis()
		return
		
	_timer += delta
	if _timer >= WINDOW_DURATION:
		_timer = 0.0
		_capture_current_note()

func _capture_current_note() -> void:
	var magnitudes: Array[float] = []
	
	# Passa pelas 5 faixas de frequência baseadas nos botões do minigame
	for i in range(5):
		var mag = _analyzer.get_magnitude_for_frequency_range(F_LIMITS[i], F_LIMITS[i+1]).length()
		magnitudes.append(mag)
		
	# Encontra qual das 5 faixas estava mais forte neste milissegundo
	var strongest_idx = magnitudes.find(magnitudes.max())
	
	# Opcional: Ignora trechos de silêncio absoluto para não gerar notas falsas
	if magnitudes[strongest_idx] > 0.025:
		if _generated_sequence.is_empty() or _generated_sequence[-1] != strongest_idx:
			_generated_sequence.append(strongest_idx)

func _finish_analysis() -> void:
	set_process(false)
	
	# Garante que só vai interagir com o player se ele existir de fato
	if _player:
		_player.stop()
		_player.queue_free()
		_player = null
		
	if _bus_index < AudioServer.bus_count:
		AudioServer.remove_bus(_bus_index)
	
	if _generated_sequence.is_empty():
		print("✗ Falha: Nenhuma frequência relevante foi detectada no áudio.")
		return
		
	_save_signal_resource()

func _save_signal_resource() -> void:
	var file_path = audio_file.resource_path
	var file_name = file_path.get_file().get_basename()
	
	var signal_data = load("res://godot_scripts/resources/signal_data.gd").new()
	signal_data.signal_id = file_name
	signal_data.display_name = file_name.capitalize()
	signal_data.bird_audio = audio_file
	
	var syllable_script = load("res://godot_scripts/resources/syllable_data.gd")
	var syllable = syllable_script.new()
	syllable.label = "A"
	
	# Converte explicitamente a sequência gerada para o tipo de array esperado pelo enum Pitch
	var typed_sequence: Array[int] = []
	for note in _generated_sequence:
		typed_sequence.append(note)
	syllable.frequency_sequence = typed_sequence
	
	# CRUCIAL: Forçamos a criação de uma Array sem tipo estrito inicial 
	# e depois fazemos o assign usando o próprio tipo do script para compatibilidade.
	var typed_syllables: Array[SyllableData] = []
	typed_syllables.append(syllable)
	
	signal_data.syllables = typed_syllables
	
	var save_path = "res://godot_scripts/resources/" + file_name + ".tres"
	var error = ResourceSaver.save(signal_data, save_path)
	
	if error == OK:
		print("✓ Sucesso! Recurso gerado em: ", save_path)
	else:
		print("✗ Erro ao salvar o Resource. Código: ", error)
