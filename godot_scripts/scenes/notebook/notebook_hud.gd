extends Control

# Índice da ave que está sendo visualizada no caderno no momento
var current_bird_index: int = 0

# Referências para as duas páginas
@onready var puzzle_page: Panel = $OpenPages/PuzzlePage
@onready var info_page: VBoxContainer = $OpenPages/BirdInfo

# Referência direta ao nó raiz do script PuzzleMain se ele estiver instanciado na página
@onready var puzzle_handler = $OpenPages/PuzzlePage/SubViewportContainer/SubViewport/PuzzleMain

@export var debug_birds_to_inject: Array[SignalData] = []
@export var run_in_debug_mode: bool = false

func _ready() -> void:
	# Se a opção estiver ativa ou se estivermos rodando a cena isoladamente (sem fluxo do GameManager externo)
	if run_in_debug_mode and not debug_birds_to_inject.is_empty():
		print("[NotebookDebug] Injetando aves de teste para validação de layout.")
		for test_bird in debug_birds_to_inject:
			# Força o aprendizado fictício e simula captações no GameManager
			if not SignalBook.check_signal(test_bird.signal_id):
				SignalBook.learned_signals.append(test_bird)
				# Garante que as sílabas simulem o estado totalmente desbloqueado de 3 encontros
				SignalBook.unlock_syllables_for_encounter(test_bird, 3)
				# Define que encontramos a ave 3 vezes para liberar o puzzle e a interface
				GameManager.bird_encounter_counts[test_bird.signal_id] = 3
	
	var prev_button = get_node_or_null("BtnAnterior") 
	var next_button = get_node_or_null("BtnProximo")
	
	if prev_button and not prev_button.pressed.is_connected(_on_prev_page_pressed):
		prev_button.pressed.connect(_on_prev_page_pressed)
	if next_button and not next_button.pressed.is_connected(_on_next_page_pressed):
		next_button.pressed.connect(_on_next_page_pressed)
		
	visible = true 
	_atualizar_paginas_caderno()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_notebook"):
		if visible:
			_salvar_puzzle_atual()
		
		visible = !visible
		
		if visible:
			_atualizar_paginas_caderno()

func _salvar_puzzle_atual() -> void:
	var list_of_birds = SignalBook.learned_signals
	if list_of_birds.size() > 0 and current_bird_index < list_of_birds.size():
		var active_bird: SignalData = list_of_birds[current_bird_index]
		PuzzleGlobal.save_bird_puzzle(active_bird.signal_id)

## Função que atualiza o conteúdo visual das folhas do caderno
func _atualizar_paginas_caderno() -> void:
	var list_of_birds = SignalBook.learned_signals 
	
	if list_of_birds.size() == 0:
		_mostrar_caderno_vazio()
		return
		
	current_bird_index = clamp(current_bird_index, 0, list_of_birds.size() - 1)
	var active_bird: SignalData = list_of_birds[current_bird_index]
	
	# Atalho para acessar os dados biológicos internos da enciclopédia
	var bio = active_bird.biological_data if "biological_data" in active_bird else null
	
	# --- 1. ATUALIZAR PÁGINA DA DIREITA (Informações e Curiosidades) ---
	var name_label = info_page.get_node_or_null("ColorRect3/ScrollContainer/MarginContainer/VBoxContainer/LabelNomePopular")
	if name_label:
		name_label.text = active_bird.display_name

	var cientifico_label = info_page.get_node_or_null("ColorRect3/ScrollContainer/MarginContainer/VBoxContainer/GridContainer/LabelNomeCientificoValor")
	if cientifico_label and bio and "scientific_name" in bio:
		cientifico_label.text = bio.scientific_name

	# Fallback caso não use english_name, podemos usar o primeiro nome popular extra se existir
	var ingles_label = info_page.get_node_or_null("ColorRect3/ScrollContainer/MarginContainer/VBoxContainer/GridContainer/LabelInglesValor")
	if ingles_label:
		if bio and not bio.popular_names.is_empty():
			ingles_label.text = bio.popular_names[0] # Usa o nome principal ou ajusta conforme preferir
		else:
			ingles_label.text = "---"

	var diet_label = info_page.get_node_or_null("ColorRect3/ScrollContainer/MarginContainer/VBoxContainer/LabelDietValor")
	if diet_label and bio and "diet" in bio:
		diet_label.text = bio.diet

	var habitat_label = info_page.get_node_or_null("ColorRect3/ScrollContainer/MarginContainer/VBoxContainer/LabelHabitatValor")
	if habitat_label and bio and "habitats" in bio:
		habitat_label.text = bio.habitats

	var curiosidade_label = info_page.get_node_or_null("ColorRect3/ScrollContainer/MarginContainer/VBoxContainer/CuriosidadeValor")
	if curiosidade_label and bio and "curiosity" in bio:
		curiosidade_label.text = bio.curiosity

	var icon_rect = info_page.get_node_or_null("BirdIconTexture")
	if icon_rect and active_bird.puzzle_image: 
		icon_rect.texture = active_bird.puzzle_image

	# --- 2. ATUALIZAR PÁGINA DA ESQUERDA (Quebra-Cabeça) ---
	var encounter_count = GameManager.get_encounter_count(active_bird.signal_id)
	
	var progress_label = puzzle_page.get_node_or_null("PuzzleProgressLabel")
	if progress_label:
		progress_label.text = "Captações realizadas: %d" % encounter_count
		
	var play_button = puzzle_page.get_node_or_null("StartPuzzleButton")
	if play_button:
		play_button.disabled = (encounter_count == 0)

	# --- 3. RECONSTRUIR OU RESTAURAR O PUZZLE DINÂMICO ---
	if puzzle_handler and puzzle_handler.has_method("init_puzzle"):
		puzzle_handler.init_puzzle(active_bird)

	# --- 4. VALIDAÇÃO DOS BOTÕES DE NAVEGAÇÃO ---
	var prev_button = get_node_or_null("BtnAnterior") # Ajuste para o caminho real do seu botão esquerdo
	var next_button = get_node_or_null("BtnProximo")  # Ajuste para o caminho real do seu botão direito
	
	if prev_button:
		prev_button.disabled = (current_bird_index == 0)
	if next_button:
		next_button.disabled = (current_bird_index >= list_of_birds.size() - 1)

func _mostrar_caderno_vazio() -> void:
	var name_label = info_page.get_node_or_null("LabelNomePopular")
	if name_label: name_label.text = "Nenhuma anotação..."
	var progress_label = puzzle_page.get_node_or_null("PuzzleProgressLabel")
	if progress_label: progress_label.text = "Explore o mapa com seu rádio para coletar sinais!"

# --- MÉTODOS PARA OS BOTÕES DE SETA ---

func _on_next_page_pressed() -> void:
	var list_of_birds = SignalBook.learned_signals 
	if current_bird_index < list_of_birds.size() - 1:
		_salvar_puzzle_atual()
		current_bird_index += 1
		_atualizar_paginas_caderno()

func _on_prev_page_pressed() -> void:
	if current_bird_index > 0:
		_salvar_puzzle_atual()
		current_bird_index -= 1
		_atualizar_paginas_caderno()
