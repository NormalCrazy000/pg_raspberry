extends "res://scripts/powers/power.gd"
# Hotfix (Dario): le paperelle sono attratte dai bug vicini, per il resto del tiro e per il tiro successivo.

const RANGE := 200.0
const STRENGTH := 900.0 # accelerazione in px/s² (la gravità è 900)
const EXTRA_SHOTS := 1

var active := false
var shots_left := 0


func activate(_ball: RigidBody2D, _peg: Node2D) -> void:
	active = true
	shots_left += EXTRA_SHOTS


func on_shot_start() -> void:
	if shots_left > 0:
		shots_left -= 1
		active = true


func on_ball_physics(ball: RigidBody2D, delta: float) -> void:
	if not active:
		return
	var nearest: Node2D = null
	var nearest_distance := RANGE
	for peg in game.get_pegs():
		if peg.is_target and not peg.lit and not peg.popping:
			var distance: float = peg.global_position.distance_to(ball.position)
			if distance < nearest_distance:
				nearest = peg
				nearest_distance = distance
	if nearest:
		ball.apply_central_impulse((nearest.global_position - ball.position).normalized() * STRENGTH * delta * ball.mass)


func on_shot_end() -> void:
	active = false


func status_text() -> String:
	if active:
		return tr("POWER_MAGNET_ACTIVE")
	if shots_left > 0:
		return tr("POWER_MAGNET_NEXT")
	return ""
