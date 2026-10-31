extends CanvasLayer
# HUD della sfida: i due giocatori ai lati, bug rimasti e moltiplicatore ai lati del cannone,
# messaggi a comparsa, pausa e schermata finale. Le scelte dei menu escono dal segnale `menu_choice`
# ("resume", "restart", "new", "rematch", "bracket", "menu").

signal menu_choice(id)

const Scoring := preload("res://scripts/game/scoring.gd")
const MenuBox := preload("res://scripts/game/menu_box.gd")
const INACTIVE_ALPHA := 0.45

var flash_tween: SceneTreeTween
var result_box: Control
var pause_box: Control
var allow_restart := true # nel torneo non si può ricominciare una partita

onready var panels := [
	[$P1Name, $P1Score, $P1Info],
	[$P2Name, $P2Score, $P2Info],
]
onready var targets_label = $TargetsLabel
onready var multiplier_label = $MultiplierLabel
onready var message = $Message
onready var pause_button = $PauseButton


func _ready() -> void:
	# La pausa deve funzionare anche ad albero in pausa.
	pause_mode = Node.PAUSE_MODE_PROCESS
	result_box = MenuBox.new()
	add_child(result_box)
	result_box.connect("choice", self, "_on_result_choice")
	pause_box = MenuBox.new()
	add_child(pause_box)
	pause_box.connect("choice", self, "_on_pause_choice")
	pause_button.connect("pressed", self, "show_pause")


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
		labels[2].text = tr("HUD_BALLS") % player.balls_left + (" · " + status if status else "")
		for label in labels:
			label.modulate.a = 1.0 if i == current else INACTIVE_ALPHA


func update_field(targets_left: int, multiplier: int) -> void:
	targets_label.text = tr("HUD_BUGS") % targets_left
	multiplier_label.text = "x%d" % multiplier


func flash(text: String) -> void:
	get_parent().mark_perf("messaggio")
	message.text = text
	message.modulate.a = 1.0
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	flash_tween = create_tween()
	flash_tween.tween_interval(0.8)
	flash_tween.tween_property(message, "modulate:a", 0.0, 0.4)


# `options`: pulsanti come coppie [id, testo] (vedi MenuBox.open).
func show_result(title: String, lines: Array, options: Array) -> void:
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	message.modulate.a = 0.0
	pause_button.visible = false
	result_box.open(title, lines, options)


func show_pause() -> void:
	if pause_box.visible or result_box.visible:
		return
	get_tree().paused = true
	var options := [["resume", tr("PAUSE_RESUME")]]
	if allow_restart:
		options.append(["restart", tr("PAUSE_RESTART")])
	options.append(["menu", tr("PAUSE_MENU")])
	pause_box.open(tr("PAUSE_TITLE"), [], options)


func _on_result_choice(id: String) -> void:
	emit_signal("menu_choice", id)


func _on_pause_choice(id: String) -> void:
	pause_box.close()
	get_tree().paused = false
	if id != "resume":
		emit_signal("menu_choice", id)


func _unhandled_input(event: InputEvent) -> void:
	# Esc / Start / indietro chiudono la pausa.
	if pause_box.visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		get_tree().set_input_as_handled()
		_on_pause_choice("resume")
