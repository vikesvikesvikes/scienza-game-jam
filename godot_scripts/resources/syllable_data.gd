class_name SyllableData
extends Resource

## Uma "peça" do repertório do pássaro.
## Cada sílaba é uma sequência de 1–N notas de altura (Pitch).

## As 5 alturas disponíveis para compor o canto.
## No editor, cada nota do frequency_sequence aparece como dropdown com esses nomes.
enum Pitch {
		GRAVE        = 0,  ## tecla W
		NEUTRO       = 1,  ## tecla E — frequência média
		AGUDO        = 2,  ## tecla R
}

## Rótulo visual exibido no mini-game (ex: "A", "B", "X")
@export var label: String = "A"

## Cor de identificação no UI (opcional, para diferenciar visualmente)
@export var color: Color = Color.CYAN

## Sequência de notas que o jogador deve reproduzir.
## Cada elemento é uma das 5 alturas do enum Pitch acima.
## No Inspector do .tres, cada item aparece como dropdown com os nomes.
## Ex: [MUITO_GRAVE, NEUTRO, AGUDO] = 3 notas, Q → E → R
@export var frequency_sequence: Array[Pitch] = []
