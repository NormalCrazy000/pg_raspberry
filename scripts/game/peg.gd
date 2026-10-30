extends StaticBody2D
# Piolo: puntina o riga di codice (normale), bug (obiettivo) o tazza di caffè (potere).
# Si illumina quando viene colpito e viene rimosso a fine tiro.
# Le immagini arrivano dal dizionario `textures` con chiavi "<forma>_<tipo>", più "glow" e "glow_material".

const KIND_NORMAL := "normal"
const KIND_TARGET := "target"
const KIND_POWER := "power"
# Colore dell'alone quando il piolo è acceso (e delle particelle).
const COLORS := {
	KIND_NORMAL: Color(0.3, 0.6, 1.0),
	KIND_TARGET: Color(1.0, 0.35, 0.45),
	KIND_POWER: Color(0.3, 0.9, 0.55),
}
const LIT_BRIGHTNESS := Color(1.45, 1.45, 1.45) # quanto si schiarisce l'immagine quando è colpito
const ROUND_VISUAL := 22.0 # px: l'immagine è un po' più grande della collisione
const RECT_VISUAL := 32.0
const GLOW_SIZE := 46.0
const ROUND_RADIUS := 9.0
const RECT_SIZE := Vector2(30, 10)
const POP_TIME := 0.12

var kind := KIND_NORMAL
var is_target := false
var lit := false
var popping := false
var sprite: Sprite
var halo: Sprite
var collision: CollisionShape2D


func setup(shape_kind: String, peg_kind: String, textures: Dictionary, material: PhysicsMaterial) -> void:
	add_to_group("pegs")
	kind = peg_kind
	is_target = kind == KIND_TARGET
	physics_material_override = material
	collision = CollisionShape2D.new()
	sprite = Sprite.new()
	sprite.texture = textures["%s_%s" % [shape_kind, kind]]
	if shape_kind == "rect":
		var rect := RectangleShape2D.new()
		rect.extents = RECT_SIZE / 2.0
		collision.shape = rect
		sprite.scale = Vector2.ONE * (RECT_VISUAL / sprite.texture.get_width())
	else:
		var circle := CircleShape2D.new()
		circle.radius = ROUND_RADIUS
		collision.shape = circle
		sprite.scale = Vector2.ONE * (ROUND_VISUAL / sprite.texture.get_width())
	halo = Sprite.new()
	halo.texture = textures.glow
	halo.material = textures.glow_material
	halo.modulate = COLORS[kind]
	halo.scale = Vector2.ONE * (GLOW_SIZE / halo.texture.get_width())
	halo.visible = false
	add_child(collision)
	add_child(halo)
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
	tween.parallel().tween_property(halo, "modulate:a", 0.0, POP_TIME)
	tween.tween_callback(self, "queue_free")


func _update_color() -> void:
	sprite.modulate = LIT_BRIGHTNESS if lit else Color.white
	halo.visible = lit
