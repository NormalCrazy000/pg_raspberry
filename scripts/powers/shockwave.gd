extends "res://scripts/powers/power.gd"
# Refactoring (Giulia): onda d'urto che accende tutti i pioli attorno alla tazza colpita.

const Ring := preload("res://scripts/effects/ring.gd")
const RADIUS := 110.0


func activate(ball: RigidBody2D, peg: Node2D) -> void:
	if not peg:
		return
	var ring := Ring.new()
	ring.position = peg.global_position
	ring.max_radius = RADIUS
	game.add_effect(ring)
	for other in game.get_pegs():
		if other != peg and other.global_position.distance_to(peg.global_position) <= RADIUS:
			game.hit_peg(other, ball)
