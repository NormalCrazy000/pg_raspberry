extends Node2D
# Gruppo di pioli in movimento: ruota attorno al proprio centro oppure scorre avanti e indietro.

var mode := "rotate" # "rotate" oppure "slide"
var speed := 1.0 # rad/s per la rotazione; frequenza dell'oscillazione per lo scorrimento
var amplitude := 0.0 # px, solo per lo scorrimento
var axis := Vector2.RIGHT
var phase := 0.0
var origin := Vector2.ZERO
var time := 0.0


func _ready() -> void:
	origin = position


func _physics_process(delta: float) -> void:
	time += delta
	if mode == "rotate":
		rotation += speed * delta
	else:
		position = origin + axis * sin(time * speed + phase) * amplitude
