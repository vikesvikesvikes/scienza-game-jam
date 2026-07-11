extends Node

# Armazena quantas vezes o jogador encontrou cada ave neste nível
# Exemplo: {"bem-te-vi": 1, "quero-quero": 3}
var bird_encounter_counts: Dictionary = {}

func set_player_input_blocked(blocked: bool) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
		
	# Busca o jogador pelo grupo ou pelo nó (usando o grupo 'player' conforme seu README)
	var player = tree.get_first_node_in_group("player")
	
	# Se não achar por grupo, tenta um fallback direto pelo nome comum na cena ativa
	if not player:
		player = tree.current_scene.get_node_or_null("CharacterBody2D")
		
	# 1ª Validação: Só altera se o jogador realmente existir na cena atual
	if player and is_instance_valid(player):
		if blocked:
			player.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			player.process_mode = Node.PROCESS_MODE_INHERIT


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
