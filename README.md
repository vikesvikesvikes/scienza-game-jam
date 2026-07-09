# Bird Radio System — Documentação de Integração

Este diretório contém o ecossistema de scripts e cenas em Godot 3 para a mecânica de mapeamento, captação de áudio de aves via rádio amador, progressão por encontros e estudo ornitológico através de minigames.

## Estrutura

```text
.
├── Audio/                           ← Arquivos de áudio originais (.mp3, .ogg)
│   ├── bem-te-vi.mp3
│   ├── quero-quero.mp3
│   ├── tico-tico.mp3
│   ├── cb_radio_static.ogg          ← Ruído estático de rádio base
│   └── Noise/                       ← Sons de interferência urbana/ambiente
│       ├── buzina_bike.mp3
│       └── buzina_trafego.mp3
├── godot_scripts/
│   ├── autoloads/                   ← Singletons Globais (Configurar no Projeto)
│   │   ├── game_manager.gd          ← Gerencia contagem de encontros e dados persistentes
│   │   ├── puzzle_global.gd         ← Gerencia o estado e peças do quebra-cabeça visual
│   │   └── signal_book.gd           ← Inventário global de cantos de aves aprendidos
│   ├── resources/                   ← Contratos e Dados customizados (.tres)
│   │   ├── signal_data.gd           ← Definição estrutural de uma ave
│   │   ├── syllable_data.gd         ← Definição estrutural de uma sílaba/nota
│   │   ├── bem-te-vi.tres           
│   │   ├── quero-quero.tres         
│   │   └── tico-tico.tres           
│   └── scenes/
│       ├── radio_emitter/           ← Emissor de sinal de rádio + áudio no mapa
│       ├── sweet_spot/              ← Ponto limpo onde o canto toca sem estática
│       ├── Player/                  ← Personagem jogável controlador
│       ├── repertoire_minigame/     ← Minigame "Typer" rítmico de digitação (Q, W, E)
│       ├── Puzzles/                 ← Protótipo de quebra-cabeça baseado em mouse
│       │   ├── Cell.tscn            ← Espaço de encaixe (Grid Snap)
│       │   ├── PuzzlePiece.tscn     ← Peça arrastável e rotacionável (Mouse)
│       │   └── PuzzleMain.tscn      ← Canvas/Mesa principal do puzzle visual
│       ├── analyzer/ & sonogram/    ← Componentes visuais do sonograma em tempo real
│       ├── hud/                     ← Barra de intensidade de sinal e antenas
│       └── test/                    ← Cena de testes e sandbox
└── Images/                          
    ├── Test_MapBrasil_v1.png        ← Textura do mapa de exploração
    └── puzzle/                      ← Imagens fatiadas em pedaços para as texturas do puzzle
        └── 1.jpg, 2.jpg, 3.jpg...
```

## 1. Configurar os Autoloads (Singletons)
Vá em Project > Project Settings > Autoload e adicione os três scripts na seguinte ordem de precedência:

- Path: res://godot_scripts/autoloads/game_manager.gd -> Name: GameManager

- Path: res://godot_scripts/autoloads/signal_book.gd -> Name: SignalBook

- Path: res://godot_scripts/autoloads/puzzle_global.gd -> Name: PuzzleGlobal

## 2. Grupo do Player
A cena Player.tscn (ou seu objeto controlado por física) deve obrigatoriamente estar inserido no grupo "player".
(Selecione o nó Raiz do seu jogador -> Aba Node -> sub-aba Groups -> Digite player e clique em Add).

## 3. Setup de Efeitos do Barramento de Áudio (Audio Bus)
Para o sonograma e o analisador funcionarem:

1. Abra a aba Audio localizada no rodapé da engine Godot.

2. No barramento Master (释放 ou em um bus específico criado por você), clique em Add Effect.

3. Adicione o efeito SpectrumAnalyzer. O nome do efeito no slot precisa coincidir com o esperado pelos scripts de renderização.

## 🕹️ Ciclo de Gameplay e Fluxo do Código
Mecânica de Aproximação e Interação (SweetSpot e TestScene)

1. Sinal de Rádio: Conforme o jogador se aproxima de um RadioEmitter, o ruído de estática diminui e o volume do áudio limpo da ave (bird_audio) aumenta gradativamente.

2. Entrada na Área: Ao entrar no círculo interno (SweetSpot), o áudio da ave fica completamente limpo e o script armazena temporariamente a referência da ave na variável radio_atual.

3. Tecla de Interação (E): O minijogo de estudo não abre automaticamente. O jogador precisa estar dentro do SweetSpot e pressionar ativamente l'tecla E do teclado.

## Sistema de Progressão por Encontros e Trava de Sílabas
Cada pássaro possui um recurso contendo uma lista de sílabas (SyllableData). Cada sílaba possui uma propriedade exportada chamada required_encounter (variando de 1 a 3).

- 1º Encontro: O GameManager incrementa a contagem para este ID. O SignalBook libera apenas as sílabas configuradas com peso 1. No minijogo, as sílabas futuras aparecem com uma interrogação cinza (?). Ao tentar avançar nelas, o jogo exibe um aviso de interferência e fecha após 2 segundos.

- 2º Encontro: Libera as sílabas de nível 2. O jogador progride mais na música, mas ainda é barrado antes do final.

- 3º Encontro (Sinal Limpo): Todas as sílabas são totalmente destravadas (is_unlocked = true). O jogador consegue executar a sequência inteira de notas até o fim, adicionando permanentemente o pássaro à lista de conhecidos (SignalBook.learn_signal).

## 🧩 Mecânica Complementar: Quebra-Cabeça Visual (Puzzles/)
A pasta scenes/Puzzles/ abriga o desenvolvimento para o minijogo complementar onde o especialista une os fragmentos coletados para concluir seus estudos:

- puzzle_piece.gd: Controla peças físicas do canvas usando detecção de clique do mouse. Implementa mecânica de Arrastar (seguindo o mouse) e Rotacionar em 90° ao pressionar o botão direito do mouse (rotation_degrees += 90).

- cell.gd: Define células fixas de gabarito que utilizam cálculo de proximidade física para puxar a peça à sua coordenada exata (Grid Snap) caso a peça solta esteja dentro da distância de tolerância.

- Performance Otimizada: Utiliza o sistema de Region bidimensional do Sprite2D permitindo carregar apenas uma imagem unificada de paisagem na memória e renderizar múltiplos fragmentos/ladrilhos cortados de forma leve e otimizada em tempo de execução.igame.gd`.
