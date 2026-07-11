extends Area2D

var index = -1
var occupied = false

@onready var sprite2d: Sprite2D = $Sprite2D
@onready var collishape: CollisionShape2D = $CollisionShape2D

func init_cell(_index: int, piece_size: Vector2):
	index = _index
	
	# Obtém o tamanho nativo em pixels da imagem usada como célula
	var texture_size = sprite2d.texture.get_size()
	
	# Define a escala dividindo o tamanho alvo pelo tamanho real da textura
	sprite2d.scale = Vector2(piece_size.x / texture_size.x, piece_size.y / texture_size.y)
	
	# Atualiza o collider (o CollisionShape2D aceita o tamanho bruto perfeitamente)
	if collishape and collishape.shape:
		collishape.shape.size = piece_size

func is_free():
	return not occupied

func occupy():
	occupied = true

func unoccupy():
	occupied = false
