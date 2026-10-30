extends "res://scripts/powers/power.gd"
# Hotfix (Dario): per il resto del tiro le paperelle sono attratte dai bug vicini.

const RANGE := 160.0
const STRENGTH := 700.0 # accelerazione in px/s² (la gravità è 900)

var active := false


func activate(_ball: RigidBody2D, _peg: Node2D) -> void:
	active = true


func on_ball_physics(ball: RigidBody2D, delta: float) -> void:
	if not active:
		return
	var nearest: Node2D = null
	var nearest_distance := RANGE
	for peg in game.pegs_root.get_children():
		if peg.is_target and not peg.lit and not peg.popping:
			var distance: float = peg.position.distance_to(ball.position)
			if distance < nearest_distance:
				nearest = peg
				nearest_distance = distance
	if nearest:
		ball.apply_central_impulse((nearest.position - ball.position).normalized() * STRENGTH * delta * ball.mass)


func on_shot_end() -> void:
	active = false


func status_text() -> String:
	return "magnete attivo" if active else ""
