extends Node2D

## Controlador da cena de teste.
## Conecta SweetSpot → RepertoireMinigame.
## O player precisa estar no grupo "player" (já configurado no TestScene.tscn).

@onready var minigame: RepertoireMinigame         = $HUD/RepertoireMinigame

func _ready() -> void:
	# Busca todas as áreas do tipo SweetSpot que forem filhas da TestScene
	for child in get_children():
		if child is SweetSpot:
			child.player_entered_sweetspot.connect(_on_entered_sweetspot)
			child.player_exited_sweetspot.connect(_on_exited_sweetspot)
			
	minigame.minigame_completed.connect(_on_minigame_completed)
	minigame.minigame_cancelled.connect(_on_minigame_cancelled)

func _on_entered_sweetspot(emitter: RadioEmitter) -> void:
	if emitter.signal_data:
		minigame.open(emitter.signal_data)
		
		# Força o player de áudio do pássaro a rodar na simulação
		var bird_player = emitter.get_node_or_null("BirdPlayer")
		if bird_player and not bird_player.playing:
			bird_player.play()
		
		# Conecta o áudio do rádio ao visor do sonograma na HUD
		var sonogram = $HUD/BirdSonogram
		if sonogram and sonogram.has_method("analyze") and bird_player:
			sonogram.analyze(bird_player)

func _on_exited_sweetspot() -> void:
	# Não fecha automaticamente — deixa o player terminar ou sair com Esc
	pass

func _on_minigame_completed(data: SignalData) -> void:
	print("[TestScene] Canto aprendido: ", data.display_name)

func _on_minigame_cancelled() -> void:
	print("[TestScene] Mini-game cancelado")
