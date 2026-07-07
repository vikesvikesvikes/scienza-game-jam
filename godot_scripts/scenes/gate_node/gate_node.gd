class_name GateNode
extends Node2D

## Coloque num Node2D com um Sprite2D (porta fechada/aberta) como filho.
## Filho opcional: AnimationPlayer nomeado "AnimPlayer" com animação "open"

## IDs dos sinais necessários para abrir esta porta
@export var required_signal_ids: Array[String] = []

## Se true, mostra quais sinais faltam ao interagir
@export var show_hint_on_interact: bool = true

@onready var anim_player: AnimationPlayer = $AnimPlayer if has_node("AnimPlayer") else null

var _is_open: bool = false

func _ready() -> void:
	# Escuta novos sinais aprendidos
	SignalBook.signal_learned.connect(_on_signal_learned)
	_check_unlock()

func _on_signal_learned(_signal_data: SignalData) -> void:
	_check_unlock()

func _check_unlock() -> void:
	if _is_open:
		return
	if SignalBook.has_all(required_signal_ids):
		_unlock()

func _unlock() -> void:
	_is_open = true
	print("[GateNode] Porta desbloqueada!")
	if anim_player:
		anim_player.play("open")

## Chame ao interagir com a porta para mostrar dica de progresso
func get_progress_hint() -> String:
	var missing: Array[String] = []
	for id in required_signal_ids:
		if not SignalBook.has_signal(id):
			missing.append(id)
	if missing.is_empty():
		return "A passagem está aberta!"
	return "Faltam %d canto(s): %s" % [missing.size(), ", ".join(missing)]
