extends StaticBody2D
# Piolo statico: si illumina quando viene colpito.

const COLOR_IDLE := Color(0.25, 0.55, 1.0)
const COLOR_LIT := Color(1.0, 0.85, 0.3)

var lit := false
var sprite: Sprite


func setup(texture: Texture, radius: float, material: PhysicsMaterial) -> void:
	physics_material_override = material
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	sprite = Sprite.new()
	sprite.texture = texture
	sprite.scale = Vector2.ONE * (radius * 2.0 / texture.get_width())
	sprite.modulate = COLOR_IDLE
	add_child(sprite)


func hit() -> bool:
	if lit:
		return false
	lit = true
	sprite.modulate = COLOR_LIT
	return true


func reset() -> void:
	lit = false
	sprite.modulate = COLOR_IDLE
