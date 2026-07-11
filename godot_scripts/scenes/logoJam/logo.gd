extends Node2D

@export_file("*.tscn") var cena_destino_path: String
var delay_seconds: float = 4.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Cria um timer temporário atrelado à árvore da cena e aguarda o término (timeout)
	await get_tree().create_timer(delay_seconds).timeout
	
	# Dispara a mudança usando a função que você já estruturou no GameManager
	_mudar_de_cena()

func _mudar_de_cena() -> void:
	if cena_destino_path != "":
		GameManager.change_scene(cena_destino_path)
	else:
		push_warning("[Transicao] Alerta: O caminho para a próxima cena não foi definido!")
