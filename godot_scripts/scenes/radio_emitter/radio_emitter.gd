class_name RadioEmitter
extends Node2D

## Coloque num Node2D no mapa. Adicione um Sprite2D do rádio como filho.
## Filho obrigatório: Area2D (com CollisionShape2D circular) nomeado "DetectionArea"
## Filhos de áudio: AudioStreamPlayer2D nomeados "StaticPlayer" e "NoisePlayer" e "BirdPlayer"

@export var signal_data: SignalData

## Intervalo (segundos) entre cada emissão do canto do pássaro
@export var bird_call_interval: float = 8.0

## Intervalo entre ruídos de ambiente
@export var noise_interval: float = 4.0

## Volume base da estática (dB). Aumenta com a distância do player.
@export var static_volume_db: float = -10.0

## Arquivo de áudio para o ruído estático (ex: cb_radio_static.ogg).
## Se vazio, gera ruído branco proceduralmente.
@export var static_audio: AudioStream

## Frequência central do chirp do pássaro (Hz). Usada apenas se bird_audio não for definido.
@export var bird_chirp_freq: float = 1800.0

@onready var detection_area: Area2D = $DetectionArea
@onready var static_player: AudioStreamPlayer2D = $StaticPlayer
@onready var noise_player: AudioStreamPlayer2D = $NoisePlayer
@onready var bird_player: AudioStreamPlayer2D = $BirdPlayer

## Referência opcional ao BirdSonogram filho.
## Se presente, é ativado automaticamente quando o pássaro canta.
@onready var bird_sonogram: BirdSonogram = $BirdSonogram if has_node("BirdSonogram") else null

var _player_ref: Node2D = null
var _in_sweet_spot: bool = false
var _bird_timer: float = 0.0
var _noise_timer: float = 0.0

# Áudio procedural — estática
var _static_playback: AudioStreamGeneratorPlayback = null
var _static_volume: float = 0.0  # 0.0 = mudo, 1.0 = pleno

# Áudio procedural — pássaro (chirp sintético)
var _bird_playback: AudioStreamGeneratorPlayback = null
var _bird_phase: float = 0.0
var _bird_chirp_time: float = 0.0
var _bird_chirp_duration: float = 1.2  # segundos de chirp
var _bird_chirping: bool = false
const _SAMPLE_RATE: float = 22050.0

func _ready() -> void:
		detection_area.body_entered.connect(_on_body_entered)
		detection_area.body_exited.connect(_on_body_exited)

		_setup_static_audio()
		_setup_bird_audio()

# ── Configuração do áudio procedural ──────────────────────────────────────────

func _setup_static_audio() -> void:
		if static_audio:
				# Usa o arquivo de estática real (ex: cb_radio_static.ogg)
				static_player.stream = static_audio
				static_player.volume_db = -80.0  # começa mudo; sobe conforme distância
				static_player.play()
				return

		# Geração procedural de ruído branco
		var gen := AudioStreamGenerator.new()
		gen.mix_rate = _SAMPLE_RATE
		gen.buffer_length = 0.15
		static_player.stream = gen
		static_player.play()
		_static_playback = static_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _setup_bird_audio() -> void:
		if signal_data and signal_data.bird_audio:
				# Usa o arquivo real de pássaro — não gera sinteticamente
				bird_player.stream = signal_data.bird_audio
				return

		var gen := AudioStreamGenerator.new()
		gen.mix_rate = _SAMPLE_RATE
		gen.buffer_length = 0.15
		bird_player.stream = gen
		bird_player.play()
		_bird_playback = bird_player.get_stream_playback() as AudioStreamGeneratorPlayback

# ── Loop principal ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
		_fill_static_buffer()
		_fill_bird_buffer(delta)

		if _in_sweet_spot:
				_process_sweet_spot(delta)
		else:
				_process_outside(delta)

func _process_outside(delta: float) -> void:
		_bird_timer = 0.0  # reseta timer do pássaro enquanto fora

		_noise_timer += delta
		if _noise_timer >= noise_interval:
				_noise_timer = 0.0
				_play_noise()

		# Volume da estática: maior quando mais próximo; zero quando fora do range
		if _player_ref:
				var dist: float = global_position.distance_to(_player_ref.global_position)
				var shape: CollisionShape2D = detection_area.get_node("CollisionShape2D")
				var max_range: float = (shape.shape as CircleShape2D).radius
				var intensity: float = clamp(1.0 - dist / max_range, 0.0, 1.0)
				_static_volume = intensity
				if _static_playback == null:
						static_player.volume_db = lerp(-40.0, static_volume_db, intensity)
		else:
				_static_volume = 0.0
				if _static_playback == null:
						static_player.volume_db = -80.0

func _process_sweet_spot(delta: float) -> void:
		_static_volume = 0.0  # silencia a estática dentro do sweet spot

		_bird_timer += delta
		if _bird_timer >= bird_call_interval:
				_bird_timer = 0.0
				_trigger_bird_call()

# ── Geração procedural — buffer de estática ────────────────────────────────────

func _fill_static_buffer() -> void:
	if _static_playback == null:
		return
	var available: int = _static_playback.get_frames_available()
	
	# Converte o volume máximo de dB para escala linear (ex: -10dB vira ~0.316)
	var max_linear_volume: float = db_to_linear(static_volume_db)
	
	for _i in available:
		# Multiplica o ruído pela intensidade da distância e pelo limite linear de volume
		var noise: float = randf_range(-1.0, 1.0) * _static_volume * max_linear_volume
		_static_playback.push_frame(Vector2(noise, noise))
# ── Geração procedural — chirp do pássaro ─────────────────────────────────────

func _fill_bird_buffer(delta: float) -> void:
		if _bird_playback == null:
				return

		var available: int = _bird_playback.get_frames_available()
		if available == 0:
				return

		if not _bird_chirping:
				# Silêncio: empurra zeros para manter o buffer ativo
				for _i in available:
						_bird_playback.push_frame(Vector2.ZERO)
				return

		_bird_chirp_time += delta
		var t_norm: float = _bird_chirp_time / _bird_chirp_duration

		if t_norm >= 1.0:
				_bird_chirping = false
				_bird_chirp_time = 0.0
				for _i in available:
						_bird_playback.push_frame(Vector2.ZERO)
				return

		# Envelope: ataque rápido, decay suave
		var envelope: float = sin(t_norm * PI)

		# Frequência com vibrato ascendente para soar como pássaro
		var freq: float = bird_chirp_freq + sin(t_norm * PI * 8.0) * 200.0 + t_norm * 400.0

		var dt: float = 1.0 / _SAMPLE_RATE
		for _i in available:
				_bird_phase += freq * dt * TAU
				if _bird_phase > TAU:
						_bird_phase -= TAU
				var sample: float = sin(_bird_phase) * envelope * 0.5
				_bird_playback.push_frame(Vector2(sample, sample))

# ── Disparadores de som ────────────────────────────────────────────────────────

func _trigger_bird_call() -> void:
	if signal_data and signal_data.bird_audio:
		# 1. Inicia o áudio do pássaro totalmente limpo
		bird_player.play()
		
		# Ativa o sonograma se estiver presente
		if bird_sonogram:
			bird_sonogram.analyze(bird_player)
			
		# 2. Agenda o início do ruído com base no atraso definido no recurso (signal_data)
		var delay = signal_data.get("noise_delay") if "noise_delay" in signal_data else 3.0
		
		# Cria um timer seguro na SceneTree; se o player sair do SweetSpot ou o nó morrer, 
		# a checagem 'is_inside_tree()' impede ruídos fantasmas
		await get_tree().create_timer(delay).timeout
		if is_inside_tree() and _in_sweet_spot and bird_player.playing:
			_play_noise()
	else:
		# Comportamento alternativo para chirp sintético
		_bird_chirping = true
		_bird_chirp_time = 0.0
		_bird_phase = 0.0

func _play_noise() -> void:
		if signal_data and signal_data.noise_sounds.size() > 0:
				var pick: AudioStream = signal_data.noise_sounds[randi() % signal_data.noise_sounds.size()]
				noise_player.stream = pick
				noise_player.play()

# ── Detecção de área ───────────────────────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
		if body.is_in_group("player"):
				_player_ref = body

func _on_body_exited(body: Node2D) -> void:
		if body == _player_ref:
				_player_ref = null
				_static_volume = 0.0
				if _static_playback == null:
						static_player.volume_db = -80.0

# ── API para o SweetSpot ───────────────────────────────────────────────────────

## Chamado pelo SweetSpot quando o player entra
func on_player_entered_sweet_spot() -> void:
		_in_sweet_spot = true
		_bird_timer = 0.0
		_trigger_bird_call()  # toca imediatamente ao entrar

## Chamado pelo SweetSpot quando o player sai
func on_player_exited_sweet_spot() -> void:
		_in_sweet_spot = false
		_bird_chirping = false
		_bird_timer = 0.0
