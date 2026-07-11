extends Node2D
@onready var minigame: RepertoireMinigame = $HUD/RepertoireMinigame

# Criamos apenas essa caixinha para lembrar em qual rádio o jogador está pisando
var radio_atual: RadioEmitter = null

func _ready() -> void:
	for child in get_children():
		if child is SweetSpot:
			child.player_entered_sweetspot.connect(_on_entered_sweetspot)
			child.player_exited_sweetspot.connect(_on_exited_sweetspot)
	minigame.minigame_completed.connect(_on_minigame_completed)
	minigame.minigame_cancelled.connect(_on_minigame_cancelled)

# O Godot roda essa função o tempo todo capturando o teclado do jogador
func _unhandled_input(event: InputEvent) -> void:
	# Se o jogador apertou a tecla E e ele ESTÁ dentro de um SweetSpot (radio_atual existe)
	if event is InputEventKey and event.pressed and event.keycode == KEY_E and radio_atual != null:
		# Só abre se o minijogo já não estiver aberto na tela
		if not minigame.visible:
			_abrir_estudo_da_ave(radio_atual)

func _on_entered_sweetspot(emitter: RadioEmitter) -> void:
	# O jogador entrou! Vamos lembrar qual rádio é este
	radio_atual = emitter
	
	# Liga o som automaticamente ao se aproximar (comportamento original seu)
	var bird_player = emitter.get_node_or_null("BirdPlayer")
	if bird_player and not bird_player.playing:
		bird_player.play()

func _on_exited_sweetspot() -> void:
	# O jogador saiu! Limpamos a memória e fecha o minijogo se estava aberto
	radio_atual = null
	minigame.close()

# Esta é a sua lógica de interação, modificada temporariamente para BYPASS de Debug!
func _abrir_estudo_da_ave(emitter: RadioEmitter) -> void:
	if emitter.signal_data:
		var signal_data = emitter.signal_data
		
		# 1. Registra o encontro no GameManager
		var encontros: int = GameManager.register_encounter(signal_data.signal_id)
		
		# 2. Desbloqueia as sílabas correspondentes
		SignalBook.unlock_syllables_for_encounter(signal_data, encontros)
		
		# 3. Verifica se atingiu o teto de estudos definido no próprio recurso da ave
		var esta_completo = SignalBook.is_bird_fully_studied(signal_data, encontros)
		var progresso = signal_data.get_study_progress_percentage(encontros)
		
		print("[DEBUG] Ave: %s | Progresso: %.1f%%" % [signal_data.display_name, progresso])
		
		if esta_completo:
			if not SignalBook.check_signal(signal_data.signal_id):
				SignalBook.learn_signal(signal_data)
				print("[DEBUG] Estudo Concluído! Caderno atualizado.")

# Esta é a sua lógica exata, centralizada para rodar apenas quando o "E" for apertado!
#func _abrir_estudo_da_ave(emitter: RadioEmitter) -> void:
	#if emitter.signal_data:
		#var signal_data = emitter.signal_data
		#
		## 1. Registra o encontro no GameManager
		#var encontros: int = GameManager.register_encounter(signal_data.signal_id)
		#
		## 2. Conecta o áudio ao sonograma da HUD para começar a análise visual
		#var bird_player = emitter.get_node_or_null("BirdPlayer")
		#var sonogram = $HUD/BirdSonogram
		#if sonogram and sonogram.has_method("analyze") and bird_player:
			#sonogram.analyze(bird_player)
			#
		## 3. Lógica de Progressão baseada nos Encontros:
		#if encontros < 3:
			#print("[TestScene] Captação parcial número ", encontros, " para: ", signal_data.display_name)
			#SignalBook.unlock_syllables_for_encounter(signal_data, encontros)
			#
			## Abre o minijogo (que no passo 3 vai mostrar algumas sílabas bloqueadas)
			#minigame.open(signal_data)
		#else:
			#print("[TestScene] Sinal completamente limpo para análise de: ", signal_data.display_name)
			#SignalBook.unlock_syllables_for_encounter(signal_data, 3)
			#
			## Abre o minijogo completo
			#minigame.open(signal_data)

# Mantidos os seus métodos originais abaixo...
@warning_ignore("unused_parameter")
func _on_minigame_completed(signal_data: SignalData) -> void:
	if radio_atual != null:
		print("[Pesquisa] Dados coletados com sucesso neste ponto. Desativando transmissor...")
		
		# 1. Para o áudio da ave para indicar visualmente/auditivamente que foi exaurido
		var bird_player = radio_atual.get_node_or_null("BirdPlayer")
		if bird_player:
			bird_player.stop()
		
		# 2. Desativa o SweetSpot para que o jogador não consiga interagir de novo nele
		if radio_atual.has_method("set_process"):
			radio_atual.set_process(false)
		
		# Se o seu SweetSpot for um Area2D mapeado por nós filhos:
		for child in get_children():
			if child is SweetSpot and child.linked_emitter == radio_atual.get_path():
				child.queue_free() # Remove o ponto de interação do mapa
				break
				
		radio_atual = null
		minigame.close()

func _on_minigame_cancelled() -> void:
	pass
