extends RigidBody2D
# Paperella: segnala ciò che tocca e misura da quanto tempo è quasi ferma.

signal touched(body, ball)

const RADIUS := 7.0
const SLOW_SPEED := 40.0

var age := 0.0
var slow_time := 0.0


func setup(texture: Texture, material: PhysicsMaterial) -> void:
	add_to_group("balls")
	physics_material_override = material
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	contacts_reported = 4
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var sprite := Sprite.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * (RADIUS * 2.0 / texture.get_width())
	add_child(sprite)
	connect("body_entered", self, "_on_body_entered")


func _physics_process(delta: float) -> void:
	age += delta
	if linear_velocity.length() < SLOW_SPEED:
		slow_time += delta
	else:
		slow_time = 0.0


func _on_body_entered(body: Node) -> void:
	emit_signal("touched", body, self)
