extends Node
var cells = []
var pieces = []

var is_dragging = false # evita arrastar 2 imagens 
const images = [
	"res://Images/puzzle/1.png"
]


enum DIFFICULTY {
	EASY,
	MEDIUM,
	HARD
}

const DIFFICULTY_VALUES = {
	DIFFICULTY.EASY: 3,
	DIFFICULTY.MEDIUM: 4,
	DIFFICULTY.HARD: 5
}

var chosen_difficulty = DIFFICULTY.EASY

var grid_size = Vector2i(
	DIFFICULTY_VALUES[chosen_difficulty],
	DIFFICULTY_VALUES[chosen_difficulty]
	)

func get_image() -> Image:
	# 1. Carrega o arquivo como uma textura nativa da Godot (funciona pós-exportação)
	var texture = load(images.pick_random()) as Texture2D
	
	if texture:
		# 2. Extrai e retorna a Image de dentro da textura
		return texture.get_image()
		
	return null

func find_cell(index: InternalMode):
	for cell in cells:
		if cell.index == index:
			return cell

func check_win():
	for piece in pieces:
		if piece.index != piece.cell_index:
			return
	print("Yeeeah!!")
