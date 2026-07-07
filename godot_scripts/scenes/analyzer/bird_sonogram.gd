class_name BirdSonogram
extends Node2D

## Sonograma temporal: grava FFT enquanto o áudio toca e exibe como textura.
## Eixo X = tempo, Eixo Y = frequência (grave → agudo)
##
## Integração com o RadioEmitter:
##   1. Instancie esta cena como filho do RadioEmitter (ou da UI)
##   2. Chame analyze(player) passando o BirdPlayer do emitter
##   3. O sonograma aparece progressivamente enquanto o pássaro canta
##
## Diferença do SpectrumAnalyzer simples:
##   Este guarda o HISTÓRICO completo (tempo × frequência).
##   Ideal como referência visual do canto — o jogador vê o "mapa" antes de reproduzir.

# ── Configuração ───────────────────────────────────────────────────────────────
## Nome do bus de áudio com o AudioEffectSpectrumAnalyzer
@export var bus_name: String = "Radio"

## Quantas bandas de frequência no eixo Y
@export var vu_count: int = 30

## Quantas colunas de tempo no eixo X (resolução temporal)
@export var historic_samples: int = 256

## Frequência máxima analisada (Hz)
@export var freq_max: float = 11050.0

## Sensibilidade em dB (mais alto = mais sensível a sons fracos)
@export var min_db: float = 60.0

## Ganho aplicado à energia capturada
@export var signal_gain: float = 1.5


# ── Estado interno ─────────────────────────────────────────────────────────────
var _spectrum: AudioEffectSpectrumAnalyzerInstance = null
var _audio_player: AudioStreamPlayer2D = null
var _sonogram_image: Image = null
var _sonogram_texture: ImageTexture = null
var _last_written_column: int = -1
var _total_duration: float = 0.0
var _is_analyzing: bool = false

@onready var _color_rect = $"PanelContainer/HBoxContainer/EixoX-Tempo/ColorRect"

# ── API pública ────────────────────────────────────────────────────────────────

## Conecta ao AudioStreamPlayer2D passado e inicia a gravação do sonograma.
## Chame este método quando o pássaro começar a cantar (ex: on_player_entered_sweet_spot).
func analyze(player: AudioStreamPlayer2D) -> void:
	_audio_player = player

	if not player.stream:
		push_warning("[BirdSonogram] AudioStreamPlayer2D não tem stream definido.")
		return

	_total_duration = player.stream.get_length()
	_connect_spectrum()
	_reset_image()
	_is_analyzing = true
	set_process(true)

## Para a gravação (mas mantém a imagem atual visível).
func stop() -> void:
	_is_analyzing = false
	set_process(false)

## Apaga o sonograma e volta ao estado limpo.
func clear() -> void:
	stop()
	_audio_player = null
	_last_written_column = -1
	if _sonogram_image:
		_sonogram_image.fill(Color(0, 0, 0, 1))
		_sonogram_texture.update(_sonogram_image)

# ── Inicialização ──────────────────────────────────────────────────────────────

func _ready() -> void:
	_reset_image()
	set_process(false)  # inativo até analyze() ser chamado

func _connect_spectrum() -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		# Fallback para Master
		bus_idx = 0
		push_warning("[BirdSonogram] Bus '%s' não encontrado, usando Master." % bus_name)

	for i in AudioServer.get_bus_effect_count(bus_idx):
		var effect := AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectSpectrumAnalyzer:
			_spectrum = AudioServer.get_bus_effect_instance(bus_idx, i) \
				as AudioEffectSpectrumAnalyzerInstance
			return

	push_warning(
		"[BirdSonogram] Nenhum AudioEffectSpectrumAnalyzer no bus '%s'.\n" \
		+ "Adicione: aba Audio → %s → Add Effect → SpectrumAnalyzer" % [bus_name, bus_name]
	)

func _reset_image() -> void:
	# X = colunas de tempo, Y = bandas de frequência
	_sonogram_image = Image.create(historic_samples, vu_count, false, Image.FORMAT_RF)
	_sonogram_image.fill(Color(0, 0, 0, 1))
	_sonogram_texture = ImageTexture.create_from_image(_sonogram_image)
	_last_written_column = -1

	if _color_rect and _color_rect.material:
		(_color_rect.material as ShaderMaterial).set_shader_parameter(
			"sonogram_tex", _sonogram_texture
		)

# ── Loop de captura ────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if not _is_analyzing or not _spectrum or not _audio_player:
		return

	if not _audio_player.playing:
		if _audio_player.get_playback_position() == 0.0:
			_last_written_column = -1
		return

	# 1. Calcula coluna X proporcional ao tempo atual de reprodução
	var current_time: float = _audio_player.get_playback_position()
	var time_pct: float = current_time / max(_total_duration, 0.001)
	var col: int = clamp(int(time_pct * historic_samples), 0, historic_samples - 1)

	if col == _last_written_column:
		return
	_last_written_column = col

	# 2. Captura FFT para este instante
	var prev_hz: float = 0.0
	for i in range(1, vu_count + 1):
		var hz: float = float(i) * freq_max / float(vu_count)
		var mag: Vector2 = _spectrum.get_magnitude_for_frequency_range(prev_hz, hz)
		var energy: float = clamp(
			(min_db + linear_to_db(mag.length())) / min_db, 0.0, 1.0
		)
		energy = clamp(energy * signal_gain, 0.0, 1.0)

		# Y invertido: frequências agudas no topo (Y=0), graves na base (Y=max)
		var pixel_y: int = (vu_count - 1) - i + 1
		_sonogram_image.set_pixel(col, pixel_y, Color(energy, energy, energy, 1.0))
		prev_hz = hz

	# 3. Envia textura atualizada para o shader
	_sonogram_texture.update(_sonogram_image)
