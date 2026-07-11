class_name SignalData
extends Resource

## Contrato central entre RadioEmitter, RepertoireMinigame e SignalBook.
## Crie instâncias (.tres) no editor do Godot para cada canto de pássaro.

enum NoiseType { WIND, CARS, WATER, GENERIC }

## Identificador único do sinal (ex: "sabia_mata")
@export var signal_id: String = ""

## Nome exibido na UI (ex: "Canto do Sabiá")
@export var display_name: String = ""

@export var biological_data: Resource
 
@export var puzzle_image: Texture2D

## Áudio do canto real do pássaro (toca no sweet spot)
@export var bird_audio: AudioStream

## ── REPERTOIRE ──────────────────────────────────────────────────────────────
## Sílabas do canto. Cada entrada é um combo de teclas de frequência.
## Ex: [ [1,3], [3,5,2], [1] ]  →  3 sílabas, a 2ª tem 3 notas
@export var syllables: Array[SyllableData] = []

## ── RUÍDO / INTERFERÊNCIA ───────────────────────────────────────────────────
@export var noise_type: NoiseType = NoiseType.GENERIC
@export var noise_sounds: Array[AudioStream] = []
@export var noise_delay: float = 3.0
## ── PROGRESSO DO ESTUDO ─────────────────────────────────────────────────────

## Define quantos encontros com captação são necessários para considerar a ave 100% mapeada.
## Por padrão definimos 3, mas você pode mudar por ave no Inspector (ex: aves raras exigem 5).
@export_range(1, 5) var required_encounters_to_fully_study: int = 3

## Retorna a porcentagem de conclusão do estudo desta ave com base nos encontros atuais.
func get_study_progress_percentage(current_encounters: int) -> float:
	if required_encounters_to_fully_study <= 0:
		return 100.0
	var percentage = (float(current_encounters) / float(required_encounters_to_fully_study)) * 100.0
	return clamp(percentage, 0.0, 100.0)
