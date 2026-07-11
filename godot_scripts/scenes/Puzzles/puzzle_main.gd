extends Node2D

const TARGET_SIZE = Vector2(790, 920)
@onready var cells = $Cells
@onready var cell_scene = preload("res://godot_scripts/scenes/Puzzles/Cell.tscn")

@onready var pieces = $Pieces
@onready var piece_scene = preload("res://godot_scripts/scenes/Puzzles/PuzzlePiece.tscn")

var piece_size: Vector2 = Vector2(100, 100)
var current_bird_id: String = ""


func _ready() -> void:
	var img: Image = PuzzleGlobal.get_image()
	if img:
		# Redimensiona a imagem do pássaro para caber perfeitamente no espaço do caderno
		img.resize(TARGET_SIZE.x, TARGET_SIZE.y, Image.INTERPOLATE_LANCZOS)
		var new_texture = ImageTexture.create_from_image(img)
		
		# A partir daqui, sua lógica que fatia as peças usando 'Region' 
		# utilizará a textura já perfeitamente moldada para os 790x920!
		
		
func init_puzzle(bird_data: SignalData) -> void:
	# Limpa instâncias anteriores na árvore e dados residuais
	for child in cells.get_children():
		child.queue_free()
	for child in pieces.get_children():
		child.queue_free()
		
	PuzzleGlobal.clear_runtime_data()
	
	if not bird_data or not bird_data.puzzle_image:
		return
		
	current_bird_id = bird_data.signal_id
	PuzzleGlobal.set_current_bird_image(bird_data.puzzle_image.get_image())
	
	init_game()

func init_game():
	# 1º: Pegamos a imagem e definimos o piece_size correto em tempo de execução
	var image = PuzzleGlobal.get_image()
	if image:
		piece_size = Vector2(
			image.get_width() / PuzzleGlobal.grid_size.x,
			image.get_height() / PuzzleGlobal.grid_size.y
		)
	
	# 2º: Agora sim desenhamos as células e geramos as peças com o tamanho correto!
	draw_cells()
	generate_pieces()

func draw_cells():
	for y in range(PuzzleGlobal.grid_size.y):
		for x in range(PuzzleGlobal.grid_size.x):
			add_cell(x, y)

func add_cell(x, y):
	var cell = cell_scene.instantiate()
	cells.add_child(cell)
	PuzzleGlobal.cells.append(cell)
	
	# Posiciona localmente em relação ao nó pai "Cells" (que já está em 328, 326)
	cell.position = Vector2(
		piece_size.x * x,
		piece_size.y * y
	)
	# Fórmula correta para ID único linear: (linha * total_de_colunas) + coluna
	var idx = (y * PuzzleGlobal.grid_size.x) + x
	cell.init_cell(idx, piece_size)

func generate_pieces():
	var image = PuzzleGlobal.get_image()
	if not image:
		return
		
	var saved_state = PuzzleGlobal.get_saved_bird_puzzle(current_bird_id)
	var has_saved_data = not saved_state.is_empty()
	
	var piece_index = 0
	
	# Loop corrigido: Varre linha por linha (y), coluna por coluna (x)
	for y in range(PuzzleGlobal.grid_size.y):
		for x in range(PuzzleGlobal.grid_size.x):
			var piece = piece_scene.instantiate()
			pieces.add_child(piece)
			PuzzleGlobal.pieces.append(piece)
			
			var region = Rect2(x * piece_size.x, y * piece_size.y, piece_size.x, piece_size.y)
			var sub_image = image.get_region(Rect2i(region.position, region.size))
			var sub_tex = ImageTexture.create_from_image(sub_image)
			
			var pos: Vector2
			var saved_cell_idx: int = -1
			
			if has_saved_data and piece_index < saved_state.size():
				var data = saved_state[piece_index]
				pos = data["position"]
				saved_cell_idx = data["cell_index"]
			else:
				# Distribuição randômica inicial baseada no ID linear correto
				var actual_idx = int(y * PuzzleGlobal.grid_size.x + x)
				if actual_idx < (PuzzleGlobal.grid_size.x * PuzzleGlobal.grid_size.y) / 2:
					pos = Vector2(randi_range(650, 750), randi_range(50, 250))
				else:
					pos = Vector2(randi_range(650, 750), randi_range(300, 550))
			
			var actual_index = int(y * PuzzleGlobal.grid_size.x + x)
			piece.init_piece(actual_index, sub_tex, pos, piece_size)
			
			if saved_cell_idx != -1:
				piece.cell_index = saved_cell_idx
				call_deferred("_reoccupy_cell_from_save", saved_cell_idx)
				
			piece_index += 1

func _reoccupy_cell_from_save(cell_idx: int) -> void:
	var cell = PuzzleGlobal.find_cell(cell_idx)
	if cell:
		cell.occupy()
