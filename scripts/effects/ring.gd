extends Node2D
# Anello che si espande e svanisce (onda d'urto).

const DURATION := 0.35

var max_radius := 100.0
var color := Color(0.3, 0.9, 0.55)
var radius := 0.0


func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "radius", max_radius, DURATION)
	tween.parallel().tween_property(self, "modulate:a", 0.0, DURATION)
	tween.tween_callback(self, "queue_free")


func _process(_delta: float) -> void:
	update()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, color, 3.0)
