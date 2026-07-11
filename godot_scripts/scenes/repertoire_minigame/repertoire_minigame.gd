class_name RepertoireMinigame
extends Control

# Sinais necessários para a comunicação com o resto do jogo
signal minigame_completed(signal_data: SignalData)
signal minigame_cancelled

# Mapeamento dos botões numéricos para índices de pitch (0, 1, 2)
const PITCH_INDEXES = {
	KEY_1: 0, # Grave
	KEY_2: 1, # Neutro
	KEY_3: 2  # Agudo
}

@onready var radial_menu: Control          = $RadialMenu 
@onready var bird_name_label: Label        = $Panel/TitleBar/BirdNameLabel
@onready var syllable_slots: HBoxContainer = $Panel/VBox/SyllableSlots
@onready var feedback_label: Label         = $Panel/VBox/FeedbackLabel
@onready var phrase_progress: Label        = $Panel/VBox/PhraseProgress

var _current_signal: SignalData
var _current_syllable_index: int = 0
var _current_note_index: int = 0
var _is_active: bool = false

func _ready() -> void:
	visible = false
	if radial_menu:
		radial_menu.enabled = false 
		radial_menu.slot_selected.connect(_on_radial_slot_selected)
	set_process_unhandled_key_input(false)

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
	_update_phrase_progress()
	_update_feedback("Segure TAB para abrir o Menu Radial e use 1, 2, 3")
	
	visible = true
	set_process_unhandled_key_input(true)

func close() -> void:
	visible = false
	_is_active = false
	if radial_menu:
		radial_menu.enabled = false
	set_process_unhandled_key_input(false)
	_current_signal = null

func _unhandled_key_input(event: InputEvent) -> void:
	if not _is_active:
		return
		
	# Tecla ESC cancela o estudo
	if event.is_action_pressed("ui_cancel"):
		minigame_cancelled.emit()
		close()
		return
		
	# Gerenciamento do HOLD da tecla TAB para exibir o Menu Radial
	if event.is_action_pressed("ui_focus_next"): 
		if radial_menu and not radial_menu.enabled:
			radial_menu.enabled = true
			radial_menu.visible = true
			_update_feedback("Menu Radial Ativo. Escolha o Pitch!")
			get_viewport().set_input_as_handled()
			return
			
	if event.is_action_released("ui_focus_next"):
		if radial_menu and radial_menu.enabled:
			radial_menu.enabled = false
			radial_menu.visible = false
			get_viewport().set_input_as_handled()
			return

	# Se o menu radial não estiver ativo (Tab solto), ignora os inputs de nota
	if radial_menu and not radial_menu.enabled:
		return

	# Captura dos botões numéricos 1, 2 e 3 para validação direta de Pitch
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode in PITCH_INDEXES:
			var target_pitch: int = PITCH_INDEXES[event.keycode]
			
			if radial_menu and radial_menu.has_method("set_temporary_selection"):
				radial_menu.set_temporary_selection(target_pitch)
				
			_on_frequency_pressed(target_pitch)
			get_viewport().set_input_as_handled()

func _on_radial_slot_selected(_slot: Control, index: int) -> void:
	if _is_active and radial_menu and radial_menu.enabled:
		_on_frequency_pressed(index)
		
## Processa a entrada de uma nota/frequência e faz a validação lógica
func _on_frequency_pressed(freq_index: int) -> void:
	if not _is_active or not _current_signal:
		return
	
	if _current_syllable_index >= _current_signal.syllables.size():
		return
		
	var current_syllable: SyllableData = _current_signal.syllables[_current_syllable_index]
	
	# Segurança se a sílaba estiver trancada
	if "is_unlocked" in current_syllable and not current_syllable.is_unlocked:
		_update_feedback("Sílaba bloqueada! Busque mais áudios da ave.")
		return
	
	var expected_pitch = current_syllable.frequency_sequence[_current_note_index]
	
	if freq_index == expected_pitch:
		_current_note_index += 1
		_update_feedback("Nota correta!")
		
		if syllable_slots and syllable_slots.get_child_count() > _current_syllable_index:
			var slot = syllable_slots.get_child(_current_syllable_index)
			_flash_node(slot, Color.GREEN)
			
		if _current_note_index >= current_syllable.frequency_sequence.size():
			_advance_syllable()
	else:
		_current_note_index = 0
		_update_feedback("Incorreto! Recomeçando esta sílaba...")
		if syllable_slots and syllable_slots.get_child_count() > _current_syllable_index:
			var slot = syllable_slots.get_child(_current_syllable_index)
			_flash_node(slot, Color.RED)

## API pública para entradas vindas de outras fontes
func receive_radial_input(freq_index: int) -> void:
	if not _is_active:
		return
	_on_frequency_pressed(freq_index)

func _advance_syllable() -> void:
	_current_note_index = 0
	_current_syllable_index += 1
	
	if _current_syllable_index < _current_signal.syllables.size():
		var next_syllable = _current_signal.syllables[_current_syllable_index]
		
		if "is_unlocked" in next_syllable and not next_syllable.is_unlocked:
			_update_feedback("Áudio com interferência... Encontre a ave em outro ponto!")
			_is_active = false
			
			await get_tree().create_timer(2.0).timeout
			minigame_cancelled.emit()
			close()
			return
			
		_update_phrase_progress()
	else:
		_update_feedback("Estudo concluído com sucesso!")
		set_process_unhandled_key_input(false)
		
		if has_node("/root/SignalBook"):
			get_node("/root/SignalBook").learn_signal(_current_signal)
			
		minigame_completed.emit(_current_signal)
		
		await get_tree().create_timer(1.5).timeout
		close()

# ── Construção Dinâmica da UI de Sílabas ─────────────────────────────────────

func _build_syllable_ui() -> void:
	if not syllable_slots:
		return
	for child in syllable_slots.get_children():
		child.queue_free()
		
	for syllable in _current_signal.syllables:
		var slot := Label.new()
		slot.theme_type_variation = "HeaderLarge"
		
		if "is_unlocked" in syllable and syllable.is_unlocked:
			slot.text = " %s " % syllable.label
			slot.modulate = syllable.color
		else:
			slot.text = " ? "
			slot.modulate = Color.DARK_GRAY
			
		syllable_slots.add_child(slot)

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

func _flash_node(node: Control, color: Color) -> void:
	if not node:
		return
	var orig_color := node.modulate
	var tween := create_tween()
	tween.tween_property(node, "modulate", color, 0.1)
	tween.tween_property(node, "modulate", orig_color, 0.1)
