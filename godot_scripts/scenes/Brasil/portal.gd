extends Area2D

# O filtro garante que você só consiga arrastar ou selecionar arquivos .tscn válidos
@export_file("*.tscn") var cena_destino_path: String

@onready var indicador_ui: Node2D = $IndicadorUI

var player_na_area: bool = false

func _ready() -> void:
	# Conecta os próprios sinais de física automaticamente
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# Se o jogador estiver na área e pressionar a tecla de interação
	if player_na_area and Input.is_action_just_pressed("enter_portal"): # Ou crie uma action "interagir"
		teleportar()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_na_area = true
		indicador_ui.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_na_area = false
		indicador_ui.visible = false

func teleportar() -> void:
	if cena_destino_path and cena_destino_path != "":
		# Desativa o processamento para evitar múltiplos cliques/comandos simultâneos
		set_process(false) 
		GameManager.change_scene(cena_destino_path)
	else:
		push_warning("Aviso: O portal em %s não possui um caminho de cena definido!" % name)
