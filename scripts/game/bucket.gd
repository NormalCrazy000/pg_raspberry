extends KinematicBody2D
# Cestino mobile, il "garbage collector" (GC): se la paperella ci cade dentro, viene recuperata.

signal ball_caught(ball)

const TEXTURE := preload("res://assets/sprites/bin.svg")

export var speed := 140.0
export var min_x := 70.0
export var max_x := 730.0

var direction := 1.0
var x := 0.0 # posizione tenuta qui: rileggere `position` dal corpo fisico non è affidabile


func _ready() -> void:
	x = position.x
	var sprite := Sprite.new()
	sprite.texture = TEXTURE
	sprite.position = Vector2(0, 1)
	add_child(sprite)
	$Catch.connect("body_entered", self, "_on_catch_body_entered")


func _physics_process(delta: float) -> void:
	x += direction * speed * delta
	if x >= max_x:
		x = max_x
		direction = -1.0
	elif x <= min_x:
		x = min_x
		direction = 1.0
	position.x = x


func _on_catch_body_entered(body: Node) -> void:
	if body.is_in_group("balls"):
		emit_signal("ball_caught", body)
