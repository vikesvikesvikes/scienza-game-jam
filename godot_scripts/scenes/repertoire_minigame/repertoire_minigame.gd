class_name RepertoireMinigame
extends Control

const FREQ_KEYS: Array[Key] = [KEY_Q, KEY_W, KEY_E]

## Rótulos exibidos nos botões (tecla + altura)
const FREQ_LABELS: Array[String] = [
	"Q\nGrave",
	"W\nNeutro",
	"E\nAgudo",
]

## Cores dos 3 canais de frequência
const FREQ_COLORS: Array[Color] = [
	Color(0.4, 0.9, 0.8),   # Q — ciano       (Grave)
	Color(0.5, 1.0, 0.5),   # W — verde       (Neutro)
	Color(1.0, 0.75, 0.2),  # E — amarelo     (Agudo)
]

## Emitido ao concluir com sucesso
signal minigame_completed(signal_data: SignalData)
## Emitido ao fechar sem terminar
signal minigame_cancelled

@onready var bird_name_label: Label   = $Panel/TitleBar/BirdNameLabel
@onready var syllable_slots: HBoxContainer = $Panel/VBox/SyllableSlots
@onready var freq_buttons: HBoxContainer   = $Panel/VBox/FreqButtons
@onready var feedback_label: Label         = $Panel/VBox/FeedbackLabel
@onready var phrase_progress: Label        = $Panel/VBox/PhraseProgress

var _current_signal: SignalData
var _current_syllable_index: int = 0
var _current_note_index: int = 0
var _is_active: bool = false

func _ready() -> void:
	visible = false
	set_process_unhandled_key_input(false)

## Abre a interface do mini-game para o pássaro atual
func open(signal_data: SignalData) -> void:
	if not signal_data:
		return
	_current_signal = signal_data
	_current_syllable_index = 0
	_current_note_index = 0
	_is_active = true
	
	if bird_name_label:
		bird_name_label.text = _current_signal.display_name
		
	_build_syllable_ui()
	_build_frequency_buttons()
	_update_phrase_progress()
	_update_feedback("Digite a sequência de notas usando Q, W, E")
	
	visible = true
	set_process_unhandled_key_input(true)

## Fecha o mini-game limpando referências
func close() -> void:
	visible = false
	_is_active = false
	set_process_unhandled_key_input(false)
	_current_signal = null

func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_active or not event.is_pressed() or event.is_echo():
		return
		
	# Tecla ESC cancela/fecha o estudo
	if event.is_action_pressed("ui_cancel"):
		minigame_cancelled.emit()
		close()
		return
		
	# Verifica se apertou uma das teclas válidas do minigame (Q, W, E)
	for i in FREQ_KEYS.size():
		if event.keycode == FREQ_KEYS[i]:
			_on_frequency_pressed(i)
			get_viewport().set_input_as_handled()
			return

## Processa a entrada de uma nota/frequência
func _on_frequency_pressed(freq_index: int) -> void:
	if not _is_active or not _current_signal:
		return
		
	_animate_freq_button(freq_index)
	
	if _current_syllable_index >= _current_signal.syllables.size():
		return
		
	var current_syllable: SyllableData = _current_signal.syllables[_current_syllable_index]
	
	# SEGURANÇA: Se por algum motivo a sílaba estiver trancada
	if "is_unlocked" in current_syllable and not current_syllable.is_unlocked:
		_update_feedback("Sílaba bloqueada! Busque mais áudios da ave.")
		return
	
	var expected_pitch = current_syllable.frequency_sequence[_current_note_index]
	
	if freq_index == expected_pitch:
		# Acertou a nota!
		_current_note_index += 1
		_update_feedback("Nota correta!")
		
		if syllable_slots and syllable_slots.get_child_count() > _current_syllable_index:
			var slot = syllable_slots.get_child(_current_syllable_index)
			_flash_node(slot, Color.GREEN)
			
		if _current_note_index >= current_syllable.frequency_sequence.size():
			# Completou a sílaba inteira! Avança.
			_advance_syllable()
	else:
		# Errou a nota da sequência, reseta o progresso desta sílaba
		_current_note_index = 0
		_update_feedback("Incorreto! Recomeçando esta sílaba...")
		if syllable_slots and syllable_slots.get_child_count() > _current_syllable_index:
			var slot = syllable_slots.get_child(_current_syllable_index)
			_flash_node(slot, Color.RED)

func _advance_syllable() -> void:
	_current_note_index = 0
	_current_syllable_index += 1
	
	# Se ainda restam sílabas
	if _current_syllable_index < _current_signal.syllables.size():
		var next_syllable = _current_signal.syllables[_current_syllable_index]
		
		# VALIDAÇÃO DE BLOQUEIO: Se a próxima sílaba estiver trancada, barra!
		if "is_unlocked" in next_syllable and not next_syllable.is_unlocked:
			_update_feedback("Áudio com interferência... Encontre a ave em outro ponto!")
			_is_active = false
			
			await get_tree().create_timer(2.0).timeout
			minigame_cancelled.emit()
			close()
			return
			
		_update_phrase_progress()
	else:
		# Passou de todas as sílabas, vitória total!
		_update_feedback("Estudo concluído com sucesso!")
		set_process_unhandled_key_input(false)
		
		SignalBook.learn_signal(_current_signal)
		minigame_completed.emit(_current_signal)
		
		await get_tree().create_timer(1.5).timeout
		close()

# ── Construção Dinâmica da UI ────────────────────────────────────────────────

func _build_syllable_ui() -> void:
	if not syllable_slots:
		return
	for child in syllable_slots.get_children():
		child.queue_free()
		
	for syllable in _current_signal.syllables:
		var slot := Label.new()
		slot.theme_type_variation = "HeaderLarge"
		
		# Mostra a Letra se destravado, senão "?"
		if "is_unlocked" in syllable and syllable.is_unlocked:
			slot.text = " %s " % syllable.label
			slot.modulate = syllable.color
		else:
			slot.text = " ? "
			slot.modulate = Color.DARK_GRAY
			
		syllable_slots.add_child(slot)

func _build_frequency_buttons() -> void:
	if not freq_buttons:
		return
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

# ── Feedback visual / Tweens Corrigidos ──────────────────────────────────────

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
	# Corrigido aspas corrompidas para strings limpas
	tween.tween_property(btn, "scale", Vector2(1.25, 1.25), 0.06)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.06)

func _flash_node(node: Control, color: Color) -> void:
	if not node:
		return
	var orig_color := node.modulate
	var tween := create_tween()
	# Corrigido aspas corrompidas para strings limpas
	tween.tween_property(node, "modulate", color, 0.1)
	tween.tween_property(node, "modulate", orig_color, 0.1)
