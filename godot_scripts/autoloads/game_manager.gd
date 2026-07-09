extends Node

# Armazena quantas vezes o jogador encontrou cada ave neste nível
# Exemplo: {"bem-te-vi": 1, "quero-quero": 3}
var bird_encounter_counts: Dictionary = {}

## Centraliza a troca de telas
func change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

## Registra que encontrou a ave e retorna o novo número de encontros
func register_encounter(signal_id: String) -> int:
	if not bird_encounter_counts.has(signal_id):
		bird_encounter_counts[signal_id] = 0
	
	bird_encounter_counts[signal_id] += 1
	return bird_encounter_counts[signal_id]

func get_encounter_count(signal_id: String) -> int:
	return bird_encounter_counts.get(signal_id, 0)
