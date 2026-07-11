extends Node

## Autoload singleton — adicione em Project > Project Settings > Autoload

## Emitido quando um novo sinal é aprendido
signal signal_learned(signal_data: SignalData)

## Todos os sinais que o jogador já aprendeu
var learned_signals: Array[SignalData] = []

## Verifica se um sinal já foi aprendido
func check_signal(signal_id: String) -> bool:
	for s in learned_signals:
		if s.signal_id == signal_id:
			return true
	return false

## Registra um sinal como aprendido (chamado pelo RepertoireMinigame)
func learn_signal(signal_data: SignalData) -> void:
	if check_signal(signal_data.signal_id):
		return
	learned_signals.append(signal_data)
	signal_learned.emit(signal_data)
	print("[SignalBook] Aprendido: ", signal_data.display_name)

func is_bird_fully_studied(signal_data: SignalData, current_encounters: int) -> bool:
	if not signal_data:
		return false
	return current_encounters >= signal_data.required_encounters_to_fully_study

## Limpa o inventário (útil para testes / novo jogo)
func clear() -> void:
	learned_signals.clear()

## Desbloqueia as sílabas do SignalData baseadas no número de encontros atuais
func unlock_syllables_for_encounter(signal_data: SignalData, encounter_count: int) -> void:
	for syllable in signal_data.syllables:
		# Se a sílaba exigir um encontro menor ou igual ao atual, ela destrava
		if syllable.has_method("get") and "required_encounter" in syllable:
			if syllable.required_encounter <= encounter_count:
				syllable.is_unlocked = true
		else:
			# Se você ainda não configurou a variável required_encounter nela, 
			# por padrão deixamos destravada para não quebrar o jogo
			syllable.is_unlocked = true

func get_unlocked_encyclopedia_data(signal_data: SignalData) -> Dictionary:
	var info = {
		"cientifica": false,
		"biologia": false,
		"distribuicao": false
	}
	
	if not signal_data or not signal_data.biological_data:
		return info
		
	var encontros = GameManager.get_encounter_count(signal_data.signal_id)
	
	# 1º Encontro: Grupo Informações Científicas
	if encontros >= 1:
		info["cientifica"] = true
		
	# 2º Encontro: Dados de Biologia e Habitat
	if encontros >= 2:
		info["biologia"] = true
		
	# 3º Encontro: Distribuição Geográfica e Curiosidades
	if encontros >= 3:
		info["distribuicao"] = true
		
	return info
