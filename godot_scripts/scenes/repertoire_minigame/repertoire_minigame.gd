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

var _current_signal: SignalData
var _current_syllable_index: int = 0
var _current_note_index: int = 0
var _is_active: bool = false

func _ready() -> void:
	set_process_unhandled_key_input(false)

## Inicializa o estado lógico da validação para a ave atual
func open(signal_data: SignalData) -> void:
	if not signal_data:
		return
	_current_signal = signal_data
	_current_syllable_index = 0
	_current_note_index = 0
	_is_active = true
	
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
		return
	
	if _current_syllable_index >= _current_signal.syllables.size():
		return
		
	var current_syllable: SyllableData = _current_signal.syllables[_current_syllable_index]
	
	# Validação de progressão: Se o especialista não coletou áudios suficientes para liberar a sílaba
	if "is_unlocked" in current_syllable and not current_syllable.is_unlocked:
		print("[Repertoire] Tentativa de input em Sílaba Bloqueada.")
		return
	
	var expected_pitch = current_syllable.frequency_sequence[_current_note_index]
	
	if freq_index == expected_pitch:
		_current_note_index += 1
		
		if _current_note_index >= current_syllable.frequency_sequence.size():
			_advance_syllable()
	else:
		# Errou a nota da sequência: Reseta a sílaba atual para o começo
		_current_note_index = 0

## Controla os índices de avanço do minigame e travas de áudio corrompido
func _advance_syllable() -> void:
	_current_note_index = 0
	_current_syllable_index += 1
	
	if _current_syllable_index < _current_signal.syllables.size():
		var next_syllable = _current_signal.syllables[_current_syllable_index]
		
		# Se a próxima sílaba exigir um encontro maior do que o jogador possui
		if "is_unlocked" in next_syllable and not next_syllable.is_unlocked:
			_is_active = false
			minigame_cancelled.emit()
			close()
			return
	else:
		# Completou todas as sílabas com sucesso
		set_process_unhandled_key_input(false)
		
		if has_node("/root/SignalBook"):
			get_node("/root/SignalBook").learn_signal(_current_signal)
			
		minigame_completed.emit(_current_signal)
		close()
