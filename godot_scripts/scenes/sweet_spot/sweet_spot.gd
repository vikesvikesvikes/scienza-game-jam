class_name SweetSpot
extends Area2D

## Area2D circular colocado no mapa onde o sinal fica limpo.
## Filho obrigatório: CollisionShape2D com CircleShape2D
## Conecte linked_emitter ao RadioEmitter correspondente no editor.

## Emitido quando o player entra no sweet spot (abre UI de Interpretação)
signal player_entered_sweetspot(emitter: RadioEmitter)

## Emitido quando o player sai (fecha UI de Interpretação)
signal player_exited_sweetspot

## O RadioEmitter ao qual este sweet spot pertence
@export var linked_emitter: NodePath

## Se true, mostra um indicador visual no mapa (DebugShape)
@export var show_debug_area: bool = true

var _emitter: RadioEmitter = null

func _ready() -> void:
	# Adiciona ao grupo para ser encontrado pelo BirdHint
	add_to_group("sweet_spots")
	
	if linked_emitter:
		_emitter = get_node(linked_emitter)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if show_debug_area:
		modulate = Color(0.2, 1.0, 0.4, 0.15)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		print("[SweetSpot] body_entered ignorado — '%s' não está no grupo 'player'" % body.name)
		return
	print("[SweetSpot] ✅ Player ENTROU no sweet spot")
	if _emitter:
		print("[SweetSpot]   → emitter encontrado: %s" % _emitter.name)
		_emitter.on_player_entered_sweet_spot()
		player_entered_sweetspot.emit(_emitter)
		print("[SweetSpot]   → sinal player_entered_sweetspot emitido")
	else:
		print("[SweetSpot]   ⚠️  linked_emitter não configurado — verifique o Inspector")

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	print("[SweetSpot] 🚪 Player SAIU do sweet spot")
	if _emitter:
		_emitter.on_player_exited_sweet_spot()
	player_exited_sweetspot.emit()
	print("[SweetSpot]   → sinal player_exited_sweetspot emitido")
	
