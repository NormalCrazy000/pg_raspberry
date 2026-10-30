extends Node2D
# Cannone: mira con mouse, touch (trascina e rilascia), tastiera o gamepad.

signal fire(direction)

const MAX_AIM_ANGLE := deg2rad(85.0)
const AIM_SPEED := 1.6 # rad/s con tastiera o gamepad
const PREVIEW_DOTS := 12
const PREVIEW_STEP := 0.04 # secondi tra un punto e l'altro

export var launch_speed := 600.0

var aim_angle := 0.0
var enabled := true setget set_enabled


func set_enabled(value: bool) -> void:
	enabled = value
	update()


func direction() -> Vector2:
	return Vector2.DOWN.rotated(aim_angle)


func aim_at(local_target: Vector2) -> void:
	if local_target.length() < 1.0:
		return
	aim_angle = clamp(Vector2.DOWN.angle_to(local_target), -MAX_AIM_ANGLE, MAX_AIM_ANGLE)
	update()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		aim_at(make_input_local(event).position)
	elif event is InputEventScreenTouch:
		aim_at(make_input_local(event).position)
		if not event.pressed:
			_fire()
	elif event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		aim_at(make_input_local(event).position)
		_fire()
	elif event.is_action_pressed("ui_accept"):
		_fire()


func _process(delta: float) -> void:
	if not enabled:
		return
	var axis := Input.get_joy_axis(0, JOY_AXIS_0)
	if abs(axis) < 0.2:
		axis = 0.0
	axis += Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	if axis != 0.0:
		aim_angle = clamp(aim_angle + axis * AIM_SPEED * delta, -MAX_AIM_ANGLE, MAX_AIM_ANGLE)
		update()


func _fire() -> void:
	get_tree().set_input_as_handled()
	emit_signal("fire", direction())


func _draw() -> void:
	var dir := direction()
	draw_line(Vector2.ZERO, dir * 28.0, Color(0.9, 0.9, 1.0), 6.0)
	draw_circle(Vector2.ZERO, 12.0, Color(0.5, 0.5, 0.65))
	if not enabled:
		return
	# Anteprima della traiettoria: parabola senza collisioni.
	var gravity := Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity"))
	var velocity := dir * launch_speed
	for i in range(1, PREVIEW_DOTS):
		var t: float = i * PREVIEW_STEP
		var alpha: float = 1.0 - float(i) / PREVIEW_DOTS
		draw_circle(velocity * t + gravity * t * t / 2.0, 2.0, Color(1, 1, 1, alpha))
