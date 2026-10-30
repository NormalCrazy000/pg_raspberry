extends Node2D
# Cannone: mira con mouse o touch (premi, trascina, rilascia per lanciare), tastiera o gamepad.
# Il touch arriva come mouse grazie all'emulazione di Godot.

signal fire(direction)

const MAX_AIM_ANGLE := deg2rad(85.0)
const AIM_SPEED := 1.6 # rad/s con tastiera o gamepad
const PREVIEW_DOTS := 12
const PREVIEW_STEP := 0.04 # secondi tra un punto e l'altro
const Trajectory := preload("res://scripts/game/trajectory.gd")
const BASE_TEXTURE := preload("res://assets/sprites/launcher_base.svg")
const BARREL_TEXTURE := preload("res://assets/sprites/launcher_barrel.svg")

const MUZZLE := 30.0 # distanza dal centro a cui nasce la paperella
const PATH_STEPS := 240
const PATH_DOT_EVERY := 3
const PATH_REFRESH_FRAMES := 4 # i pioli possono muoversi: il percorso si ricalcola ogni tanto

export var launch_speed := 600.0

var aim_angle := 0.0 setget set_aim_angle
var enabled := true setget set_enabled
var preview_bounces := 0 setget set_preview_bounces
var path := PoolVector2Array()
var path_dirty := true
var frames := 0
var barrel: Sprite


func _ready() -> void:
	# La canna è sotto la base e ruota attorno al centro del cannone.
	barrel = Sprite.new()
	barrel.texture = BARREL_TEXTURE
	barrel.centered = false
	barrel.offset = Vector2(-BARREL_TEXTURE.get_width() / 2.0, 0)
	barrel.scale = Vector2.ONE * 0.8
	add_child(barrel)
	var base := Sprite.new()
	base.texture = BASE_TEXTURE
	base.scale = Vector2.ONE * 0.75
	add_child(base)


func set_aim_angle(value: float) -> void:
	aim_angle = clamp(value, -MAX_AIM_ANGLE, MAX_AIM_ANGLE)
	path_dirty = true
	if barrel:
		barrel.rotation = aim_angle
	update()


func set_enabled(value: bool) -> void:
	enabled = value
	path_dirty = true
	update()


func set_preview_bounces(value: int) -> void:
	preview_bounces = value
	path_dirty = true
	update()


func direction() -> Vector2:
	return Vector2.DOWN.rotated(aim_angle)


func aim_at(local_target: Vector2) -> void:
	if local_target.length() < 1.0:
		return
	self.aim_angle = Vector2.DOWN.angle_to(local_target)


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion:
		aim_at(make_input_local(event).position)
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		aim_at(make_input_local(event).position)
		if not event.pressed:
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
		self.aim_angle = aim_angle + axis * AIM_SPEED * Settings.value("aim_speed") * delta


func _physics_process(_delta: float) -> void:
	# Il percorso con rimbalzi usa le query di fisica: si calcola qui, quando la mira cambia
	# e ogni PATH_REFRESH_FRAMES frame per seguire i pioli in movimento.
	frames += 1
	if frames % PATH_REFRESH_FRAMES == 0:
		path_dirty = true
	if path_dirty and enabled and preview_bounces > 0:
		path_dirty = false
		_compute_path()
		update()


func _fire() -> void:
	get_tree().set_input_as_handled()
	emit_signal("fire", direction())


func _compute_path() -> void:
	var result := Trajectory.simulate(get_world_2d().direct_space_state, global_position + direction() * MUZZLE,
			direction() * launch_speed, preview_bounces, PATH_STEPS, 500.0)
	path = PoolVector2Array()
	var points: PoolVector2Array = result.points
	for i in points.size():
		if i % PATH_DOT_EVERY == 0:
			path.append(to_local(points[i]))


func _draw() -> void:
	var dir := direction()
	if not enabled:
		return
	if preview_bounces > 0:
		for i in path.size():
			var alpha: float = 1.0 - 0.7 * float(i) / max(1, path.size())
			draw_circle(path[i], 2.0, Color(0.75, 0.55, 1.0, alpha))
		return
	# Anteprima base: parabola senza collisioni.
	var gravity := Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity"))
	var velocity := dir * launch_speed
	for i in range(1, PREVIEW_DOTS):
		var t: float = i * PREVIEW_STEP
		var alpha: float = 1.0 - float(i) / PREVIEW_DOTS
		draw_circle(velocity * t + gravity * t * t / 2.0, 2.0, Color(1, 1, 1, alpha))
