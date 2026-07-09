class_name SyllableData
extends Resource

## Uma "peça" do repertório do pássaro.
## Cada sílaba é uma sequência de 1–N notas de altura (Pitch).

## As 3 alturas disponíveis para compor o canto.
enum Pitch {
	GRAVE        = 0,  ## tecla Q
	NEUTRO       = 1,  ## tecla W — frequência média
	AGUDO        = 2,  ## tecla E
}

## Rótulo visual exibido no mini-game (ex: \"A\", \"B\", \"X\")
@export var label: String = "A"

## Cor de identificação no UI (opcional, para diferenciar visualmente)
@export var color: Color = Color.CYAN

## Sequência de notas que o jogador deve reproduzir.
@export var frequency_sequence: Array[Pitch] = []


# ── NOVAS VARIÁVEIS PARA O SISTEMA DE PROGRESSÃO ─────────────────────────────

## Em qual encontro (1, 2 ou 3) essa sílaba se torna disponível para estudo?
@export_range(1, 3) var required_encounter: int = 1

## Estado interno que diz se ela já foi desbloqueada pelo especialista
var is_unlocked: bool = false
