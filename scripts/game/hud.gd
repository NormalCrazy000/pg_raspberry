extends CanvasLayer
# HUD della sfida: i due giocatori ai lati, bug rimasti e moltiplicatore ai lati del cannone,
# messaggi a comparsa e schermata finale.

const Scoring := preload("res://scripts/game/scoring.gd")
const INACTIVE_ALPHA := 0.45

var flash_tween: SceneTreeTween

onready var panels := [
	[$P1Name, $P1Score, $P1Info],
	[$P2Name, $P2Score, $P2Info],
]
onready var targets_label = $TargetsLabel
onready var multiplier_label = $MultiplierLabel
onready var message = $Message
onready var result_panel = $ResultPanel


func update_players(players: Array, current: int) -> void:
	for i in panels.size():
		var labels: Array = panels[i]
		for label in labels:
			label.visible = i < players.size()
		if i >= players.size():
			continue
		var player = players[i]
		var turn_mark := "» " if i == current else ""
		labels[0].text = turn_mark + player.label() if i == 0 else player.label() + (" «" if i == current else "")
		labels[0].add_color_override("font_color", Color(player.character.color))
		labels[1].text = Scoring.format(player.score)
		var status: String = player.power.status_text()
		labels[2].text = "Paperelle %d%s" % [player.balls_left, " · " + status if status else ""]
		for label in labels:
			label.modulate.a = 1.0 if i == current else INACTIVE_ALPHA


func update_field(targets_left: int, multiplier: int) -> void:
	targets_label.text = "Bug %d" % targets_left
	multiplier_label.text = "x%d" % multiplier


func flash(text: String) -> void:
	message.text = text
	message.modulate.a = 1.0
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	flash_tween = create_tween()
	flash_tween.tween_interval(0.8)
	flash_tween.tween_property(message, "modulate:a", 0.0, 0.4)


func show_result(title: String, lines: Array) -> void:
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	message.modulate.a = 0.0
	result_panel.show_result(title, lines)
