extends RigidBody2D
# Paperella: segnala ciò che tocca e misura da quanto tempo è quasi ferma.

signal touched(body, ball)

const RADIUS := 7.0
const VISUAL_SIZE := 22.0 # px: l'immagine è più grande della collisione per essere riconoscibile
const SLOW_SPEED := 40.0
const TRAIL_POINTS := 10
const TRAIL_COLOR := Color(1.0, 0.85, 0.2, 0.35)

var age := 0.0
var hits := 0 # pioli toccati da questa paperella (per la combo)
var slow_time := 0.0
var portal_cooldown := 0.0
var teleport_target = null # Vector2 oppure null
var trail: Line2D


func setup(texture: Texture, material: PhysicsMaterial, with_trail := true) -> void:
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
	sprite.scale = Vector2.ONE * (VISUAL_SIZE / texture.get_width())
	add_child(sprite)
	if with_trail:
		_add_trail()
	connect("body_entered", self, "_on_body_entered")


# Scia: una linea in coordinate globali che segue la paperella.
func _add_trail() -> void:
	trail = Line2D.new()
	trail.set_as_toplevel(true)
	trail.width = 6.0
	var fade := Gradient.new()
	fade.set_color(0, Color(TRAIL_COLOR.r, TRAIL_COLOR.g, TRAIL_COLOR.b, 0.0))
	fade.set_color(1, TRAIL_COLOR)
	trail.gradient = fade
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.show_behind_parent = true
	add_child(trail)


# I corpi rigidi si spostano in modo affidabile solo dentro _integrate_forces.
func teleport(to: Vector2) -> void:
	teleport_target = to


func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	if teleport_target != null:
		state.transform = Transform2D(state.transform.get_rotation(), teleport_target)
		teleport_target = null


func _physics_process(delta: float) -> void:
	age += delta
	portal_cooldown = max(0.0, portal_cooldown - delta)
	if not trail:
		pass
	elif teleport_target == null and portal_cooldown < 0.45:
		trail.add_point(global_position)
	else:
		trail.clear_points() # niente scia attraverso i portali
	while trail and trail.get_point_count() > TRAIL_POINTS:
		trail.remove_point(0)
	if linear_velocity.length() < SLOW_SPEED:
		slow_time += delta
	else:
		slow_time = 0.0


func _on_body_entered(body: Node) -> void:
	emit_signal("touched", body, self)
