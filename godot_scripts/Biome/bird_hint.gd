extends Node2D
class_name BirdHint

## Sequência de 4 cores mostrada no balão (0 = A, 1 = X, 2 = Y — mesmos índices da radial)
@export var sequence: Array[int] = [0, 1, 2, 0]

## Tempo que cada cor fica sendo revelada
@export var color_reveal_time: float = 0.5
## Tempo que a sequência completa fica visível antes de sumir
@export var hold_time_after_complete: float = 1.0
## Pausa (balão escondido) antes de repetir
@export var pause_between_loops: float = 2.0

## Mesmas cores usadas na radial (A / X / Y)
const SLOT_COLORS = [
	Color.RED,
	Color.GREEN,
	Color.BLUE,
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

func _ready() -> void:
	speech_bubble.visible = false
	_reset_slots()

	# Se este nó estiver dentro de um SweetSpot, conecta automaticamente
	var sweet_spot := get_parent()
	if sweet_spot is SweetSpot:
		sweet_spot.player_entered_sweetspot.connect(func(_emitter): start_hint())
		sweet_spot.player_exited_sweetspot.connect(stop_hint)

## Chamar quando o player entrar na área (se não estiver usando SweetSpot como pai)
func start_hint() -> void:
	_player_inside = true
	if not _is_playing:
		_play_loop()

## Chamar quando o player sair da área
func stop_hint() -> void:
	_player_inside = false
	speech_bubble.visible = false

func _play_loop() -> void:
	_is_playing = true
	while _player_inside:
		speech_bubble.visible = true
		_reset_slots()

		for i in sequence.size():
			if not _player_inside:
				break
			var color_index: int = sequence[i]
			color_slots[i].color = SLOT_COLORS[color_index]
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
