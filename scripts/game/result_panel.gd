extends Control
# Schermata di fine livello: esito, stelle e riepilogo del punteggio.

const BOX := Rect2(200, 90, 400, 220)
const STAR_Y := 185.0
const STAR_SPACING := 75.0
const STAR_RADIUS := 26.0
const STAR_ON := Color(1.0, 0.85, 0.3)
const STAR_OFF := Color(0.25, 0.27, 0.35)

var won := false
var stars := 0
var stars_shown := 0

onready var title = $Title
onready var details = $Details


func show_result(level_won: bool, star_count: int, lines: Array) -> void:
	won = level_won
	stars = star_count
	stars_shown = 0
	title.text = "Release completata!" if won else "Paperelle finite: release rimandata"
	lines.append("")
	lines.append("Tocca o premi A per ricominciare")
	details.text = PoolStringArray(lines).join("\n")
	visible = true
	update()
	if won:
		# Le stelle compaiono una alla volta.
		var tween := create_tween()
		for i in stars:
			tween.tween_interval(0.35)
			tween.tween_callback(self, "_show_next_star")


func _show_next_star() -> void:
	stars_shown += 1
	update()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0, 0, 0, 0.45))
	draw_rect(BOX, Color(0.1, 0.11, 0.17, 0.95))
	draw_rect(BOX, Color(0.4, 0.45, 0.6), false, 2.0)
	if not won:
		return
	for i in 3:
		var center := Vector2(rect_size.x / 2.0 + (i - 1) * STAR_SPACING, STAR_Y)
		_draw_star(center, STAR_RADIUS, STAR_ON if i < stars_shown else STAR_OFF)


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PoolVector2Array()
	for i in 10:
		var r: float = radius if i % 2 == 0 else radius * 0.45
		var angle: float = -PI / 2.0 + i * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color)
