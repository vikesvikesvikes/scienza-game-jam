# --- [ biome_1.gd ] ---
extends Node2D

@onready var radial_menu: Control = $HUD/RadialMenu
@onready var minigame: RepertoireMinigame = $HUD/RepertoireMinigame

# Armazena temporariamente qual rádio o jogador está pisando no momento
var radio_atual: RadioEmitter = null

func _ready() -> void:
	# Inicialização do Menu Radial
	radial_menu.visible = false
	radial_menu.enabled = false
	
	# Conecta dinamicamente todos os SweetSpots presentes na cena biome_1
	for child in get_children():
		if child is SweetSpot:
			child.player_entered_sweetspot.connect(_on_entered_sweetspot)
			child.player_exited_sweetspot.connect(_on_exited_sweetspot)
			
	# Conecta as respostas de finalização do minijogo
	minigame.minigame_completed.connect(_on_minigame_completed)
	minigame.minigame_cancelled.connect(_on_minigame_cancelled)

func _unhandled_input(event: InputEvent) -> void:
	# 1. GERENCIAMENTO DO MENU RADIAL (Segurar TAB)
	if event.is_action_pressed(&"radial_open"):
		if minigame.visible: # Só permite abrir se o minijogo de estudo estiver ativo
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
		return

	# 2. INTERAÇÃO PARA ABRIR O ESTUDO (Tecla E)
	if event is InputEventKey and event.pressed and event.keycode == KEY_E and radio_atual != null:
		if not minigame.visible:
			_abrir_estudo_da_ave(radio_atual)

func _open_radial() -> void:
	radial_menu.visible = true
	radial_menu.enabled = true

func _close_radial() -> void:
	radial_menu.visible = false
	radial_menu.enabled = false

func _choose_slot(index: int) -> void:
	radial_menu.set_temporary_selection(index)
	# Modificado: Se você implementou o método customizado no RepertoireMinigame
	if minigame.has_method("receive_radial_input"):
		minigame.receive_radial_input(index)
	else:
		# Fallback para o comportamento padrão por index (Grave, Neutro, Agudo)
		minigame._on_frequency_pressed(index)

func _on_entered_sweetspot(emitter: RadioEmitter) -> void:
	radio_atual = emitter
	var bird_player = emitter.get_node_or_null("BirdPlayer")
	if bird_player and not bird_player.playing:
		bird_player.play()

func _on_exited_sweetspot() -> void:
	radio_atual = null
	minigame.close()
	_close_radial()

func _abrir_estudo_da_ave(emitter: RadioEmitter) -> void:
	if emitter.signal_data:
		var signal_data = emitter.signal_data
		
		# Registra o encontro incremental no GameManager (1º, 2º, 3º encontro...)
		var encontros: int = GameManager.register_encounter(signal_data.signal_id)
		
		# Destrava as sílabas correspondentes no inventário global
		SignalBook.unlock_syllables_for_encounter(signal_data, encontros)
		
		# Abre a interface com as sílabas atualizadas
		minigame.open(signal_data)

func _on_minigame_completed(signal_data: SignalData) -> void:
	if radio_atual != null:
		print("[Pesquisa] Dados coletados com sucesso em biome_1!")
		var bird_player = radio_atual.get_node_or_null("BirdPlayer")
		if bird_player:
			bird_player.stop()
		
		# Limpa o SweetSpot correspondente do mapa após exaurir a coleta
		for child in get_children():
			if child is SweetSpot and child.linked_emitter == radio_atual.get_path():
				child.queue_free()
				break
				
		radio_atual = null
		minigame.close()
		_close_radial()

func _on_minigame_cancelled() -> void:
	_close_radial()
