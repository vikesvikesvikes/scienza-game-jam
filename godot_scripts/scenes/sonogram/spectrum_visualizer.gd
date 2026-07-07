class_name SpectrumVisualizer
extends ColorRect

## Lê dados reais de frequência do AudioServer e alimenta o shader de espectro.
##
## Pré-requisito no editor:
##   Audio (aba inferior) → Master bus → Add Effect → SpectrumAnalyzer
##   (ou qualquer outro bus definido em `bus_name`)
##
## Este nó deve ser filho do SonogramDisplay (ou qualquer Control).
## O shader spectrum_analyzer.gdshader deve estar no material deste ColorRect.

## Nome do bus de áudio com o efeito SpectrumAnalyzer
@export var bus_name: String = "Master"

## Número de bandas de frequência — deve bater com VU_COUNT no shader
@export var vu_count: int = 30

## Frequência máxima analisada (Hz) — 11050 = Nyquist para 22kHz
@export var freq_max: float = 11050.0

## Mínimo em dB para normalização (quanto mais alto, mais sensível)
@export var min_db: float = 60.0

## Velocidade de animação: quão rápido as barras sobem/descem
@export var animation_speed: float = 0.15

## Escala de altura das barras (1.0 = normalizado ao tamanho do nó)
@export var height_scale: float = 1.0

var _spectrum: AudioEffectSpectrumAnalyzerInstance = null
var _min_values: PackedFloat32Array
var _max_values: PackedFloat32Array
var _freq_data:  PackedFloat32Array

func _ready() -> void:
	_min_values.resize(vu_count)
	_max_values.resize(vu_count)
	_freq_data.resize(vu_count)

	_connect_spectrum()

func _connect_spectrum() -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_warning("[SpectrumVisualizer] Bus '%s' não encontrado." % bus_name)
		return

	for i in AudioServer.get_bus_effect_count(bus_idx):
		var effect := AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectSpectrumAnalyzer:
			_spectrum = AudioServer.get_bus_effect_instance(bus_idx, i) \
				as AudioEffectSpectrumAnalyzerInstance
			return

	push_warning(
		"[SpectrumVisualizer] Nenhum AudioEffectSpectrumAnalyzer encontrado no bus '%s'. Adicione o efeito em: aba Audio → %s bus → Add Effect → SpectrumAnalyzer" % [bus_name, bus_name])

func _process(delta: float) -> void:
	if not _spectrum:
		return

	var prev_hz := 0.0
	for i in vu_count:
		var hz := (float(i) + 1.0) * freq_max / float(vu_count)
		var mag: Vector2 = _spectrum.get_magnitude_for_frequency_range(prev_hz, hz)
		var energy :float = clamp((min_db + linear_to_db(mag.length())) / min_db, 0.0, 1.0)
		_freq_data[i] = energy * height_scale
		prev_hz = hz

	# Suavização: máximos caem devagar, mínimos sobem devagar
	for i in vu_count:
		if _freq_data[i] > _max_values[i]:
			_max_values[i] = _freq_data[i]
		else:
			_max_values[i] = lerpf(_max_values[i], _freq_data[i], animation_speed)

		if _freq_data[i] <= 0.0:
			_min_values[i] = lerpf(_min_values[i], 0.0, animation_speed)

	# Array final enviado ao shader
	var shader_data := PackedFloat32Array()
	shader_data.resize(vu_count)
	for i in vu_count:
		shader_data[i] = lerpf(_min_values[i], _max_values[i], animation_speed)

	if material:
		(material as ShaderMaterial).set_shader_parameter("freq_data", shader_data)

## Liga/desliga a visualização sem destruir o nó
func set_active(active: bool) -> void:
	set_process(active)
	visible = active
