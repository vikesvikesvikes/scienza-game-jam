class_name FeedbackMessage
extends CanvasLayer

## Tempo (em segundos) que a mensagem fica visível na tela antes de sumir sozinha
@export var display_time: float = 2.0

@onready var _panel: Panel = $Panel
@onready var _label: Label = $Panel/Label
@onready var _timer: Timer = $Timer

var _style_error: StyleBoxFlat
var _style_success: StyleBoxFlat

func _ready() -> void:
	visible = false

	_style_error = StyleBoxFlat.new()
	_style_error.bg_color = Color(0.55, 0.12, 0.12, 0.95)
	_style_error.corner_radius_top_left = 12
	_style_error.corner_radius_top_right = 12
	_style_error.corner_radius_bottom_left = 12
	_style_error.corner_radius_bottom_right = 12

	_style_success = StyleBoxFlat.new()
	_style_success.bg_color = Color(0.14, 0.5, 0.2, 0.95)
	_style_success.corner_radius_top_left = 12
	_style_success.corner_radius_top_right = 12
	_style_success.corner_radius_bottom_left = 12
	_style_success.corner_radius_bottom_right = 12

	_timer.wait_time = display_time
	_timer.one_shot = true
	_timer.timeout.connect(hide_message)

## Chame esta função quando o jogador errar a sequência
func show_wrong_sequence() -> void:
	_show("Sequência errada", _style_error)

func show_wrong_sequence2() -> void:
	_show("Sequência já coletada", _style_error)
## Chame esta função quando o jogador acertar a sequência
func show_correct_sequence() -> void:
	_show("Sequência certa, novos dados coletados", _style_success)
	

func hide_message() -> void:
	visible = false

func _show(text: String, style: StyleBoxFlat) -> void:
	_label.text = text
	_panel.add_theme_stylebox_override("panel", style)
	visible = true
	_timer.start()
