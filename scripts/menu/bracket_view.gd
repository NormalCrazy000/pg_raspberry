extends Control
# Disegno del tabellone del torneo: una colonna per turno, una casella per partita con i due nomi e i punti,
# linee verso la partita successiva. La prossima partita da giocare è evidenziata.

const Bracket := preload("res://scripts/tournament/bracket.gd")
const Characters := preload("res://scripts/game/characters.gd")
const Scoring := preload("res://scripts/game/scoring.gd")
const ROW_H := 20.0
const BOX_MARGIN := 14.0
const COLOR_BOX := Color(0.1, 0.11, 0.17, 0.92)
const COLOR_BORDER := Color(0.3, 0.34, 0.46)
const COLOR_NEXT := Color(1.0, 0.85, 0.3)
const COLOR_LINE := Color(0.3, 0.34, 0.46)
const COLOR_TEXT := Color(0.85, 0.88, 0.95)
const COLOR_DIM := Color(0.5, 0.53, 0.62)
const LOSER_ALPHA := 0.45

var data := {}
var next := [] # [turno, partita] da evidenziare
var colors := {} # id personaggio -> colore


func _ready() -> void:
	for character in Characters.load_all():
		colors[character.id] = Color(character.color)


func show_bracket(bracket: Dictionary, next_match: Array) -> void:
	data = bracket
	next = next_match
	update()


func _column_width() -> float:
	return rect_size.x / data.rounds.size()


func _box(round_index: int, match_index: int) -> Rect2:
	var count: int = data.rounds[round_index].size()
	var slot := (rect_size.y - 24.0) / count
	var center := Vector2(_column_width() * (round_index + 0.5), 24.0 + slot * (match_index + 0.5))
	var size := Vector2(_column_width() - BOX_MARGIN * 2.0, ROW_H * 2.0)
	return Rect2(center - size / 2.0, size)


func _draw() -> void:
	if data.empty():
		return
	var font := get_font("font", "Label")
	for r in data.rounds.size():
		var title: String = tr(Bracket.round_key(data, r))
		var x: float = _column_width() * (r + 0.5) - font.get_string_size(title).x / 2.0
		draw_string(font, Vector2(x, 14), title, COLOR_DIM)
	for r in data.rounds.size():
		for i in data.rounds[r].size():
			var box := _box(r, i)
			if r + 1 < data.rounds.size():
				var target := _box(r + 1, i / 2)
				var from := Vector2(box.end.x, box.position.y + box.size.y / 2.0)
				var to := Vector2(target.position.x, target.position.y + target.size.y / 2.0)
				var mid_x := (from.x + to.x) / 2.0
				draw_polyline(PoolVector2Array([from, Vector2(mid_x, from.y), Vector2(mid_x, to.y), to]), COLOR_LINE, 1.5)
			_draw_match(font, box, data.rounds[r][i], next == [r, i])


func _draw_match(font: Font, box: Rect2, m: Dictionary, highlighted: bool) -> void:
	draw_rect(box, COLOR_BOX)
	draw_rect(box, COLOR_NEXT if highlighted else COLOR_BORDER, false, 2.0 if highlighted else 1.0)
	var decided: bool = int(m.winner) >= 0 and m.decided_by != "bye"
	for slot in 2:
		var index: int = int(m.a) if slot == 0 else int(m.b)
		var top: float = box.position.y + ROW_H * slot
		var baseline := top + ROW_H / 2.0 + font.get_ascent() / 2.0 - 1.0
		var text_x := box.position.x + 14.0
		if index == Bracket.BYE:
			draw_string(font, Vector2(text_x, baseline), tr("BRACKET_BYE"), COLOR_DIM)
			continue
		if index == Bracket.EMPTY:
			draw_string(font, Vector2(text_x, baseline), "...", COLOR_DIM)
			continue
		var p: Dictionary = data.participants[index]
		var alpha: float = LOSER_ALPHA if decided and int(m.winner) != index else 1.0
		var color: Color = colors.get(p.character, COLOR_TEXT)
		draw_rect(Rect2(box.position.x + 5.0, top + 6.0, 4.0, ROW_H - 12.0), Color(color.r, color.g, color.b, alpha))
		draw_string(font, Vector2(text_x, baseline), p.name, Color(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, alpha))
		if decided:
			var score := Scoring.format(int(m.scores[slot]))
			var width := font.get_string_size(score).x
			draw_string(font, Vector2(box.end.x - width - 8.0, baseline), score, Color(COLOR_DIM.r, COLOR_DIM.g, COLOR_DIM.b, alpha))
	draw_line(Vector2(box.position.x + 4.0, box.position.y + ROW_H), Vector2(box.end.x - 4.0, box.position.y + ROW_H), COLOR_BORDER)
