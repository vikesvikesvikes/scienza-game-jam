extends Node2D
class_name BirdHint

## Tempo que cada cor fica sendo revelada
@export var color_reveal_time: float = 0.5
## Tempo que a sequência completa fica visível antes de sumir
@export var hold_time_after_complete: float = 1.0
## Pausa (balão escondido) antes de repetir
@export var pause_between_loops: float = 2.0

@export var target_syllable_index: int = 0
## Cores correspondentes às frequências: 0 = Grave, 1 = Neutro, 2 = Agudo
const SLOT_COLORS = [
	Color(0, 0, 1),   # Grave (Ciano)
	Color(0, 1, 0),   # Neutro (Verde)
	Color(1.0, 0, 0),  # Agudo (Amarelo)
]
const COLOR_OFF := Color(0.2, 0.2, 0.2)

@onready var speech_bubble: Control = $SpeechBubble
@onready var color_slots: Array[ColorRect] = [
	$SpeechBubble/ColorSlots/ColorSlot1,
	$SpeechBubble/ColorSlots/ColorSlot2,
	$SpeechBubble/ColorSlots/ColorSlot3,
	$SpeechBubble/ColorSlots/ColorSlot4,
]

var _player_inside := false
var _is_playing := false
var _current_signal: SignalData

func _ready() -> void:
	speech_bubble.visible = false
	_reset_slots()

	var sweet_spot := get_parent()
	if sweet_spot is SweetSpot:
		sweet_spot.player_entered_sweetspot.connect(_on_player_entered)
		sweet_spot.player_exited_sweetspot.connect(stop_hint)

func _on_player_entered(emitter: RadioEmitter) -> void:
	if emitter and emitter.signal_data:
		_current_signal = emitter.signal_data
	start_hint()

func start_hint() -> void:
	_player_inside = true
	if not _is_playing:
		_play_loop()

func stop_hint() -> void:
	_player_inside = false
	speech_bubble.visible = false
	_current_signal = null

func _play_loop() -> void:
	_is_playing = true
	while _player_inside:
		# 1. Valida se o emissor injetou o recurso corretamente
		if not _current_signal or _current_signal.syllables.is_empty():
			await get_tree().create_timer(0.5).timeout
			continue
			
		# 2. Usa o target_syllable_index exportado para focar na sílaba deste nó
		var safe_index = clamp(target_syllable_index, 0, _current_signal.syllables.size() - 1)
		var syllable: SyllableData = _current_signal.syllables[safe_index]
		var sequence: Array = syllable.frequency_sequence
		
		# (Opcional) Se quiser que a dica não apareça para sílabas vazias:
		if sequence.is_empty():
			speech_bubble.visible = false
			await get_tree().create_timer(1.0).timeout
			continue

		speech_bubble.visible = true
		_reset_slots()

		# 3. Liga e desliga os slots com base no tamanho da sequência real da sílaba
		for i in color_slots.size():
			if i >= sequence.size():
				color_slots[i].visible = false
			else:
				color_slots[i].visible = true

		# 4. Exibe as cores da dica ignorando a trava de is_unlocked para guiar o jogador
		for i in sequence.size():
			if not _player_inside:
				break
			var pitch_value: int = sequence[i]
			if pitch_value < SLOT_COLORS.size():
				color_slots[i].color = SLOT_COLORS[pitch_value]
			await get_tree().create_timer(color_reveal_time).timeout

		if _player_inside:
			await get_tree().create_timer(hold_time_after_complete).timeout

		speech_bubble.visible = false

		if _player_inside:
			await get_tree().create_timer(pause_between_loops).timeout

	_is_playing = false

func _reset_slots() -> void:
	for slot in color_slots:
		slot.color = COLOR_OFF
