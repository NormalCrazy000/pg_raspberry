extends KinematicBody2D
# Cestino mobile: se la palla ci cade dentro, viene recuperata.

signal ball_caught(ball)

const COLOR := Color(0.75, 0.8, 0.9)

export var speed := 140.0
export var min_x := 70.0
export var max_x := 730.0

var direction := 1.0


func _ready() -> void:
	$Catch.connect("body_entered", self, "_on_catch_body_entered")


func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta
	if position.x >= max_x:
		position.x = max_x
		direction = -1.0
	elif position.x <= min_x:
		position.x = min_x
		direction = 1.0


func _on_catch_body_entered(body: Node) -> void:
	if body.is_in_group("balls"):
		emit_signal("ball_caught", body)


func _draw() -> void:
	draw_rect(Rect2(-38, -4, 76, 18), Color(COLOR, 0.25))
	draw_rect(Rect2(-46, -12, 8, 26), COLOR)
	draw_rect(Rect2(38, -12, 8, 26), COLOR)
