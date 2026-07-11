extends CharacterBody2D

@export var speed: float = 150.0

# Referência direta para o novo nó de sprite animado que substituiu a árvore antiga
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- SISTEMA DE MAPA DE PIXELS ---
var mapa_image: Image
var mapa_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Busca o TextureRect na raiz da cena (ajuste o caminho se necessário)
	var texture_rect: TextureRect = get_node_or_null("../TextureRect")
	
	if texture_rect and texture_rect.texture:
		# Extrai os dados de pixel da textura para a memória RAM
		mapa_image = texture_rect.texture.get_image()
		mapa_offset = texture_rect.global_position
	else:
		push_warning("[Player] TextureRect do mapa não foi localizado. Colisão por pixels desativada.")
# ----------------------------------

func _physics_process(delta: float) -> void:
	# 1. Captura as direções do teclado/controle (permitindo diagonais nativamente)
	var input_direction := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	
	# Normaliza o vetor para manter a mesma velocidade em todas as direções
	input_direction = input_direction.normalized()
	
	# 2. Movimenta o corpo físico da personagem com validação do mapa
	var movimento_desejado = input_direction * speed
	
	if input_direction != Vector2.ZERO and mapa_image != null:
		# Calcula onde o jogador estaria no próximo frame antes de aplicar o movimento
		var proxima_posicao = global_position + (movimento_desejado * delta)
		
		# Converte a posição do mundo para a coordenada de pixels da imagem
		var pixel_pos = proxima_posicao - mapa_offset
		var px := int(pixel_pos.x)
		var py := int(pixel_pos.y)
		
		# Valida se as coordenadas estão dentro dos limites da imagem
		if px >= 0 and px < mapa_image.get_width() and py >= 0 and py < mapa_image.get_height():
			var cor_pixel = mapa_image.get_pixel(px, py)
			
			# Define a cor alvo do azul da borda (aproximada do seu JPG)
			var azul_borda = Color("33999e")
			
			# Calcula se a cor do pixel atual é muito próxima ao azul da borda (tolerância de 0.1)
			var eh_azul_borda = cor_pixel.is_equal_approx(azul_borda) or (abs(cor_pixel.r - azul_borda.r) < 0.05 and abs(cor_pixel.g - azul_borda.g) < 0.05 and abs(cor_pixel.b - azul_borda.b) < 0.05)
			
			# O preto de fundo serve como backup definitivo
			var eh_fundo_preto = (cor_pixel.r + cor_pixel.g + cor_pixel.b) <= 0.1
			
			# CONDIÇÃO DE MOVIMENTO: 
			if eh_azul_borda or eh_fundo_preto:
				velocity = Vector2.ZERO
			else:
				# Barreira invisível (Fundo Preto Detectado)
				velocity = movimento_desejado
		else:
			# Fora da imagem
			velocity = Vector2.ZERO
	else:
		velocity = movimento_desejado
		
	move_and_slide()
	
	# 3. Gerenciador de Animações (Walk e Idle usando reaproveitamento de 6 direções)
	if input_direction != Vector2.ZERO and velocity != Vector2.ZERO:
		# Obtém o sufixo da direção baseada no movimento atual
		var direction_name = _get_animation_direction(input_direction)
		animated_sprite.play("walk_" + direction_name)
	else:
		# Se o jogador parou ou colidiu com a parede invisível, atualiza para o Idle correspondente
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
