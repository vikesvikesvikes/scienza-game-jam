extends CanvasLayer

@onready var main_panel: Control = $Root/MainPanel
@onready var controls_panel: Control = $Root/ControlsPanel
@onready var audio_panel: Control = $Root/AudioPanel
@onready var credits_panel: Control = $Root/CreditsPanel  # Adicione este nó na cena

@onready var resume_button: Button = $Root/MainPanel/ResumeButton
@onready var master_slider: HSlider = $Root/AudioPanel/MasterRow/MasterSlider
@onready var radio_slider: HSlider = $Root/AudioPanel/RadioRow/RadioSlider

var _master_bus: int
var _radio_bus: int

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_master_bus = AudioServer.get_bus_index("Master")
	_radio_bus = AudioServer.get_bus_index("Radio")

	$Root/MainPanel/ResumeButton.pressed.connect(_close)
	$Root/MainPanel/MapButton.pressed.connect(_on_map_pressed)
	$Root/MainPanel/ControlsButton.pressed.connect(_show_panel.bind(controls_panel))
	$Root/MainPanel/AudioButton.pressed.connect(_show_panel.bind(audio_panel))
	$Root/MainPanel/CreditsButton.pressed.connect(_show_panel.bind(credits_panel))  # Conecta o botão de créditos
	$Root/MainPanel/QuitButton.pressed.connect(_on_quit_pressed)
	$Root/ControlsPanel/BackButtonControls.pressed.connect(_show_panel.bind(main_panel))
	$Root/AudioPanel/BackButtonAudio.pressed.connect(_show_panel.bind(main_panel))
	$Root/CreditsPanel/BackButtonCredits.pressed.connect(_show_panel.bind(main_panel))  # Botão voltar dos créditos

	master_slider.min_value = -40
	master_slider.max_value = 0
	master_slider.value = AudioServer.get_bus_volume_db(_master_bus)
	master_slider.value_changed.connect(_on_master_changed)

	radio_slider.min_value = -40
	radio_slider.max_value = 0
	radio_slider.value = AudioServer.get_bus_volume_db(_radio_bus)
	radio_slider.value_changed.connect(_on_radio_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause_game"):
		if visible:
			_close()
		elif not _is_world_map():
			_open()
		get_viewport().set_input_as_handled()
		return

	if visible and event.is_action_pressed(&"ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
		return

	if visible and event.is_action_pressed(&"menu_confirm_key"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused is Button:
			focused.pressed.emit()
		get_viewport().set_input_as_handled()

## B (ou Esc) volta pro painel anterior; se já estiver no MainPanel, fecha o menu
func _on_back_pressed() -> void:
	if credits_panel.visible:
		_show_panel(main_panel)
	elif controls_panel.visible or audio_panel.visible:
		_show_panel(main_panel)
	else:
		_close()

func _open() -> void:
	visible = true
	_show_panel(main_panel)
	get_tree().paused = true

func _close() -> void:
	visible = false
	get_tree().paused = false

func _show_panel(panel: Control) -> void:
	main_panel.visible = panel == main_panel
	controls_panel.visible = panel == controls_panel
	audio_panel.visible = panel == audio_panel
	credits_panel.visible = panel == credits_panel
	_focus_first_control(panel)
	
## Joga o foco pro primeiro botão/slider clicável do painel que acabou de aparecer,
## assim Enter, E e o botão A do controle já têm o que confirmar de cara.
func _focus_first_control(panel: Control) -> void:
	for child in panel.get_children():
		if child is Control and child.focus_mode != Control.FOCUS_NONE:
			child.grab_focus()
			return

func _on_map_pressed() -> void:
	_close()
	GameManager.change_scene("res://godot_scripts/scenes/Brasil/Brasil.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_master_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_master_bus, value)

func _on_radio_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_radio_bus, value)
	
func _is_world_map() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path == "res://godot_scripts/scenes/Brasil/Brasil.tscn"
