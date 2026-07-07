extends Node

## Autoload singleton — adicione em Project > Project Settings > Autoload
## Nome sugerido: "SignalBook"

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

## Verifica se o jogador tem todos os sinais de uma lista (usado pelo GateNode)
func has_all(required_ids: Array[String]) -> bool:
	for id in required_ids:
		if not check_signal(id):
			return false
	return true

## Limpa o inventário (útil para testes / novo jogo)
func clear() -> void:
	learned_signals.clear()
