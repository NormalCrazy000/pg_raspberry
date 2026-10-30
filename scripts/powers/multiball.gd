extends "res://scripts/powers/power.gd"
# Fork (Marco): la paperella si divide in tre.

const SPREAD := 0.35 # radianti tra le paperelle


func activate(ball: RigidBody2D, _peg: Node2D) -> void:
	if not ball:
		return
	var velocity := ball.linear_velocity
	if velocity.length() < 200.0:
		velocity = velocity.normalized() * 200.0 if velocity.length() > 0.0 else Vector2(0, -200)
	for angle in [-SPREAD, SPREAD]:
		game.spawn_ball(ball.position, velocity.rotated(angle))
