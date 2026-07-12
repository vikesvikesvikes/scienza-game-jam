class_name RepertoireMinigame
extends Node

@export var feedback_ui: FeedbackMessage

signal minigame_completed(signal_data: SignalData)
signal minigame_cancelled

const PITCH_INDEXES = {
	KEY_1: 0,
	KEY_2: 1,
	KEY_3: 2
}

var _current_signal: SignalData
var _is_active := false

# NOVO
var _input_sequence: Array[int] = []
var _completed_syllables: Dictionary = {}
var _active_target_index: int = -1

func _ready() -> void:
	set_process_unhandled_key_input(false)

func set_active_target(index: int) -> void:
	_active_target_index = index
	print("[Repertoire] Target ativo:", index)
	
func open(signal_data: SignalData) -> void:
	if !signal_data:
		print("[Repertoire] Erro ao abrir minigame.")
		return

	print("[Repertoire] Minigame aberto.")

	_current_signal = signal_data
	_is_active = true

	_input_sequence.clear()
	_completed_syllables.clear()

	set_process_unhandled_key_input(true)

func close() -> void:
	_is_active = false
	set_process_unhandled_key_input(false)

	_current_signal = null

	_input_sequence.clear()
	_completed_syllables.clear()

func _unhandled_key_input(event: InputEvent) -> void:
	if !_is_active:
		return

	if event.is_action_pressed("ui_cancel"):
		minigame_cancelled.emit()
		close()
		return

	if event is InputEventKey and event.is_pressed() and !event.is_echo():
		if event.keycode in PITCH_INDEXES:
			_on_frequency_pressed(PITCH_INDEXES[event.keycode])
			get_viewport().set_input_as_handled()

func receive_radial_input(freq_index:int) -> void:
	if !_is_active:
		return

	_on_frequency_pressed(freq_index)

func _on_frequency_pressed(freq_index:int) -> void:
	
	if !_is_active or !_current_signal:
		return
	print("Recebi:", freq_index)
	print_stack()
	_input_sequence.append(freq_index)

	print("[Repertoire] Buffer:", _input_sequence)

	if _input_sequence.size() == 3:
		if _active_target_index == -1:
			feedback_ui.show_wrong_sequence()
			_input_sequence.clear()
			return
		_validate_sequence(_active_target_index)
		_input_sequence.clear()


func _validate_sequence(target_index: int) -> void:
	if target_index < 0 or target_index >= _current_signal.syllables.size():
		if feedback_ui:
			feedback_ui.show_wrong_sequence()
		return

	var syllable: SyllableData = _current_signal.syllables[target_index]

	if "is_unlocked" in syllable and !syllable.is_unlocked:
		if feedback_ui:
			feedback_ui.show_wrong_sequence()
		return

	if syllable.frequency_sequence != _input_sequence:
		print("[Repertoire] Sequência incorreta.")
		if feedback_ui:
			feedback_ui.show_wrong_sequence()
		return

	if _completed_syllables.has(target_index):
		print("[Repertoire] Essa sílaba já foi concluída.")
		if feedback_ui:
			feedback_ui.show_wrong_sequence2()
		return

	print("[Repertoire] Sílaba", target_index, "concluída!")

	_completed_syllables[target_index] = true

	if feedback_ui:
		feedback_ui.show_correct_sequence()

	_check_completion()


func _check_completion() -> void:

	var total := 0

	for syllable in _current_signal.syllables:

		if "is_unlocked" in syllable and !syllable.is_unlocked:
			continue

		total += 1

	print("[Repertoire] %d/%d sílabas completas." % [_completed_syllables.size(), total])

	if _completed_syllables.size() < total:
		return

	print("[Repertoire] Todas as sílabas concluídas!")

	set_process_unhandled_key_input(false)

	if has_node("/root/SignalBook"):
		get_node("/root/SignalBook").learn_signal(_current_signal)

	minigame_completed.emit(_current_signal)
	close()
