extends RigidBody2D
# Palla: notifica ogni piolo toccato.

signal peg_hit(peg)

var age := 0.0


func setup(texture: Texture, radius: float, material: PhysicsMaterial) -> void:
	physics_material_override = material
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	contacts_reported = 4
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var sprite := Sprite.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * (radius * 2.0 / texture.get_width())
	add_child(sprite)
	connect("body_entered", self, "_on_body_entered")


func _physics_process(delta: float) -> void:
	age += delta


func _on_body_entered(body: Node) -> void:
	if body.has_method("hit") and body.hit():
		emit_signal("peg_hit", body)
