extends Area2D

var index = -1
var cell_index = -1

var dragging = false
var drag_offset = Vector2.ZERO

@onready var sprite2d: Sprite2D = $Sprite2D
@onready var collishape: CollisionShape2D = $CollisionShape2D

func init_piece(_index: int, texture: ImageTexture, pos: Vector2, piece_size: Vector2):
	index = _index
	sprite2d.texture = texture
	position = pos
	collishape.shape.set("size", piece_size)

func _process(_delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position() + drag_offset

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if PuzzleGlobal.is_dragging and not dragging:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if cell_index != -1:
				var cell = PuzzleGlobal.find_cell(cell_index)
				if cell:
					cell.unoccupy()
				cell_index = -1
			dragging = true
			PuzzleGlobal.is_dragging = true
			z_index = 100
			drag_offset = global_position - get_global_mouse_position()
			get_viewport().set_input_as_handled() 

func drop_piece():
	var overlapping_areas = get_overlapping_areas()
	for cell in overlapping_areas:
		if cell.is_in_group("cell"):
			if cell.is_free():
				cell_index = cell.index
				cell.occupy()
				position = cell.global_position
				return

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.is_pressed() and dragging:
			dragging = false
			PuzzleGlobal.is_dragging = false
			z_index = 0
			drop_piece()
			PuzzleGlobal.check_win()
