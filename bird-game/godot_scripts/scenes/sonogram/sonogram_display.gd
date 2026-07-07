class_name SonogramDisplay
extends Control

## Exibe o canto do pássaro como um sonograma interativo.
## Notas = blocos por frequência (Q=Muito Grave .. T=Muito Agudo)
## Sílabas = grupos com colchetes
## Frase = sequência completa
##
## API:
##   setup(signal_data)         — carrega o canto para exibição
##   mark_note(syl, note, ok)   — marca uma nota como correta/errada
##   set_cursor(syl, note)      — move o cursor de input
##   reset()                    — volta ao estado inicial

# ── Paleta ────────────────────────────────────────────────────────────────────
const C_BG           := Color(0.04, 0.07, 0.10, 0.60)
const C_GRID         := Color(0.12, 0.18, 0.24, 1.00)
const C_FREQ_LABEL   := Color(0.50, 0.75, 1.00, 0.75)
const C_NOTE_IDLE    := Color(0.25, 0.35, 0.55, 0.70)
const C_NOTE_ACTIVE  := Color(0.90, 0.90, 1.00, 1.00)
const C_NOTE_CORRECT := Color(0.20, 0.95, 0.45, 1.00)
const C_NOTE_WRONG   := Color(0.95, 0.25, 0.25, 1.00)
const C_BRACKET      := Color(0.75, 0.80, 1.00, 0.90)
const C_CURSOR_LINE  := Color(1.00, 0.85, 0.10, 0.85)
const C_CURSOR_BG    := Color(1.00, 0.85, 0.10, 0.07)
const C_SCAN_LINE    := Color(0.40, 0.80, 1.00, 0.30)

# ── Layout ────────────────────────────────────────────────────────────────────
const FREQ_COUNT    := 5
const FREQ_LABELS   := ["Q\nM.Grave", "W\nGrave", "E\nNeutro", "R\nAgudo", "T\nM.Agudo"]
const LABEL_COL_W   := 56.0    # largura da coluna de labels à esquerda
const NOTE_W        := 28.0    # largura de uma nota
const NOTE_GAP      := 5.0     # gap entre notas dentro da sílaba
const SYL_GAP       := 22.0    # gap entre sílabas
const BRACKET_H     := 24.0    # altura da área de colchetes no topo
const MARGIN_BOT    := 6.0     # margem inferior

# ── Estado ────────────────────────────────────────────────────────────────────
var _signal_data: SignalData = null
## _states[syl_idx][note_idx] ∈ { "idle", "active", "correct", "wrong" }
var _states: Array = []
var _cursor_syl:  int = 0
var _cursor_note: int = 0

var _scan_x: float = LABEL_COL_W
var _scan_speed: float = 0.0

# ── API pública ───────────────────────────────────────────────────────────────

func setup(data: SignalData) -> void:
	_signal_data = data
	reset()

func reset() -> void:
	_states.clear()
	_cursor_syl  = 0
	_cursor_note = 0
	_scan_x = LABEL_COL_W
	if not _signal_data:
		queue_redraw()
		return
	for syl in _signal_data.syllables:
		var row: Array = []
		for _n in syl.frequency_sequence:
			row.append("idle")
		_states.append(row)
	_update_active_cursor()
	queue_redraw()

func mark_note(syl_idx: int, note_idx: int, correct: bool) -> void:
	if syl_idx >= _states.size():
		return
	if note_idx >= _states[syl_idx].size():
		return
	_states[syl_idx][note_idx] = "correct" if correct else "wrong"
	var next_note := note_idx + 1
	if not correct:
		for i in _states[syl_idx].size():
			_states[syl_idx][i] = "idle"
		next_note = 0
	if next_note >= _states[syl_idx].size():
		_cursor_syl  = syl_idx + 1
		_cursor_note = 0
	else:
		_cursor_syl  = syl_idx
		_cursor_note = next_note
	_update_active_cursor()
	queue_redraw()

func set_cursor(syl_idx: int, note_idx: int) -> void:
	_cursor_syl  = syl_idx
	_cursor_note = note_idx
	_update_active_cursor()
	queue_redraw()

func is_phrase_complete() -> bool:
	for syl_states in _states:
		for s in syl_states:
			if s != "correct":
				return false
	return true

# ── Internos ──────────────────────────────────────────────────────────────────

func _update_active_cursor() -> void:
	for si in _states.size():
		for ni in _states[si].size():
			if _states[si][ni] == "active":
				_states[si][ni] = "idle"
	if _cursor_syl < _states.size() and _cursor_note < _states[_cursor_syl].size():
		if _states[_cursor_syl][_cursor_note] == "idle":
			_states[_cursor_syl][_cursor_note] = "active"

# ── Desenho ───────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _scan_speed > 0.0:
		_scan_x += _scan_speed * delta
		if _scan_x > size.x:
			_scan_x = LABEL_COL_W
		queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y

	draw_rect(Rect2(0.0, 0.0, w, h), C_BG)

	if not _signal_data or _signal_data.syllables.is_empty():
		_draw_empty(w, h)
		return

	var grid_h := h - BRACKET_H - MARGIN_BOT
	var slot_h := grid_h / float(FREQ_COUNT)

	_draw_grid(w, h, grid_h, slot_h)
	_draw_notes_and_brackets(h, grid_h, slot_h)
	_draw_scan_line(h)

func _draw_empty(w: float, h: float) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(w * 0.5 - 80.0, h * 0.5 + 6.0),
		"Sem sinal detectado", HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color(0.35, 0.35, 0.35))

func _draw_grid(w: float, h: float, grid_h: float, slot_h: float) -> void:
	var font := ThemeDB.fallback_font
	for i in FREQ_COUNT:
		var gy := BRACKET_H + float(FREQ_COUNT - 1 - i) * slot_h
		draw_line(Vector2(LABEL_COL_W, gy), Vector2(w, gy), C_GRID, 1.0)
		# Label de frequência (nome curto)
		var short_name = ["M.Grave", "Grave", "Neutro", "Agudo", "M.Agudo"][i]
		draw_string(font, Vector2(4.0, gy + slot_h * 0.68),
			short_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, C_FREQ_LABEL)
	var bottom_y := BRACKET_H + grid_h
	draw_line(Vector2(LABEL_COL_W, bottom_y), Vector2(w, bottom_y), C_GRID, 1.0)
	draw_line(Vector2(LABEL_COL_W, BRACKET_H), Vector2(LABEL_COL_W, bottom_y),
		C_GRID, 1.5)

func _draw_notes_and_brackets(h: float, grid_h: float, slot_h: float) -> void:
	var font  := ThemeDB.fallback_font
	var x     := LABEL_COL_W + 10.0

	for si in _signal_data.syllables.size():
		var syl: SyllableData = _signal_data.syllables[si]
		if syl.frequency_sequence.is_empty():
			continue

		var syl_start_x := x

		for ni in syl.frequency_sequence.size():
			var freq: int = syl.frequency_sequence[ni]
			freq = clamp(freq, 0, FREQ_COUNT - 1)

			# Y: freq 0 (Muito Grave/Q) fica na linha mais baixa, freq 4 (Muito Agudo/T) na mais alta
			var note_y := BRACKET_H + float(FREQ_COUNT - 1 - freq) * slot_h

			var state: String = "idle"
			if si < _states.size() and ni < _states[si].size():
				state = _states[si][ni]

			var col := _note_color(state)
			var rect := Rect2(x, note_y + 3.0, NOTE_W, slot_h - 6.0)

			if state == "active":
				draw_rect(Rect2(x - 2.0, BRACKET_H, NOTE_W + 4.0, grid_h),
					C_CURSOR_BG)
				draw_line(Vector2(x - 2.0, BRACKET_H),
					Vector2(x - 2.0, BRACKET_H + grid_h), C_CURSOR_LINE, 2.0)

			draw_rect(rect, col)

			if state in ["correct", "wrong"]:
				draw_rect(rect.grow(2.0), Color(col, 0.25))

			x += NOTE_W + NOTE_GAP

		var syl_end_x := x - NOTE_GAP

		var bkt_y := BRACKET_H - 14.0
		draw_line(Vector2(syl_start_x, bkt_y + 10.0),
			Vector2(syl_start_x, bkt_y), C_BRACKET, 1.5)
		draw_line(Vector2(syl_start_x, bkt_y),
			Vector2(syl_end_x, bkt_y), C_BRACKET, 1.5)
		draw_line(Vector2(syl_end_x, bkt_y),
			Vector2(syl_end_x, bkt_y + 10.0), C_BRACKET, 1.5)

		if syl.label != "":
			var lx := (syl_start_x + syl_end_x) * 0.5 - 4.0
			draw_string(font, Vector2(lx, bkt_y - 2.0),
				syl.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, C_BRACKET)

		x += SYL_GAP

func _draw_scan_line(h: float) -> void:
	if _scan_speed <= 0.0:
		return
	draw_line(Vector2(_scan_x, BRACKET_H), Vector2(_scan_x, h - MARGIN_BOT),
		C_SCAN_LINE, 2.0)

func _note_color(state: String) -> Color:
	match state:
		"active":  return C_NOTE_ACTIVE
		"correct": return C_NOTE_CORRECT
		"wrong":   return C_NOTE_WRONG
		_:         return C_NOTE_IDLE

func get_required_width() -> float:
	if not _signal_data:
		return 200.0
	var total := LABEL_COL_W + 10.0
	for syl in _signal_data.syllables:
		total += syl.frequency_sequence.size() * (NOTE_W + NOTE_GAP) + SYL_GAP
	return total + 20.0
