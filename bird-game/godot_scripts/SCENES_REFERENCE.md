# Referência de Scenes — Bird Radio

Crie cada scene do zero no Godot e monte a hierarquia exatamente como descrito.
Os nomes dos nós **precisam ser idênticos** (case-sensitive) — são os paths usados
pelos `@onready` em cada script.

---

## 1. RadioEmitter.tscn

**Raiz:** `Node2D` — script: `radio_emitter.gd`

```
RadioEmitter  (Node2D)
├── DetectionArea  (Area2D)          ← nome exato obrigatório
│   └── CollisionShape2D             ← shape: CircleShape2D
├── StaticPlayer   (AudioStreamPlayer2D)
├── NoisePlayer    (AudioStreamPlayer2D)
└── BirdPlayer     (AudioStreamPlayer2D)
```

> **Opcional:** adicione um filho `BirdSonogram (Node2D)` com script `analyzer.gd`
> para ativar o sonograma temporal. O emitter detecta por `has_node("BirdSonogram")`.

---

## 2. SweetSpot.tscn

**Raiz:** `Area2D` — script: `sweet_spot.gd`

```
SweetSpot  (Area2D)
└── CollisionShape2D    ← shape: CircleShape2D
```

> No Inspector, configure `Linked Emitter` apontando para o `RadioEmitter` da cena.
> Habilite **Monitorable** e **Monitoring** na Area2D.

---

## 3. RepertoireMinigame.tscn

**Raiz:** `Control` — script: `repertoire_minigame.gd`
Anchors da raiz: Full Rect (preset 15). Comece com `visible = false`.

```
RepertoireMinigame  (Control)
├── Backdrop    (ColorRect)          ← Full Rect, Color: (0,0,0,0.55) — overlay escuro
└── Panel       (Panel)              ← tipo "Panel", NÃO "PanelContainer"
    ├── TitleBar  (HBoxContainer)    ← nome exato obrigatório
    │   ├── BirdNameLabel  (Label)   ← nome exato obrigatório
    │   └── CloseHint      (Label)   ← nome exato obrigatório
    └── VBox      (VBoxContainer)    ← nome exato obrigatório
        ├── SonogramDisplay  (Control)        ← script: sonogram_display.gd
        │   └── SpectrumVisualizer (ColorRect) ← script: spectrum_visualizer.gd
        │                                         ShaderMaterial → spectrum_analyzer.gdshader
        ├── FreqButtons   (HBoxContainer)     ← nome exato obrigatório (botões criados por código)
        ├── FeedbackLabel (Label)             ← nome exato obrigatório
        └── PhraseProgress (Label)            ← nome exato obrigatório
```

> ⚠️ `Panel` deve ser do tipo **`Panel`** (não `PanelContainer`).
> O `PanelContainer` aceita apenas um filho para layout;
> o script acessa `TitleBar` e `VBox` como filhos diretos de `Panel`.

---

## 4. Analyzer.tscn  *(BirdSonogram — sonograma temporal)*

**Raiz:** `Node2D` — script: `analyzer.gd` (class_name: `BirdSonogram`)

```
BirdSonogram  (Node2D)
└── ColorRect                ← ShaderMaterial → bird_sonogram.gdshader
```

> No Inspector do `BirdSonogram`, o export `Color Rect Path` já aponta para
> `ColorRect` por padrão — não precisa mudar.
> O `ColorRect` precisa ter um `ShaderMaterial` com o shader
> `godot_scripts/scenes/analyzer/bird_sonogram.gdshader`.

---

## 5. SignalHUD  *(HUD de intensidade de sinal)*

**Raiz:** `CanvasLayer` — script: `signal_hud.gd`
Configure `Layer = 1` no CanvasLayer.

```
SignalHUD   (CanvasLayer)
├── SignalBar    (ProgressBar)   ← nome exato obrigatório
├── NoiseLabel   (Label)         ← nome exato obrigatório
└── AntennaIcon  (TextureRect)   ← nome exato obrigatório
```

---

## 6. TestScene.tscn  *(cena de teste)*

**Raiz:** `Node2D` — script: `test_scene.gd`

```
TestScene  (Node2D)
├── RadioEmitter  (Node2D)           ← instância de RadioEmitter.tscn
│                                       ou os nós montados diretamente (ver scene 1)
├── SweetSpot     (Area2D)           ← instância de SweetSpot.tscn
│                                       Inspector: Linked Emitter → RadioEmitter
├── Player        (CharacterBody2D)  ← script: player.gd
│   └── CollisionShape2D             ← shape: CapsuleShape2D ou CircleShape2D
│   [Grupo: "player" obrigatório — Node → Groups → adicionar "player"]
└── RepertoireMinigame  (Control)    ← instância de RepertoireMinigame.tscn
```

---

## Checklist de configuração pós-criação

| O quê | Onde configurar |
|---|---|
| Player no grupo `player` | Selecione Player → aba Node → Groups → `player` |
| `Linked Emitter` do SweetSpot | Inspector do SweetSpot → arraste RadioEmitter |
| `SpectrumAnalyzer` no bus de áudio | Aba Audio (rodapé) → Master bus → Add Effect → SpectrumAnalyzer |
| ShaderMaterial no SpectrumVisualizer | Inspector → Material → ShaderMaterial → Shader → `spectrum_analyzer.gdshader` |
| ShaderMaterial no ColorRect do Analyzer | Inspector → Material → ShaderMaterial → Shader → `bird_sonogram.gdshader` |
| `signal_data` no RadioEmitter | Inspector → Signal Data → arraste um recurso `SignalData` |
