extends CharacterBody2D

@export var speed: float = 120.0

# Referências aos nós de animação
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback = animation_tree.get("parameters/playback")

func _physics_process(_delta: float) -> void:
	# 1. Captura as direções do teclado/controle
	var input_direction := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	
	# Estilo Pokémon clássico: impede travamento ou bug se o jogador apertar diagonais
	if input_direction.x != 0 and input_direction.y != 0:
		input_direction.y = 0  # Prioriza andar para os lados se apertar diagonal
		
	# Normaliza o vetor para o boneco não andar mais rápido na diagonal
	input_direction = input_direction.normalized()
	
	# 2. Movimenta o corpo físico do especialista
	velocity = input_direction * speed
	move_and_slide()
	
	# 3. Alimenta a Árvore de Animações com os dados físicos
	if input_direction != Vector2.ZERO:
		# Atualiza a posição do ponteiro (X, Y) dentro das "pastas" Idle e Walk
		animation_tree.set("parameters/Idle/blend_position", input_direction)
		animation_tree.set("parameters/Walk/blend_position", input_direction)
		
		# Viaja no gráfico principal para o estado "Walk"
		playback.travel("Walk")
	else:
		# Se a velocidade for zero, viaja para o estado "Idle"
		playback.travel("Idle")
