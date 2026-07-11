extends Node

var cells = []
var pieces = []

var is_dragging = false # evita arrastar 2 imagens 

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

var chosen_difficulty = DIFFICULTY.MEDIUM

var grid_size = Vector2i(
	DIFFICULTY_VALUES[chosen_difficulty],
	DIFFICULTY_VALUES[chosen_difficulty]
)

# Estrutura: {"id_da_ave": [{"position": Vector2, "cell_index": int}, ...]}
var saved_puzzle_states: Dictionary = {}
var _current_bird_image: Image = null

func set_current_bird_image(img: Image) -> void:
	_current_bird_image = img

func get_image() -> Image:
	if _current_bird_image:
		if _current_bird_image.get_size() != Vector2i(800, 800):
			_current_bird_image.resize(800, 800, Image.INTERPOLATE_LANCZOS)
		return _current_bird_image
		
	print("[PuzzleGlobal] Alerta: Nenhuma imagem de ave definida. Retornando imagem padrão vazia.")
	return Image.create(800, 800, false, Image.FORMAT_RGBA8)

func preparar_imagem_da_ave(signal_data: SignalData) -> void:
	if not signal_data or not signal_data.bird_icon:
		return
		
	var img = signal_data.bird_icon.get_image()
	img.resize(800, 800, Image.INTERPOLATE_LANCZOS)
	
	set_current_bird_image(img)

func clear_runtime_data() -> void:
	cells.clear()
	pieces.clear()
	is_dragging = false

func save_bird_puzzle(bird_id: String) -> void:
	if bird_id.is_empty():
		return
	
	var pieces_data: Array = []
	for piece in pieces:
		if is_instance_valid(piece):
			pieces_data.append({
				"position": piece.global_position,
				"cell_index": piece.cell_index
			})
	
	saved_puzzle_states[bird_id] = pieces_data

func get_saved_bird_puzzle(bird_id: String) -> Array:
	return saved_puzzle_states.get(bird_id, [])

func find_cell(index: int):
	for cell in cells:
		if cell.index == index:
			return cell
	return null

func check_win():
	for piece in pieces:
		if piece.index != piece.cell_index:
			return
	print("Yeeeah!! Quebra-cabeça concluído!")
	

func get_available_pieces_count(signal_id: String) -> int:
	var encontros = GameManager.get_encounter_count(signal_id)
	var total_pecas = pieces.size()
	
	if encontros <= 0:
		return 0
	elif encontros == 1:
		return int(total_pecas * 0.33) # Libera os primeiros 33% dos fragmentos
	elif encontros == 2:
		return int(total_pecas * 0.66) # Libera até 66% das peças
	else:
		return total_pecas # Sinal limpo (3+ encontros): Libera o quebra-cabeça inteiro!
