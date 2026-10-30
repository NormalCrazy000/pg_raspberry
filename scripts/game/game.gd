extends Node2D
# Partita: tiri, punteggio, fine tiro, vittoria e sconfitta.
#
# Opzioni da riga di comando (per test e bilanciamento):
#   --level=res://levels/level_01.json   livello da caricare
#   --autoplay                          tira da solo a caso, stampa il risultato ed esce
#   --autoplay=smart                    come sopra, ma mira agli obiettivi rimasti
#   --seed=N                            seme per i pioli obiettivo e i tiri automatici
#   --screenshot=FILE.png               salva uno screenshot dopo --screenshot-delay=S secondi (default 2);
#                                       con --autoplay si esce dopo lo screenshot invece che a fine partita

enum State { AIMING, BALL_IN_PLAY, CLEARING, BONUS, WON, LOST }

const Textures := preload("res://scripts/common/textures.gd")
const LevelLoader := preload("res://scripts/game/level_loader.gd")
const Scoring := preload("res://scripts/game/scoring.gd")
const Peg := preload("res://scripts/game/peg.gd")
const Ball := preload("res://scripts/game/ball.gd")

const DEFAULT_LEVEL := "res://levels/level_01.json"
const FIELD_BOTTOM := 500.0 # sotto questa y la palla è persa
const STUCK_TIME := 1.0 # secondi quasi ferma prima di togliere i pioli colpiti
const NUDGE_AFTER := 3 # interventi anti-blocco prima di dare una spinta alla palla
const BALL_TIMEOUT := 30.0
const POP_INTERVAL := 0.05
const RESTART_DELAY := 0.6
const SLOWMO_SCALE := 0.3
const SLOWMO_TIME := 0.5 # secondi di gioco (circa 1,7 s reali)
const BALL_BONUS_INTERVAL := 0.35
const COLOR_POINTS := Color(1, 1, 1)
const COLOR_TARGET_POINTS := Color(1.0, 0.6, 0.65)
const COLOR_BONUS := Color(1.0, 0.85, 0.3)

var state: int = State.AIMING
var balls_left := 0
var targets_left := 0
var shots := 0
var extra_balls_won := 0
var bonus_balls := 0
var ball: RigidBody2D
var stuck_count := 0
var result_time := 0.0
var scoring: Scoring
var star_thresholds := []
var autoplay := ""
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
onready var effects_root = $Effects
onready var balls_label = $HUD/BallsLabel
onready var score_label = $HUD/ScoreLabel
onready var multiplier_label = $HUD/MultiplierLabel
onready var targets_label = $HUD/TargetsLabel
onready var message = $HUD/Message
onready var result_panel = $HUD/ResultPanel
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


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _parse_args() -> void:
	for arg in OS.get_cmdline_args():
		if arg == "--autoplay":
			autoplay = "random"
		elif arg.begins_with("--autoplay="):
			autoplay = arg.split("=")[1]
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
	if autoplay:
		get_tree().quit()


func _load_level(path: String) -> void:
	var level := LevelLoader.load_level(path)
	if level.empty():
		return
	balls_left = level.balls
	star_thresholds = level.stars
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
	scoring = Scoring.new(targets_left)
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
	if state == State.WON or state == State.LOST:
		_show_result()


func _on_launcher_fire(direction: Vector2) -> void:
	if state != State.AIMING or balls_left <= 0:
		return
	balls_left -= 1
	shots += 1
	stuck_count = 0
	scoring.start_shot()
	ball = Ball.new()
	ball.setup(textures.disc, bounce_material)
	ball.position = launcher.position + direction * 30.0
	ball.linear_velocity = direction * launcher.launch_speed
	ball.connect("peg_hit", self, "_on_peg_hit")
	balls_root.add_child(ball)
	_update_hud()
	_set_state(State.BALL_IN_PLAY)


func _on_peg_hit(peg: Node) -> void:
	var multiplier_before := scoring.multiplier()
	var points := scoring.peg_hit(peg.is_target)
	_float_text(peg.position, Scoring.format(points), COLOR_TARGET_POINTS if peg.is_target else COLOR_POINTS)
	if peg.is_target:
		targets_left -= 1
		if targets_left == 0:
			_start_slowmo()
		elif scoring.multiplier() > multiplier_before:
			_flash("Moltiplicatore x%d!" % scoring.multiplier())
	_update_hud()


func _start_slowmo() -> void:
	Engine.time_scale = SLOWMO_SCALE
	yield(get_tree().create_timer(SLOWMO_TIME), "timeout")
	Engine.time_scale = 1.0


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
	Engine.time_scale = 1.0
	ball.queue_free()
	ball = null
	_set_state(State.CLEARING)
	_clear_lit_pegs()


func _clear_lit_pegs() -> void:
	for peg in pegs_root.get_children():
		if is_instance_valid(peg) and peg.lit and not peg.popping:
			peg.pop()
			yield(get_tree().create_timer(POP_INTERVAL), "timeout")
	var extra := scoring.extra_balls_for_shot()
	if extra > 0:
		balls_left += extra
		extra_balls_won += extra
		_flash("Palla extra!" if extra == 1 else "%d palle extra!" % extra)
		_update_hud()
	if targets_left <= 0:
		_ball_bonus()
	elif balls_left <= 0:
		_set_state(State.LOST)
	else:
		_set_state(State.AIMING)


# Fine livello: ogni palla rimasta diventa punti, una alla volta.
func _ball_bonus() -> void:
	_set_state(State.BONUS)
	bonus_balls = balls_left
	while balls_left > 0:
		yield(get_tree().create_timer(BALL_BONUS_INTERVAL), "timeout")
		balls_left -= 1
		scoring.add_ball_bonus()
		_float_text(launcher.position + Vector2(0, 40), "+" + Scoring.format(Scoring.BALL_BONUS), COLOR_BONUS)
		_update_hud()
	yield(get_tree().create_timer(BALL_BONUS_INTERVAL), "timeout")
	_set_state(State.WON)


func _process(_delta: float) -> void:
	if autoplay and state == State.AIMING:
		launcher.aim_angle = _smart_angle() if autoplay == "smart" else _random_angle()
		_on_launcher_fire(launcher.direction())


func _random_angle() -> float:
	return rng.randf_range(-launcher.MAX_AIM_ANGLE, launcher.MAX_AIM_ANGLE)


# Autoplay "smart": sceglie un obiettivo a caso e cerca l'angolo la cui parabola
# ci passa più vicino (ignorando i pioli in mezzo), con un po' di imprecisione.
func _smart_angle() -> float:
	var targets := []
	for peg in pegs_root.get_children():
		if peg.is_target and not peg.lit and not peg.popping:
			targets.append(peg)
	if targets.empty():
		return _random_angle()
	var target: Node2D = targets[rng.randi_range(0, targets.size() - 1)]
	var goal: Vector2 = target.position - launcher.position
	var gravity := Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity"))
	var best_angle := 0.0
	var best_distance := INF
	var angle: float = -launcher.MAX_AIM_ANGLE
	while angle <= launcher.MAX_AIM_ANGLE:
		var velocity: Vector2 = Vector2.DOWN.rotated(angle) * launcher.launch_speed
		var t := 0.0
		while t < 2.0:
			var p: Vector2 = velocity * t + gravity * t * t / 2.0
			var distance := p.distance_to(goal)
			if distance < best_distance:
				best_distance = distance
				best_angle = angle
			if p.y > goal.y + 40.0:
				break
			t += 0.01
		angle += deg2rad(0.5)
	return best_angle + rng.randf_range(-0.02, 0.02)


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
	score_label.text = Scoring.format(scoring.total)
	multiplier_label.text = "x%d" % scoring.multiplier()
	targets_label.text = "Obiettivi: %d" % targets_left


func _show_result() -> void:
	result_time = OS.get_ticks_msec() / 1000.0
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	message.modulate.a = 0.0
	var won: bool = state == State.WON
	var stars: int = scoring.stars(star_thresholds) if won else 0
	var lines := ["Punteggio: %s" % Scoring.format(scoring.total)]
	if won:
		lines.append("di cui bonus palle: %d × %s" % [bonus_balls, Scoring.format(Scoring.BALL_BONUS)])
	else:
		lines.append("Obiettivi rimasti: %d" % targets_left)
	result_panel.show_result(won, stars, lines)
	if autoplay:
		print("AUTOPLAY %s | tiri %d | punteggio %d | stelle %d | obiettivi rimasti %d | palle extra %d" % [
			"vinto" if won else "perso", shots, scoring.total, stars, targets_left, extra_balls_won])
		if not screenshot_path:
			get_tree().quit()


func _flash(text: String) -> void:
	message.text = text
	message.modulate.a = 1.0
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	flash_tween = create_tween()
	flash_tween.tween_interval(0.6)
	flash_tween.tween_property(message, "modulate:a", 0.0, 0.4)


# Testo che sale e svanisce (punti guadagnati).
func _float_text(at: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.align = Label.ALIGN_CENTER
	label.rect_size = Vector2(80, 16)
	label.rect_position = at - Vector2(40, 26)
	label.modulate = color
	effects_root.add_child(label)
	var tween := label.create_tween()
	tween.tween_property(label, "rect_position:y", label.rect_position.y - 20.0, 0.7)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.3)
	tween.tween_callback(label, "queue_free")
