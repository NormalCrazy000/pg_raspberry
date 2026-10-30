extends Node2D
# Partita: tiri, fine tiro, vittoria e sconfitta.
#
# Opzioni da riga di comando (per test e bilanciamento):
#   --level=res://levels/level_01.json   livello da caricare
#   --autoplay                          tira da solo a caso, stampa il risultato ed esce
#   --seed=N                            seme per i pioli obiettivo e i tiri automatici
#   --screenshot=FILE.png               salva uno screenshot dopo --screenshot-delay=S secondi (default 2)

enum State { AIMING, BALL_IN_PLAY, CLEARING, WON, LOST }

const Textures := preload("res://scripts/common/textures.gd")
const LevelLoader := preload("res://scripts/game/level_loader.gd")
const Peg := preload("res://scripts/game/peg.gd")
const Ball := preload("res://scripts/game/ball.gd")

const DEFAULT_LEVEL := "res://levels/level_01.json"
const FIELD_BOTTOM := 500.0 # sotto questa y la palla è persa
const STUCK_TIME := 1.0 # secondi quasi ferma prima di togliere i pioli colpiti
const NUDGE_AFTER := 3 # interventi anti-blocco prima di dare una spinta alla palla
const BALL_TIMEOUT := 30.0
const POP_INTERVAL := 0.05
const RESTART_DELAY := 0.6

var state: int = State.AIMING
var balls_left := 0
var targets_left := 0
var shots := 0
var ball: RigidBody2D
var stuck_count := 0
var result_time := 0.0
var autoplay := false
var level_path := DEFAULT_LEVEL
var screenshot_path := ""
var screenshot_delay := 2.0
var rng := RandomNumberGenerator.new()
var textures := {}
var flash_tween: SceneTreeTween

onready var launcher = $Launcher
onready var bucket = $Bucket
onready var pegs_root = $Pegs
onready var balls_root = $Balls
onready var balls_label = $HUD/BallsLabel
onready var targets_label = $HUD/TargetsLabel
onready var message = $HUD/Message
onready var bounce_material: PhysicsMaterial = $Walls.physics_material_override


func _ready() -> void:
	rng.randomize()
	_parse_args()
	if screenshot_path:
		_take_screenshot()
	textures = {
		"disc": Textures.make_disc(32),
		"rect": Textures.make_rounded_rect(Peg.RECT_SIZE, 4.0),
	}
	_load_level(level_path)
	launcher.connect("fire", self, "_on_launcher_fire")
	bucket.connect("ball_caught", self, "_on_ball_caught")
	_set_state(State.AIMING)


func _parse_args() -> void:
	for arg in OS.get_cmdline_args():
		if arg == "--autoplay":
			autoplay = true
		elif arg.begins_with("--seed="):
			rng.seed = int(arg.split("=")[1])
		elif arg.begins_with("--level="):
			level_path = arg.split("=")[1]
		elif arg.begins_with("--screenshot="):
			screenshot_path = arg.split("=")[1]
		elif arg.begins_with("--screenshot-delay="):
			screenshot_delay = float(arg.split("=")[1])


func _take_screenshot() -> void:
	yield(get_tree().create_timer(screenshot_delay), "timeout")
	var img := get_viewport().get_texture().get_data()
	img.flip_y()
	img.save_png(screenshot_path)
	print("Screenshot: %s" % screenshot_path)


func _load_level(path: String) -> void:
	var level := LevelLoader.load_level(path)
	if level.empty():
		return
	balls_left = level.balls
	var order := range(level.pegs.size())
	_shuffle(order)
	var target_ids := order.slice(0, level.targets - 1) if level.targets > 0 else []
	for i in level.pegs.size():
		var data: Dictionary = level.pegs[i]
		var peg := Peg.new()
		peg.position = data.position
		peg.rotation = data.rotation
		peg.setup(data.shape, i in target_ids, textures, bounce_material)
		pegs_root.add_child(peg)
		if peg.is_target:
			targets_left += 1
	_update_hud()


func _shuffle(array: Array) -> void:
	# Fisher-Yates con il nostro rng, così --seed rende tutto riproducibile.
	for i in range(array.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp


func _set_state(new_state: int) -> void:
	state = new_state
	launcher.enabled = state == State.AIMING
	match state:
		State.WON:
			_show_result("Livello completato!")
		State.LOST:
			_show_result("Palle finite")


func _on_launcher_fire(direction: Vector2) -> void:
	if state != State.AIMING or balls_left <= 0:
		return
	balls_left -= 1
	shots += 1
	stuck_count = 0
	ball = Ball.new()
	ball.setup(textures.disc, bounce_material)
	ball.position = launcher.position + direction * 30.0
	ball.linear_velocity = direction * launcher.launch_speed
	ball.connect("peg_hit", self, "_on_peg_hit")
	balls_root.add_child(ball)
	_update_hud()
	_set_state(State.BALL_IN_PLAY)


func _on_peg_hit(peg: Node) -> void:
	if peg.is_target:
		targets_left -= 1
		_update_hud()


func _on_ball_caught(caught: Node) -> void:
	if caught != ball or state != State.BALL_IN_PLAY:
		return
	balls_left += 1
	_flash("Palla recuperata!")
	_end_shot()


func _physics_process(_delta: float) -> void:
	if state != State.BALL_IN_PLAY:
		return
	if ball.position.y > FIELD_BOTTOM or ball.age > BALL_TIMEOUT:
		_end_shot()
	elif ball.slow_time > STUCK_TIME:
		# Palla incastrata: si tolgono subito i pioli già colpiti.
		ball.slow_time = 0.0
		stuck_count += 1
		for peg in pegs_root.get_children():
			if peg.lit:
				peg.pop()
		if stuck_count >= NUDGE_AFTER:
			ball.apply_central_impulse(Vector2(rng.randf_range(-80, 80), -120))


func _end_shot() -> void:
	ball.queue_free()
	ball = null
	_set_state(State.CLEARING)
	_clear_lit_pegs()


func _clear_lit_pegs() -> void:
	for peg in pegs_root.get_children():
		if is_instance_valid(peg) and peg.lit and not peg.popping:
			peg.pop()
			yield(get_tree().create_timer(POP_INTERVAL), "timeout")
	if targets_left <= 0:
		_set_state(State.WON)
	elif balls_left <= 0:
		_set_state(State.LOST)
	else:
		_set_state(State.AIMING)


func _process(_delta: float) -> void:
	if autoplay and state == State.AIMING:
		launcher.aim_angle = rng.randf_range(-launcher.MAX_AIM_ANGLE, launcher.MAX_AIM_ANGLE)
		_on_launcher_fire(launcher.direction())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	elif event is InputEventKey and event.pressed and event.scancode == KEY_R:
		get_tree().reload_current_scene()
	elif state in [State.WON, State.LOST] and _is_confirm(event):
		if OS.get_ticks_msec() / 1000.0 - result_time > RESTART_DELAY:
			get_tree().reload_current_scene()


func _is_confirm(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return not event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == BUTTON_LEFT
	return event.is_action_pressed("ui_accept")


func _update_hud() -> void:
	balls_label.text = "Palle: %d" % balls_left
	targets_label.text = "Obiettivi: %d" % targets_left


func _show_result(text: String) -> void:
	result_time = OS.get_ticks_msec() / 1000.0
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	message.text = "%s\n\nTocca o premi A per ricominciare" % text
	message.modulate.a = 1.0
	if autoplay:
		print("AUTOPLAY %s | tiri %d | palle rimaste %d | obiettivi rimasti %d" % [
			"vinto" if state == State.WON else "perso", shots, balls_left, targets_left])
		get_tree().quit()


func _flash(text: String) -> void:
	message.text = text
	message.modulate.a = 1.0
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	flash_tween = create_tween()
	flash_tween.tween_interval(0.6)
	flash_tween.tween_property(message, "modulate:a", 0.0, 0.4)
