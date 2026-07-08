class_name RepertoireMinigame
extends Control

## ══════════════════════════════════════════════════════════════════════════════
## REPERTOIRE MINI-GAME
## Fluxo: Entrada (sonograma) → Processamento (player digita sílabas) → Saída (sinal aprendido)
##
## Como usar:
##   1. Coloque este Control num CanvasLayer (sempre por cima do jogo)
##   2. Chame open(signal_data) quando o player entrar no sweet spot
##   3. Escute o sinal "minigame_completed" para saber se aprendeu
## ══════════════════════════════════════════════════════════════════════════════

const FREQ_KEYS: Array[Key] = [KEY_Q, KEY_W, KEY_E,]

## Rótulos exibidos nos botões (tecla + altura)
const FREQ_LABELS: Array[String] = [
	"Q\nGrave",
	"W\nNeutro",
	"E\nAgudo",
]

## Cores dos 5 canais de frequência (Q=grave .. T=agudo)
const FREQ_COLORS: Array[Color] = [
	Color(0.4, 0.9, 0.8),   # Q — ciano       (Grave)
	Color(0.5, 1.0, 0.5),   # W — verde       (Neutro)
	Color(1.0, 0.75, 0.2),  # E — amarelo     (Agudo)
]

## Emitido ao concluir com sucesso
signal minigame_completed(signal_data: SignalData)

## Emitido ao fechar sem aprender (Esc)
signal minigame_cancelled

# ── Referências de UI ────────────────────────────────────────────────────────
@onready var sonogram_display: SonogramDisplay = $Panel/VBox/SonogramDisplay
@onready var freq_buttons: HBoxContainer       = $Panel/VBox/FreqButtons
@onready var feedback_label: Label             = $Panel/VBox/FeedbackLabel
@onready var bird_name_label: Label            = $Panel/TitleBar/BirdNameLabel
@onready var close_hint: Label                 = $Panel/TitleBar/CloseHint
@onready var phrase_progress: Label            = $Panel/VBox/PhraseProgress

# ── Estado interno ───────────────────────────────────────────────────────────
var _current_signal: SignalData = null
var _current_syllable_index: int = 0
var _current_note_index: int = 0
var _input_buffer: Array[int] = []
var _is_open: bool = false

# ── API pública ──────────────────────────────────────────────────────────────

func open(data: SignalData) -> void:
	_current_signal = data
	_current_syllable_index = 0
	_current_note_index = 0
	_input_buffer.clear()
	_is_open = true
	visible = true

	bird_name_label.text = data.display_name
	close_hint.text = "[Esc] Sair"

	sonogram_display.setup(data)
	_build_freq_buttons()
	_update_phrase_progress()
	_update_feedback("")

func close() -> void:
	_is_open = false
	visible = false
	_current_signal = null

# ── Input ────────────────────────────────────────────────────────────────────

func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_open or not event.pressed:
		return

	if event.keycode == KEY_ESCAPE:
		close()
		minigame_cancelled.emit()
		return

	var freq_index: int = FREQ_KEYS.find(event.keycode)
	if freq_index == -1:
		return

	_on_frequency_pressed(freq_index)

func _on_frequency_pressed(freq_index: int) -> void:
	if not _current_signal or _current_syllable_index >= _current_signal.syllables.size():
		return
	
	_animate_freq_button(freq_index)

	var syl: SyllableData = _current_signal.syllables[_current_syllable_index]
	var expected_note: int = syl.frequency_sequence[_current_note_index]
	var correct: bool = freq_index == expected_note

	# Atualiza o sonograma visualmente
	sonogram_display.mark_note(_current_syllable_index, _current_note_index, correct)

	if correct:
		_on_note_correct(syl)
	else:
		_on_note_wrong()

# ── Lógica de validação ──────────────────────────────────────────────────────

func _on_note_correct(syl: SyllableData) -> void:
	_current_note_index += 1

	if _current_note_index >= syl.frequency_sequence.size():
		# Sílaba completa
		_current_syllable_index += 1
		_current_note_index = 0
		_input_buffer.clear()

		if _current_syllable_index >= _current_signal.syllables.size():
			_on_phrase_completed()
			return

		_update_feedback("✓ Sílaba correta!")
	else:
		_update_feedback("✓ Nota correta, continue a sílaba…")

	sonogram_display.set_cursor(_current_syllable_index, _current_note_index)
	_update_phrase_progress()

func _on_note_wrong() -> void:
	_current_note_index = 0
	_input_buffer.clear()
	sonogram_display.set_cursor(_current_syllable_index, 0)
	_update_feedback("✗ Errou! Recomece a sílaba.")
	_shake_panel()

func _on_phrase_completed() -> void:
	_update_feedback("✓✓ Canto aprendido!")
	_update_phrase_progress()
	SignalBook.learn_signal(_current_signal)
	await get_tree().create_timer(1.5).timeout
	minigame_completed.emit(_current_signal)
	close()

# ── Construção de UI ─────────────────────────────────────────────────────────

func _build_freq_buttons() -> void:
	for child in freq_buttons.get_children():
		child.queue_free()

	for i in FREQ_KEYS.size():
		var btn := Button.new()
		btn.name = "Freq_%d" % i
		btn.text = FREQ_LABELS[i]
		btn.custom_minimum_size = Vector2(80, 64)
		btn.add_theme_color_override("font_color", FREQ_COLORS[i])
		btn.pressed.connect(_on_frequency_pressed.bind(i))
		freq_buttons.add_child(btn)

# ── Feedback visual ──────────────────────────────────────────────────────────

func _update_feedback(text: String) -> void:
	if feedback_label:
		feedback_label.text = text

func _update_phrase_progress() -> void:
	if not phrase_progress or not _current_signal:
		return
	var total := _current_signal.syllables.size()
	phrase_progress.text = "Sílaba %d / %d" % [
		min(_current_syllable_index + 1, total), total
	]

func _animate_freq_button(freq_index: int) -> void:
	if freq_buttons.get_child_count() <= freq_index:
		return
	var btn: Button = freq_buttons.get_child(freq_index)
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(1.25, 1.25), 0.06)
	tween.tween_property(btn, "scale", Vector2(1.00, 1.00), 0.10)

func _shake_panel() -> void:
	var panel: Control = $Panel
	if not panel:
		return
	var origin := panel.position
	var tween := create_tween()
	tween.tween_property(panel, "position", origin + Vector2(8, 0), 0.05)
	tween.tween_property(panel, "position", origin - Vector2(8, 0), 0.05)
	tween.tween_property(panel, "position", origin + Vector2(4, 0), 0.04)
	tween.tween_property(panel, "position", origin, 0.04)
