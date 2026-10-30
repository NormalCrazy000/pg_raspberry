extends Area2D
# Portale: la paperella che entra esce dal portale gemello mantenendo la velocità.

signal used(ball)

const RADIUS := 16.0
const COOLDOWN := 0.5 # evita che la paperella rimbalzi avanti e indietro tra i due portali

var partner: Area2D
var color := Color(0.7, 0.4, 1.0)
var spin := 0.0


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = RADIUS * 0.6
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	connect("body_entered", self, "_on_body_entered")


func _on_body_entered(body: Node) -> void:
	if partner and body.is_in_group("balls") and body.portal_cooldown <= 0.0:
		body.portal_cooldown = COOLDOWN
		body.teleport(partner.global_position)
		emit_signal("used", body)


func _process(delta: float) -> void:
	spin += delta * 2.0
	update()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(color, 0.18))
	for i in 3:
		var start: float = spin + i * TAU / 3.0
		draw_arc(Vector2.ZERO, RADIUS, start, start + TAU / 6.0, 8, color, 3.0)
