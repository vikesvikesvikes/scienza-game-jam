# Scripts Godot — Sistema de Rádio / Sonograma

Copie a pasta `godot_scripts/` para dentro do seu projeto Godot e ajuste os caminhos conforme necessário.

## Estrutura

```
godot_scripts/
├── resources/
│   ├── signal_data.gd        ← Resource principal (crie .tres no editor)
│   └── syllable_data.gd      ← Uma "sílaba" / peça do repertório
├── autoloads/
│   └── signal_book.gd        ← Singleton (Project > Autoload > "SignalBook")
└── scenes/
    ├── radio_emitter/
    │   └── radio_emitter.gd  ← Node2D no mapa que emite ruído + canto
    ├── sweet_spot/
    │   └── sweet_spot.gd     ← Area2D circular onde o sinal fica limpo
    ├── repertoire_minigame/
    │   └── repertoire_minigame.gd ← Mini-game principal (Control + CanvasLayer)
    ├── gate_node/
    │   └── gate_node.gd      ← Porta que destrava com sinais aprendidos
    └── hud/
        └── signal_hud.gd     ← HUD de intensidade (UI 1 — busca do sinal)
```

## Setup rápido (ordem)

### 1. Autoload
`Project > Project Settings > Autoload`
- Path: `res://autoloads/signal_book.gd`
- Name: `SignalBook`

### 2. Criar um SignalData (.tres)
No FileSystem, clique com botão direito > `New Resource` > `SignalData`
Preencha no Inspector:
- `signal_id`: `"sabia_1"`
- `display_name`: `"Canto do Sabiá"`
- `bird_audio`: seu arquivo .ogg
- `noise_type`: `WIND`
- `noise_sounds`: array com seus sons de vento
- `syllables`: array de SyllableData (cada uma com `label` e `frequency_sequence`)

**Exemplo de syllables para um canto simples:**
```
Syllable A: frequency_sequence = [0, 2]       (Q, E)
Syllable B: frequency_sequence = [3, 3, 5]    (R, R, Y)
Syllable C: frequency_sequence = [1]           (W)
→ Combo completo: Q E | R R Y | W
```

### 3. Cena RadioEmitter
Estrutura do Node:
```
RadioEmitter (Node2D) ← radio_emitter.gd
├── Sprite2D              ← visual do rádio
├── DetectionArea (Area2D)
│   └── CollisionShape2D  ← CircleShape2D, ajuste o raio
├── StaticPlayer (AudioStreamPlayer2D)  ← estática contínua
├── NoisePlayer (AudioStreamPlayer2D)   ← ruídos de ambiente
└── BirdPlayer (AudioStreamPlayer2D)    ← canto do pássaro
```
Atribua o `SignalData` no Inspector.

### 4. Cena SweetSpot
```
SweetSpot (Area2D) ← sweet_spot.gd
└── CollisionShape2D ← CircleShape2D menor que o RadioEmitter
```
No Inspector, aponte `linked_emitter` para o RadioEmitter correspondente.

### 5. Cena RepertoireMinigame
```
CanvasLayer (layer: 10)
└── RepertoireMinigame (Control, full rect) ← repertoire_minigame.gd
    ├── BirdNameLabel (Label)
    ├── SonogramDisplay (Control)    ← desenhe o sonograma aqui
    ├── SyllableSlots (HBoxContainer) ← slots gerados dinamicamente
    ├── FreqButtons (HBoxContainer)  ← 6 botões Q W E R T Y gerados
    ├── FeedbackLabel (Label)
    └── CloseHint (Label)
```

### 6. Conectar SweetSpot → RepertoireMinigame
No seu GameManager ou Player:
```gdscript
sweet_spot.player_entered_sweetspot.connect(
    func(emitter): repertoire_minigame.open(emitter.signal_data)
)
sweet_spot.player_exited_sweetspot.connect(repertoire_minigame.close)
```

### 7. GateNode
```
GateNode (Node2D) ← gate_node.gd
├── Sprite2D (porta)
└── AnimationPlayer ← animação "open"
```
No Inspector, adicione os `required_signal_ids` (ex: `["sabia_1", "coruja_1"]`).

## Teclas padrão (Q W E R T Y)
| Tecla | Índice | Frequência sugerida |
|-------|--------|-------------------|
| Q     | 0      | Grave (mais baixo) |
| W     | 1      | |
| E     | 2      | |
| R     | 3      | |
| T     | 4      | |
| Y     | 5      | Agudo (mais alto) |

Para mudar as teclas, edite `FREQ_KEYS` em `repertoire_minigame.gd`.
