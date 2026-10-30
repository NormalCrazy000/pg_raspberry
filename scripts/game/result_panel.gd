extends Control
# Schermata di fine sfida: vincitore e riepilogo dei punteggi.

const BOX := Rect2(170, 100, 460, 240)

onready var title = $Title
onready var details = $Details


func show_result(title_text: String, lines: Array) -> void:
	title.text = title_text
	details.text = PoolStringArray(lines).join("\n")
	visible = true
	update()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0, 0, 0, 0.45))
	draw_rect(BOX, Color(0.1, 0.11, 0.17, 0.95))
	draw_rect(BOX, Color(0.4, 0.45, 0.6), false, 2.0)
