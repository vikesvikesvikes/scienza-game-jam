class_name RepertoireMinigame
extends Node

# Sinais de comunicação de estado com o ecossistema do jogo
signal minigame_completed(signal_data: SignalData)
signal minigame_cancelled

# Mapeamento estrito de input de teclado se preferir tratar direto na lógica
const PITCH_INDEXES = {
	KEY_1: 0, # Grave
	KEY_2: 1, # Neutro
	KEY_3: 2  # Agudo
}
var _pending_syllables: Array[SyllableData] = []
var _current_signal: SignalData
var _current_syllable_index: int = 0
var _current_note_index: int = 0
var _is_active: bool = false

func _ready() -> void:
	set_process_unhandled_key_input(false)

## Inicializa o estado lógico da validação para a ave atual
func open(signal_data: SignalData) -> void:
	if not signal_data:
		print("[Repertoire] Erro: Tentativa de abrir minigame sem SignalData válido.")
		return
		
	print("[Repertoire] Minigame aberto. Ave carregada. Total de Sílabas: ", signal_data.syllables.size())
	_current_signal = signal_data
	_current_syllable_index = 0
	_current_note_index = 0
	_is_active = true
	_pending_syllables = []
	for s in _current_signal.syllables:
		if s.is_unlocked:
			_pending_syllables.append(s)
			
	_current_note_index = 0
	set_process_unhandled_key_input(true)

## Reseta o estado lógico do jogo e desativa processamento
func close() -> void:
	_is_active = false
	set_process_unhandled_key_input(false)
	_current_signal = null

func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_active:
		return
		
	if event.is_action_pressed("ui_cancel"):
		minigame_cancelled.emit()
		close()
		return

	# Captura direta via teclado quando não estiver usando a rota do Menu Radial externo
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode in PITCH_INDEXES:
			var target_pitch: int = PITCH_INDEXES[event.keycode]
			_on_frequency_pressed(target_pitch)
			get_viewport().set_input_as_handled()

## Ponto de entrada público para o Menu Radial ou botões externos injetarem o pitch
func receive_radial_input(freq_index: int) -> void:
	if not _is_active:
		return
	_on_frequency_pressed(freq_index)

## Processa a validação matemática/lógica da nota inserida
func _on_frequency_pressed(freq_index: int) -> void:
	if not _is_active or not _current_signal:
		print("[Repertoire] Input ignorado: Minigame inativo ou sem ave atual.")
		return
	
	if _current_syllable_index >= _current_signal.syllables.size():
		return
		
	var current_syllable: SyllableData = _current_signal.syllables[_current_syllable_index]
	
	if "is_unlocked" in current_syllable and not current_syllable.is_unlocked:
		print("[Repertoire] Tentativa de input em Sílaba Bloqueada.")
		return
	
	var expected_pitch = current_syllable.frequency_sequence[_current_note_index]
	print("[Repertoire] Input Recebido: ", freq_index, " | Esperado: ", expected_pitch)
	
	if freq_index == expected_pitch:
		print("[Repertoire] Nota CORRETA!")
		_current_note_index += 1
		
		if _current_note_index >= current_syllable.frequency_sequence.size():
			_advance_syllable()
	else:
		print("[Repertoire] Nota ERRADA! Resetando progresso desta sílaba.")
		_current_note_index = 0

## Controla os índices de avanço do minigame e travas de áudio corrompido
func _advance_syllable() -> void:
	print("[Repertoire] Sílaba finalizada com sucesso! Avançando...")
	_current_note_index = 0
	_current_syllable_index += 1
	
	if _current_syllable_index < _current_signal.syllables.size():
		var next_syllable = _current_signal.syllables[_current_syllable_index]
		
		if "is_unlocked" in next_syllable and not next_syllable.is_unlocked:
			print("[Repertoire] Próxima sílaba bloqueada. Encerrando minigame prematuramente.")
			_is_active = false
			minigame_cancelled.emit()
			close()
			return
	else:
		print("[Repertoire] Todas as sílabas validadas! Minigame Concluído.")
		set_process_unhandled_key_input(false)
		
		if has_node("/root/SignalBook"):
			get_node("/root/SignalBook").learn_signal(_current_signal)
			
		minigame_completed.emit(_current_signal)
		close()
