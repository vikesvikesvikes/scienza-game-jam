extends Control

# Índice da ave que está sendo visualizada no caderno no momento
var current_bird_index: int = 0

# Referências para as duas páginas (ajuste os caminhos se necessário)
@onready var puzzle_page: VBoxContainer = $OpenPages/Puzzle
@onready var info_page: VBoxContainer = $OpenPages/BirdInfo

func _ready() -> void:
	visible = false # Começa fechado

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_notebook"):
		visible = !visible
		if visible:
			_atualizar_paginas_caderno()

## Função que atualiza o conteúdo visual das folhas do caderno
func _atualizar_paginas_caderno() -> void:
	# Pega a lista de todas as aves que o jogador já conheceu ou tem dados
	# Para este exemplo, usaremos os sinais aprendidos no SignalBook
	var list_of_birds = SignalBook.learned_signals 
	
	# Se o jogador não encontrou nenhum pássaro ainda, exibe uma página vazia
	if list_of_birds.size() == 0:
		_mostrar_caderno_vazio()
		return
		
	# Garante que o índice não saia dos limites válidos
	current_bird_index = clamp(current_bird_index, 0, list_of_birds.size() - 1)
	var active_bird: SignalData = list_of_birds[current_bird_index]
	
	# --- 1. ATUALIZAR PÁGINA DA DIREITA (Informações e Curiosidades) ---
	# Aqui você pode mudar textos de Labels que criou dentro do BirdInfo
	var name_label = info_page.get_node_or_null("BirdNameLabel")
	if name_label:
		name_label.text = active_bird.display_name
		
	var icon_rect = info_page.get_node_or_null("BirdIconTexture")
	if icon_rect and active_bird.bird_icon: 
		icon_rect.texture = active_bird.bird_icon 

	# --- 2. ATUALIZAR PÁGINA DA ESQUERDA (Quebra-Cabeça) ---
	# Verifica quantas peças o jogador tem comparado ao total
	var encounter_count = GameManager.get_encounter_count(active_bird.signal_id)
	
	var progress_label = puzzle_page.get_node_or_null("PuzzleProgressLabel")
	if progress_label:
		# Exemplo: Cada encontro libera pedaços ou mostra o progresso de estudo
		progress_label.text = "Captações realizadas: %d" % encounter_count
		
	# Lógica para ativar o botão do Minigame se houver progresso disponível
	var play_button = puzzle_page.get_node_or_null("StartPuzzleButton")
	if play_button:
		play_button.disabled = (encounter_count == 0)

func _mostrar_caderno_vazio() -> void:
	# Configura textos padrões avisando que o caderno está vazio
	var name_label = info_page.get_node_or_null("BirdNameLabel")
	if name_label: name_label.text = "Nenhuma anotação..."
	var progress_label = puzzle_page.get_node_or_null("PuzzleProgressLabel")
	if progress_label: progress_label.text = "Explore o mapa com seu rádio para coletar sinais!"

# --- MÉTODOS PARA OS BOTÕES DE SETA (Conectar o sinal 'pressed' neles) ---

func _on_next_page_pressed() -> void:
	var list_of_birds = SignalBook.learned_signals 
	if current_bird_index < list_of_birds.size() - 1:
		current_bird_index += 1
		_atualizar_paginas_caderno()

func _on_prev_page_pressed() -> void:
	if current_bird_index > 0:
		current_bird_index -= 1
		_atualizar_paginas_caderno()
