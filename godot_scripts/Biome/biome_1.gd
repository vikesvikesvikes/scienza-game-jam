extends Node2D

@onready var radial_menu: RadialMenuAdvanced = $HUD/RadialMenu
@onready var minigame: RepertoireMinigame = $HUD/RepertoireMinigame

func _ready() -> void:
	radial_menu.visible = false
	radial_menu.enabled = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"radial_open"):
		_open_radial()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_released(&"radial_open"):
		_close_radial()
		return

	if radial_menu.enabled:
		if event.is_action_pressed(&"radial_btn_a"):
			_choose_slot(0)
		elif event.is_action_pressed(&"radial_btn_x"):
			_choose_slot(1)
		elif event.is_action_pressed(&"radial_btn_y"):
			_choose_slot(2)

func _open_radial() -> void:
	radial_menu.visible = true
	radial_menu.enabled = true

func _close_radial() -> void:
	radial_menu.visible = false
	radial_menu.enabled = false

## Cada aperto de A/X/Y manda a nota na hora, sem fechar a radial,
## permitindo apertar vários botões em sequência (a ordem/sequência
## quem identifica é o próprio RepertoireMinigame).
func _choose_slot(index: int) -> void:
	radial_menu.set_temporary_selection(index)  # só efeito visual de destaque
	minigame.receive_radial_input(index)        # envia a nota imediatamente
