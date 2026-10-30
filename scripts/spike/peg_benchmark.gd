extends Node2D
# Spike Fase 0: campo di pioli + palla con fisica, per misurare le prestazioni sul Raspberry Pi 3.
#
# Modalità interattiva (default):
#   mouse/touch: mira e lancia | frecce/stick/d-pad: mira | spazio/A: lancia | R: reset pioli | Esc: esci
#
# Modalità benchmark (lancia palle automaticamente, stampa i risultati ed esce):
#   godot3 --path . --bench [--pegs=100] [--balls=1] [--duration=30] [--fx] [--novsync]

const Peg := preload("res://scripts/spike/peg.gd")
const Ball := preload("res://scripts/spike/ball.gd")

const VIEW_SIZE := Vector2(800, 480)
const LAUNCHER_POS := Vector2(400, 28)
const LAUNCH_SPEED := 600.0
const MAX_AIM_ANGLE := deg2rad(85.0)
const AIM_SPEED := 1.6 # rad/s con tastiera o gamepad
const PEG_RADIUS := 8.0
const BALL_RADIUS := 7.0
const PEG_AREA := Rect2(60, 110, 680, 330)
const BALL_TIMEOUT := 20.0 # secondi: palla incastrata -> rimossa
const WARMUP := 2.0 # secondi esclusi dalle statistiche
const RESULTS_FILE := "user://bench_results.csv"

var bench := false
var peg_count := 100
var ball_target := 1
var duration := 30.0
var fx := false

var aim_angle := 0.0
var disc_texture: ImageTexture
var bounce_material: PhysicsMaterial
var pegs := []
var balls := []
var bursts := []
var next_burst := 0
var rng := RandomNumberGenerator.new()

var elapsed := 0.0
var frame_times := []
var physics_ms_sum := 0.0
var draw_calls_max := 0
var hits := 0
var hud: Label
var hud_timer := 0.0


func _ready() -> void:
	rng.seed = 42
	_parse_args()
	disc_texture = _make_disc_texture(32)
	bounce_material = PhysicsMaterial.new()
	bounce_material.bounce = 0.55
	bounce_material.friction = 0.1
	_build_walls()
	_build_pegs(peg_count)
	if fx:
		_build_bursts(16)
	_build_hud()
	print("Driver video: %s | GPU: %s (%s)" % [_driver_name(), VisualServer.get_video_adapter_name(), VisualServer.get_video_adapter_vendor()])
	if bench:
		print("Benchmark: pegs=%d balls=%d duration=%ss fx=%s vsync=%s" % [peg_count, ball_target, duration, fx, OS.vsync_enabled])


func _parse_args() -> void:
	for arg in OS.get_cmdline_args():
		if arg == "--bench":
			bench = true
		elif arg == "--fx":
			fx = true
		elif arg.begins_with("--pegs="):
			peg_count = int(arg.split("=")[1])
		elif arg.begins_with("--balls="):
			ball_target = int(arg.split("=")[1])
		elif arg.begins_with("--duration="):
			duration = float(arg.split("=")[1])


func _make_disc_texture(size: int) -> ImageTexture:
	var img := Image.new()
	img.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) / 2.0
	var r := size / 2.0
	img.lock()
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var alpha: float = clamp(r - d, 0.0, 1.0)
			var shade := 1.0 - 0.35 * (d / r)
			img.set_pixel(x, y, Color(shade, shade, shade, alpha))
	img.unlock()
	var tex := ImageTexture.new()
	tex.create_from_image(img, Texture.FLAG_FILTER)
	return tex


func _build_walls() -> void:
	var walls := StaticBody2D.new()
	walls.physics_material_override = bounce_material
	add_child(walls)
	var thickness := 40.0
	# sinistra, destra, soffitto (il fondo resta aperto)
	var rects := [
		Rect2(-thickness, -thickness, thickness, VIEW_SIZE.y + thickness * 2),
		Rect2(VIEW_SIZE.x, -thickness, thickness, VIEW_SIZE.y + thickness * 2),
		Rect2(0, -thickness, VIEW_SIZE.x, thickness),
	]
	for rect in rects:
		var shape := RectangleShape2D.new()
		shape.extents = rect.size / 2.0
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = rect.position + rect.size / 2.0
		walls.add_child(collision)


func _build_pegs(count: int) -> void:
	# Griglia sfalsata che riempie PEG_AREA con circa `count` pioli.
	var cols := int(max(1, round(sqrt(count * PEG_AREA.size.x / PEG_AREA.size.y))))
	var rows := int(ceil(float(count) / cols))
	var step := Vector2(PEG_AREA.size.x / max(1, cols - 1), PEG_AREA.size.y / max(1, rows - 1))
	for i in count:
		var row: int = i / cols
		var col: int = i % cols
		var offset: float = step.x / 2.0 if row % 2 == 1 else 0.0
		var peg := Peg.new()
		peg.position = PEG_AREA.position + Vector2(col * step.x + offset, row * step.y)
		peg.setup(disc_texture, PEG_RADIUS, bounce_material)
		add_child(peg)
		pegs.append(peg)


func _build_bursts(count: int) -> void:
	for i in count:
		var p := CPUParticles2D.new()
		p.emitting = false
		p.one_shot = true
		p.amount = 8
		p.lifetime = 0.4
		p.explosiveness = 1.0
		p.spread = 180.0
		p.initial_velocity = 120.0
		p.gravity = Vector2(0, 300)
		p.scale_amount = 3.0
		p.color = Peg.COLOR_LIT
		add_child(p)
		bursts.append(p)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.rect_position = Vector2(8, 4)
	layer.add_child(hud)


func _driver_name() -> String:
	return "GLES3" if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES3 else "GLES2"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if bench:
		return
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		_aim_at(make_input_local(event).position)
	elif event is InputEventScreenTouch:
		_aim_at(make_input_local(event).position)
		if not event.pressed:
			_shoot()
	elif event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		_aim_at(make_input_local(event).position)
		_shoot()
	elif event.is_action_pressed("ui_accept"):
		_shoot()
	elif event is InputEventKey and event.pressed and event.scancode == KEY_R:
		_reset_pegs()


func _aim_at(target: Vector2) -> void:
	var dir := target - LAUNCHER_POS
	if dir.length() < 1.0:
		return
	aim_angle = clamp(Vector2.DOWN.angle_to(dir), -MAX_AIM_ANGLE, MAX_AIM_ANGLE)
	update()


func _shoot() -> void:
	if not bench and balls.size() > 0:
		return # in modalità interattiva un tiro alla volta
	var ball := Ball.new()
	ball.position = LAUNCHER_POS
	ball.setup(disc_texture, BALL_RADIUS, bounce_material)
	ball.linear_velocity = Vector2.DOWN.rotated(aim_angle) * LAUNCH_SPEED
	ball.connect("peg_hit", self, "_on_peg_hit")
	add_child(ball)
	balls.append(ball)


func _on_peg_hit(peg: Node2D) -> void:
	hits += 1
	if fx:
		var p: CPUParticles2D = bursts[next_burst]
		next_burst = (next_burst + 1) % bursts.size()
		p.position = peg.position
		p.restart()


func _reset_pegs() -> void:
	for peg in pegs:
		peg.reset()


func _process(delta: float) -> void:
	var axis := Input.get_joy_axis(0, JOY_AXIS_0)
	if abs(axis) < 0.2:
		axis = 0.0
	axis += Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	if axis != 0.0 and not bench:
		aim_angle = clamp(aim_angle + axis * AIM_SPEED * delta, -MAX_AIM_ANGLE, MAX_AIM_ANGLE)
		update()

	_update_balls()
	if bench:
		_bench_step(delta)

	hud_timer -= delta
	if hud_timer <= 0.0:
		hud_timer = 0.25
		hud.text = "FPS %d | %s | pioli %d | palle %d | fisica %.1f ms | draw call %d" % [
			Engine.get_frames_per_second(), _driver_name(), pegs.size(), balls.size(),
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.RENDER_2D_DRAW_CALLS_IN_FRAME)]


func _update_balls() -> void:
	for ball in balls.duplicate():
		if ball.position.y > VIEW_SIZE.y + BALL_RADIUS * 2 or ball.age > BALL_TIMEOUT:
			balls.erase(ball)
			ball.queue_free()
			if bench:
				_reset_pegs() # numero di pioli costante durante il benchmark
			else:
				_clear_lit_pegs()
	if bench:
		while balls.size() < ball_target:
			aim_angle = rng.randf_range(-MAX_AIM_ANGLE, MAX_AIM_ANGLE)
			_shoot()


func _clear_lit_pegs() -> void:
	for peg in pegs.duplicate():
		if peg.lit:
			pegs.erase(peg)
			peg.queue_free()


func _bench_step(delta: float) -> void:
	elapsed += delta
	if elapsed < WARMUP:
		return
	frame_times.append(delta)
	physics_ms_sum += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	draw_calls_max = int(max(draw_calls_max, Performance.get_monitor(Performance.RENDER_2D_DRAW_CALLS_IN_FRAME)))
	if elapsed >= WARMUP + duration:
		_finish_bench()


func _finish_bench() -> void:
	set_process(false)
	var sorted := frame_times.duplicate()
	sorted.sort()
	var total := 0.0
	for t in sorted:
		total += t
	var n := sorted.size()
	var avg_fps := n / total
	var low1_fps: float = 1.0 / sorted[int(n * 0.99)]
	var min_fps: float = 1.0 / sorted[n - 1]
	var physics_ms := physics_ms_sum / n
	var result := "%s,%s,%s,%d,%d,%s,%s,%.1f,%.1f,%.1f,%.2f,%d,%d" % [
		Time.get_datetime_string_from_system(), OS.get_name(), VisualServer.get_video_adapter_name(),
		peg_count, ball_target, fx, OS.vsync_enabled, avg_fps, low1_fps, min_fps, physics_ms, draw_calls_max, hits]
	print("RISULTATO  fps medi %.1f | 1%% low %.1f | min %.1f | fisica %.2f ms | draw call max %d | colpi %d" % [
		avg_fps, low1_fps, min_fps, physics_ms, draw_calls_max, hits])

	var file := File.new()
	var exists := file.file_exists(RESULTS_FILE)
	if file.open(RESULTS_FILE, File.READ_WRITE if exists else File.WRITE) == OK:
		if exists:
			file.seek_end()
		else:
			file.store_line("data,os,gpu,pioli,palle,fx,vsync,fps_medi,fps_1pct_low,fps_min,fisica_ms,draw_call_max,colpi")
		file.store_line(result)
		file.close()
		print("Salvato in %s" % ProjectSettings.globalize_path(RESULTS_FILE))
	get_tree().quit()


func _draw() -> void:
	# Lanciatore e anteprima della traiettoria (parabola senza collisioni).
	var dir := Vector2.DOWN.rotated(aim_angle)
	draw_line(LAUNCHER_POS, LAUNCHER_POS + dir * 28.0, Color(0.9, 0.9, 1.0), 6.0)
	draw_circle(LAUNCHER_POS, 12.0, Color(0.5, 0.5, 0.65))
	if bench:
		return
	var gravity := Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity"))
	var velocity := dir * LAUNCH_SPEED
	for i in range(1, 12):
		var t: float = i * 0.04
		var p := LAUNCHER_POS + velocity * t + gravity * t * t / 2.0
		draw_circle(p, 2.0, Color(1, 1, 1, 1.0 - i / 12.0))
