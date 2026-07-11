extends PathFollow2D

@export var walk_speed := 100.0
var is_moving := false
var direction := 0  # 1 = direita, -1 = esquerda
var total_length := 0.0
var initial_position: Vector2

func _ready():
	total_length = get_parent().curve.get_baked_length()
	progress = 0
	initial_position = position
	print("Total length: ", total_length)

func _physics_process(delta):
	# Detecta comandos APENAS se não estiver se movendo
	if not is_moving:
		if Input.is_action_just_pressed("ui_right"):
			# Só pode ir para direita se não estiver no fim
			if progress < total_length:
				print("Indo para DIREITA")
				is_moving = true
				direction = 1
			else:
				print("Já está no fim do caminho!")
				
		elif Input.is_action_just_pressed("ui_left"):
			# Só pode ir para esquerda se não estiver no início
			if progress > 0:
				print("Indo para ESQUERDA")
				is_moving = true
				direction = -1
			else:
				print("Já está no início do caminho!")
	
	# Movimenta
	if is_moving:
		var new_progress = progress + walk_speed * direction * delta
		
		# Verifica limites
		if direction == 1:  # Indo para direita
			if new_progress >= total_length:
				new_progress = total_length
				is_moving = false
				direction = 0
				print("Chegou ao FIM!")
		else:  # Indo para esquerda (direction == -1)
			if new_progress <= 0:
				new_progress = 0
				is_moving = false
				direction = 0
				print("Chegou ao INÍCIO!")
		
		progress = new_progress
		
		# Debug
		print("Progress: ", progress, " / ", total_length)

func _process(delta):
	# Mantém a posição Y fixa
	position.y = initial_position.y
