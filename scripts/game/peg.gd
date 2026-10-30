extends StaticBody2D
# Piolo: riga di codice (normale), bug (obiettivo) o tazza di caffè (potere).
# Si illumina quando viene colpito e viene rimosso a fine tiro.

const KIND_NORMAL := "normal"
const KIND_TARGET := "target"
const KIND_POWER := "power"
const COLORS := {
	KIND_NORMAL: Color(0.3, 0.6, 1.0),
	KIND_TARGET: Color(1.0, 0.35, 0.45),
	KIND_POWER: Color(0.3, 0.9, 0.55),
}
const LIT_BOOST := 0.55 # quanto si schiarisce il colore quando è colpito
const ROUND_RADIUS := 9.0
const RECT_SIZE := Vector2(30, 10)
const POP_TIME := 0.12

var kind := KIND_NORMAL
var is_target := false
var lit := false
var popping := false
var sprite: Sprite
var collision: CollisionShape2D


func setup(shape_kind: String, peg_kind: String, textures: Dictionary, material: PhysicsMaterial) -> void:
	kind = peg_kind
	is_target = kind == KIND_TARGET
	physics_material_override = material
	collision = CollisionShape2D.new()
	sprite = Sprite.new()
	if shape_kind == "rect":
		var rect := RectangleShape2D.new()
		rect.extents = RECT_SIZE / 2.0
		collision.shape = rect
		sprite.texture = textures.rect
	else:
		var circle := CircleShape2D.new()
		circle.radius = ROUND_RADIUS
		collision.shape = circle
		sprite.texture = textures.disc
		sprite.scale = Vector2.ONE * (ROUND_RADIUS * 2.0 / sprite.texture.get_width())
	add_child(collision)
	add_child(sprite)
	_update_color()


func hit() -> bool:
	if lit or popping:
		return false
	lit = true
	_update_color()
	return true


func pop() -> void:
	if popping:
		return
	popping = true
	collision.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", sprite.scale * 1.6, POP_TIME)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, POP_TIME)
	tween.tween_callback(self, "queue_free")


func _update_color() -> void:
	var base: Color = COLORS[kind]
	sprite.modulate = base.linear_interpolate(Color.white, LIT_BOOST) if lit else base
