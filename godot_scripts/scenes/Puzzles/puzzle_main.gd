extends Node2D

@onready var cells = $Cells
@onready var cell_scene = preload("res://godot_scripts/scenes/Puzzles/Cell.tscn")

@onready var pieces = $Pieces
@onready var piece_scene = preload("res://godot_scripts/scenes/Puzzles/PuzzlePiece.tscn")

var piece_size: Vector2 = Vector2(100,100)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_game()


func init_game():
	generate_pieces()
	draw_cells()
	
func draw_cells():
	for i in range(PuzzleGlobal.grid_size.x):
		for j in range(PuzzleGlobal.grid_size.y):
			add_cell(i,j)
			


func add_cell(i,j):
	var cell = cell_scene.instantiate()
	cells.add_child(cell)
	PuzzleGlobal.cells.append(cell)
	cell.position = Vector2(
		int(piece_size.x) * i,
		int(piece_size.y) * j
	)
	var idx=int(i*PuzzleGlobal.grid_size.x) +j
	cell.init_cell(idx,piece_size)


func generate_pieces():
	randomize()
	var image = PuzzleGlobal.get_image()
	var texture = ImageTexture.create_from_image(image)
	piece_size = Vector2(
		texture.get_width() / PuzzleGlobal.grid_size.x,
		texture.get_height() / PuzzleGlobal.grid_size.y,
	)
	for i in range(PuzzleGlobal.grid_size.x):
		for j in range(PuzzleGlobal.grid_size.y):
			var piece = piece_scene.instantiate()
			pieces.add_child(piece)
			PuzzleGlobal.pieces.append(piece)
			
			#seleciona a região da imagem
			var region = Rect2(i * piece_size.x, j * piece_size.y,piece_size.x,piece_size.y)
			var sub_image = image.get_region(Rect2i(region.position,region.size))
			var sub_tex = ImageTexture.create_from_image(sub_image)
			var pos 
			var index = int(i*PuzzleGlobal.grid_size.x + j)
			if index < (PuzzleGlobal.grid_size.x * PuzzleGlobal.grid_size.y) / 2:
				pos = Vector2(randi_range(100, 200),randi_range(400, 700))
			else:
				pos = Vector2(randi_range(700, 900),randi_range(200, 800))
			piece.init_piece(index, sub_tex, pos, piece_size)
