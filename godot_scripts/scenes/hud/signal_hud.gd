class_name SignalHUD
extends CanvasLayer

## HUD persistente de intensidade de sinal.
## Coloque num CanvasLayer de layer 1 (abaixo do RepertoireMinigame).
## Conecte ao SweetSpot e RadioEmitter via código ou sinal do GameManager.

## Nó de barra de intensidade (TextureProgressBar ou ProgressBar)
@onready var signal_bar: ProgressBar = $SignalBar

## Label que mostra o tipo de ruído
@onready var noise_label: Label = $NoiseLabel

## Ícone de antena que anima quando próximo do sweet spot
@onready var antenna_icon: TextureRect = $AntennaIcon

var _current_emitter: RadioEmitter = null
var _player: Node2D = null

func _ready() -> void:
	signal_bar.value = 0
	noise_label.text = ""

## Chame quando o player entra no range de um RadioEmitter
func set_active_emitter(emitter: RadioEmitter, player: Node2D) -> void:
	_current_emitter = emitter
	_player = player
	var noise_names := {
		SignalData.NoiseType.WIND: "Vento",
		SignalData.NoiseType.CARS: "Tráfego",
		SignalData.NoiseType.WATER: "Água",
		SignalData.NoiseType.GENERIC: "Interferência",
	}
	if emitter.signal_data:
		noise_label.text = noise_names.get(emitter.signal_data.noise_type, "")

## Chame quando o player sai do range
func clear_emitter() -> void:
	_current_emitter = null
	_player = null
	signal_bar.value = 0
	noise_label.text = ""

func _process(_delta: float) -> void:
	if not _current_emitter or not _player:
		return

	var shape: CollisionShape2D = _current_emitter.get_node(
		"DetectionArea/CollisionShape2D"
	)
	var max_range: float = (shape.shape as CircleShape2D).radius
	var dist: float = _current_emitter.global_position.distance_to(_player.global_position)
	var intensity: float = clamp(1.0 - dist / max_range, 0.0, 1.0)

	signal_bar.value = intensity * 100.0

	# Pulsa o ícone de antena quando intensity > 70%
	if intensity > 0.7:
		antenna_icon.modulate = Color.CYAN
	else:
		antenna_icon.modulate = Color.WHITE
