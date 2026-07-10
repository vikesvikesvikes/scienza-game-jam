extends CharacterBody2D

@export var speed: float = 150.0

# Referência direta para o novo nó de sprite animado que substituiu a árvore antiga
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	# 1. Captura as direções do teclado/controle (permitindo diagonais nativamente)
	var input_direction := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	
	# Normaliza o vetor para manter a mesma velocidade em todas as direções
	input_direction = input_direction.normalized()
	
	# 2. Movimenta o corpo físico da personagem
	velocity = input_direction * speed
	move_and_slide()
	
	# 3. Gerenciador de Animações (Walk e Idle usando reaproveitamento de 6 direções)
	if input_direction != Vector2.ZERO:
		# Obtém o sufixo da direção baseada no movimento atual
		var direction_name = _get_animation_direction(input_direction)
		animated_sprite.play("walk_" + direction_name)
	else:
		# Se o jogador parou, pegamos o nome da última animação de caminhada tocada
		# e substituímos "walk_" por "idle_" para rodar o ciclo parado correspondente
		var last_direction = animated_sprite.animation.replace("walk_", "").replace("idle_", "")
		animated_sprite.play("idle_" + last_direction)

## Função que calcula o ângulo do movimento e mapeia para as 6 animações disponíveis
func _get_animation_direction(direction: Vector2) -> String:
	# Calcula o ângulo em radianos e converte para graus positivos (0 a 360)
	var angle = direction.angle()
	var angle_degrees = snapped(rad_to_deg(angle), 45)
	if angle_degrees < 0:
		angle_degrees += 360
		
	# Mapeamento inteligente para as 6 direções reais do arquivo de sprite
	match int(angle_degrees):
		0, 360:     return "down_right" # Direita pura -> Usa Diagonal Baixo-Direita
		45:         return "down_right" # Diagonal Baixo-Direita
		90:         return "down"       # Baixo puro
		135:        return "down_left"  # Diagonal Baixo-Esquerda
		180:        return "down_left"  # Esquerda pura -> Usa Diagonal Baixo-Esquerda
		225:        return "up_left"    # Diagonal Cima-Esquerda
		270:        return "up"         # Cima puro
		315:        return "up_right"   # Diagonal Cima-Direita
		_:          return "down"       # Caso de segurança (padrão olhando para baixo)
