class_name SignalData
extends Resource

## Contrato central entre RadioEmitter, RepertoireMinigame e SignalBook.
## Crie instâncias (.tres) no editor do Godot para cada canto de pássaro.

enum NoiseType { WIND, CARS, WATER, GENERIC }

## Identificador único do sinal (ex: "sabia_mata")
@export var signal_id: String = ""

## Nome exibido na UI (ex: "Canto do Sabiá")
@export var display_name: String = ""

@export var puzzle_image: Texture2D
## Ícone do pássaro para o inventário (opcional)
@export var bird_icon: Texture2D

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
## ── DESBLOQUEIO ─────────────────────────────────────────────────────────────
## Quantos sinais diferentes são necessários no gate que usa este sinal
## (preenchido pelo GateNode, não aqui)
