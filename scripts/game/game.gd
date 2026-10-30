extends Node2D
# Sfida a turni: due giocatori (persone o CPU) tirano a turno sullo stesso campo.
# I punti vanno a chi tira, il moltiplicatore è condiviso. La sfida finisce quando
# i bug sono tutti eliminati o nessuno ha più paperelle: vince chi ha più punti.
#
# Le impostazioni arrivano dal menu (Session); da riga di comando si possono forzare:
#   --autoplay[=random|easy|normal|hard]   entrambi i giocatori sono CPU (default normal), stampa il risultato ed esce;
#                                          con due valori separati da virgola (es. hard,easy) uno per giocatore
#   --cpu=easy|normal|hard                 il giocatore 2 è la CPU
#   --p1=ID (oppure --character=ID), --p2=ID   personaggi (id in data/characters.json)
#   --seed=N                               campo e tiri della CPU riproducibili
#   --level=res://levels/level_01.json     campo fisso da JSON invece che generato
#   --measure                              misura FPS e draw call durante la sfida e li stampa alla fine
#                                          (da usare con --autoplay, a tempo reale: è il benchmark della partita vera)
# Altre opzioni globali (--screenshot, --debug-power) in scripts/session.gd.

enum State { AIMING, BALL_IN_PLAY, CLEARING, BONUS, FINISHED }

const Textures := preload("res://scripts/common/textures.gd")
const LevelLoader := preload("res://scripts/game/level_loader.gd")
const FieldGenerator := preload("res://scripts/game/field_generator.gd")
const Scoring := preload("res://scripts/game/scoring.gd")
const Characters := preload("res://scripts/game/characters.gd")
const PowerRegistry := preload("res://scripts/powers/registry.gd")
const Player := preload("res://scripts/game/player.gd")
const CpuPlayer := preload("res://scripts/game/cpu_player.gd")
const Peg := preload("res://scripts/game/peg.gd")
const PegGroup := preload("res://scripts/game/peg_group.gd")
const PortalScript := preload("res://scripts/game/portal.gd")
const Ball := preload("res://scripts/game/ball.gd")
const SPRITES := {
	"round_normal": preload("res://assets/sprites/tack.svg"),
	"round_target": preload("res://assets/sprites/bug.svg"),
	"round_power": preload("res://assets/sprites/coffee.svg"),
	"rect_normal": preload("res://assets/sprites/code_line.svg"),
	"rect_target": preload("res://assets/sprites/code_bug.svg"),
	"rect_power": preload("res://assets/sprites/code_coffee.svg"),
	"duck": preload("res://assets/sprites/duck.svg"),
}
const BACKGROUND := preload("res://assets/sprites/background.svg")

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const FIELD_BOTTOM := 500.0 # sotto questa y la paperella è persa
const STUCK_TIME := 1.0 # secondi quasi ferma prima di togliere i pioli colpiti
const NUDGE_AFTER := 3 # interventi anti-blocco prima di dare una spinta alla paperella
const BALL_TIMEOUT := 30.0
const POP_INTERVAL := 0.05
const RESTART_DELAY := 0.6
const SLOWMO_SCALE := 0.3
const SLOWMO_TIME := 0.5 # secondi di gioco (circa 1,7 s reali)
const BALL_BONUS_INTERVAL := 0.35
const CPU_THINK_TIME := 0.5
const CPU_AIM_TIME := 0.6
const PORTAL_COLORS := [Color(0.7, 0.4, 1.0), Color(0.3, 0.85, 0.95)]
const COLOR_POINTS := Color(1, 1, 1)
const COLOR_TARGET_POINTS := Color(1.0, 0.6, 0.65)
const COLOR_BONUS := Color(1.0, 0.85, 0.3)
const BURSTS := 8 # sistemi di particelle riutilizzati (budget contenuto per il Pi)
# Intonazione dei colpi nello stesso tiro: scala pentatonica in semitoni.
const HIT_STEPS := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]

var state: int = State.AIMING
var players := []
var current := 0
var balls := [] # paperelle in gioco nel tiro corrente
var targets_left := 0
var shots := 0
var portal_uses := 0
var stuck_count := 0
var recovered_this_shot := false
var debug_hit_pending := false
var result_time := 0.0
var scoring: Scoring
var field_seed := 0
var field_info := ""
var autoplay := ""
var level_path := ""
var rng := RandomNumberGenerator.new()
var textures := {}
var shot_hits := 0
var bursts := []
var next_burst := 0
var measure := false
var frame_times := []
var draw_calls_max := 0

onready var launcher = $Launcher
onready var bucket = $Bucket
onready var pegs_root = $Pegs
onready var balls_root = $Balls
onready var effects_root = $Effects
onready var hud = $HUD
onready var bounce_material: PhysicsMaterial = $Walls.physics_material_override


func _ready() -> void:
	rng.randomize()
	field_seed = Session.field_seed
	_parse_args()
	if field_seed == 0:
		field_seed = rng.randi_range(1, 999999)
	textures = SPRITES.duplicate()
	textures.glow = Textures.make_glow(64)
	textures.glow_material = CanvasItemMaterial.new()
	textures.glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_build_background()
	_build_bursts()
	Audio.play_music()
	var level: Dictionary = LevelLoader.load_level(level_path) if level_path else FieldGenerator.generate(field_seed)
	_create_players(level.balls)
	_build_field(level)
	launcher.connect("fire", self, "_on_launcher_fire")
	bucket.connect("ball_caught", self, "_on_ball_caught")
	if Session.debug_power:
		for player in players:
			player.power.activate(null, null)
	current = Session.first_player % players.size()
	_start_turn()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _parse_args() -> void:
	for arg in OS.get_cmdline_args():
		var value: String = arg.split("=")[1] if "=" in arg else ""
		if arg == "--autoplay":
			autoplay = "normal"
		elif arg.begins_with("--autoplay="):
			autoplay = "normal" if value == "smart" else value
		elif arg.begins_with("--cpu="):
			Session.mode = Session.MODE_CPU
			Session.cpu_difficulty = value
		elif arg.begins_with("--p1=") or arg.begins_with("--character="):
			Session.characters[0] = value
		elif arg.begins_with("--p2="):
			Session.characters[1] = value
		elif arg.begins_with("--seed="):
			field_seed = int(value)
			rng.seed = field_seed
		elif arg.begins_with("--level="):
			level_path = value
		elif arg == "--measure":
			measure = true


func _build_background() -> void:
	var background := Sprite.new()
	background.texture = BACKGROUND
	background.centered = false
	add_child(background)
	move_child(background, 0)


func _build_bursts() -> void:
	for i in BURSTS:
		var p := CPUParticles2D.new()
		p.emitting = false
		p.one_shot = true
		p.amount = 10
		p.lifetime = 0.45
		p.explosiveness = 1.0
		p.spread = 180.0
		p.initial_velocity = 110.0
		p.initial_velocity_random = 0.5
		p.gravity = Vector2(0, 260)
		p.scale_amount = 3.0
		effects_root.add_child(p)
		bursts.append(p)


func _burst(at: Vector2, color: Color) -> void:
	var p: CPUParticles2D = bursts[next_burst]
	next_burst = (next_burst + 1) % bursts.size()
	p.position = at
	p.color = color
	p.restart()


func _create_players(balls_each: int) -> void:
	for i in 2:
		var player := Player.new()
		player.index = i
		player.character = Characters.find(Session.characters[i])
		if player.character.empty():
			player.character = Characters.load_all()[i]
		player.power = PowerRegistry.create(player.character.power, self)
		player.balls_left = balls_each
		if autoplay:
			var levels := autoplay.split(",")
			player.cpu = CpuPlayer.new(levels[min(i, levels.size() - 1)], rng)
		elif i == 1 and Session.mode == Session.MODE_CPU:
			player.cpu = CpuPlayer.new(Session.cpu_difficulty, rng)
		players.append(player)


func _build_field(level: Dictionary) -> void:
	var group_nodes := []
	for data in level.groups:
		var group := PegGroup.new()
		group.position = data.position
		group.mode = data.mode
		group.speed = data.speed
		group.amplitude = data.amplitude
		group.axis = data.axis
		group.phase = data.phase
		pegs_root.add_child(group)
		group_nodes.append(group)
	# Bug e caffè scelti a caso tra i pioli, con un rng legato al campo: stesso seme = stessa sfida.
	var field_rng := RandomNumberGenerator.new()
	field_rng.seed = field_seed
	var order := range(level.pegs.size())
	_shuffle(order, field_rng)
	var kinds := {}
	for n in order.size():
		if n < level.targets:
			kinds[order[n]] = Peg.KIND_TARGET
		elif n < level.targets + level.powers:
			kinds[order[n]] = Peg.KIND_POWER
	for i in level.pegs.size():
		var data: Dictionary = level.pegs[i]
		var peg := Peg.new()
		peg.position = data.position
		peg.rotation = data.rotation
		peg.setup(data.shape, kinds.get(i, Peg.KIND_NORMAL), textures, bounce_material)
		var parent: Node = group_nodes[data.group] if data.group >= 0 else pegs_root
		parent.add_child(peg)
		if peg.is_target:
			targets_left += 1
	for pair in level.portals:
		var a := PortalScript.new()
		var b := PortalScript.new()
		a.position = pair[0]
		b.position = pair[1]
		a.color = PORTAL_COLORS[0]
		b.color = PORTAL_COLORS[1]
		a.partner = b
		b.partner = a
		a.connect("used", self, "_on_portal_used")
		b.connect("used", self, "_on_portal_used")
		pegs_root.add_child(a)
		pegs_root.add_child(b)
	scoring = Scoring.new(targets_left)
	field_info = "pioli %d gruppi %d portali %d" % [level.pegs.size(), level.groups.size(), level.portals.size()]


func _shuffle(array: Array, random: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := random.randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp


func _player() -> Reference:
	return players[current]


func _set_state(new_state: int) -> void:
	state = new_state
	launcher.enabled = state == State.AIMING and _player().cpu == null
	_update_hud()


func _start_turn() -> void:
	_set_state(State.AIMING)
	launcher.preview_bounces = _player().power.preview_bounces()
	if _player().cpu:
		_cpu_turn()


func _cpu_turn() -> void:
	var player = _player()
	var fast := autoplay != ""
	if not fast:
		yield(get_tree().create_timer(CPU_THINK_TIME), "timeout")
	var angle: float = player.cpu.choose_angle(self)
	if not fast:
		var tween := create_tween()
		tween.tween_property(launcher, "aim_angle", angle, CPU_AIM_TIME).set_trans(Tween.TRANS_SINE)
		yield(tween, "finished")
	launcher.aim_angle = angle
	if state == State.AIMING and _player() == player:
		_fire(launcher.direction())


# --- API usata dai poteri (vedi scripts/powers/power.gd) ---

func get_pegs() -> Array:
	return get_tree().get_nodes_in_group("pegs")


func spawn_ball(at: Vector2, velocity: Vector2) -> RigidBody2D:
	var ball := Ball.new()
	ball.setup(textures.duck, bounce_material)
	ball.position = at
	ball.linear_velocity = velocity
	ball.connect("touched", self, "_on_ball_touched")
	# Differito: i poteri possono creare paperelle durante una collisione, quando la fisica è bloccata.
	balls_root.call_deferred("add_child", ball)
	balls.append(ball)
	return ball


func hit_peg(peg: Node, ball: RigidBody2D) -> void:
	if not peg.hit():
		return
	var player = _player()
	var multiplier_before := scoring.multiplier()
	var points := scoring.peg_hit(peg.kind)
	player.score += points
	var pitch: float = pow(2.0, HIT_STEPS[min(shot_hits, HIT_STEPS.size() - 1)] / 12.0)
	shot_hits += 1
	match peg.kind:
		Peg.KIND_TARGET:
			Audio.play("bug", pitch)
			_burst(peg.global_position, Peg.COLORS[peg.kind])
		Peg.KIND_POWER:
			Audio.play("coffee")
			_burst(peg.global_position, Peg.COLORS[peg.kind])
		_:
			Audio.play("peg", pitch)
	_float_text(peg.global_position, Scoring.format(points), COLOR_TARGET_POINTS if peg.is_target else COLOR_POINTS)
	if peg.is_target:
		targets_left -= 1
		if targets_left == 0:
			_start_slowmo()
		elif scoring.multiplier() > multiplier_before:
			hud.flash("Moltiplicatore x%d!" % scoring.multiplier())
			Audio.play("multiplier")
	if peg.kind == Peg.KIND_POWER or debug_hit_pending:
		debug_hit_pending = false
		hud.flash("%s: %s!" % [player.character.name, player.character.power_name.to_upper()])
		player.powers_used += 1
		player.power.activate(ball, peg)
	_update_hud()


func add_effect(node: Node) -> void:
	effects_root.add_child(node)

# ---


func _on_launcher_fire(direction: Vector2) -> void:
	if state == State.AIMING and _player().cpu == null:
		_fire(direction)


func _fire(direction: Vector2) -> void:
	var player = _player()
	if player.balls_left <= 0:
		return
	player.balls_left -= 1
	shots += 1
	stuck_count = 0
	recovered_this_shot = false
	shot_hits = 0
	debug_hit_pending = Session.debug_power
	scoring.start_shot()
	player.power.on_shot_start()
	spawn_ball(launcher.position + direction * launcher.MUZZLE, direction * launcher.launch_speed)
	Audio.play("launch", rng.randf_range(0.95, 1.08))
	_set_state(State.BALL_IN_PLAY)


func _on_portal_used(_ball: Node) -> void:
	portal_uses += 1
	Audio.play("portal")


func _on_ball_touched(body: Node, ball: RigidBody2D) -> void:
	if body.has_method("hit"):
		hit_peg(body, ball)


func _start_slowmo() -> void:
	Engine.time_scale = SLOWMO_SCALE
	yield(get_tree().create_timer(SLOWMO_TIME), "timeout")
	Engine.time_scale = 1.0


func _on_ball_caught(ball: Node) -> void:
	if not ball in balls or state != State.BALL_IN_PLAY:
		return
	if not recovered_this_shot:
		# Al massimo una paperella recuperata per tiro, anche con Fork.
		recovered_this_shot = true
		_player().balls_left += 1
		hud.flash("Paperella recuperata!")
		Audio.play("bucket")
	_remove_ball(ball)


func _physics_process(delta: float) -> void:
	if state != State.BALL_IN_PLAY:
		return
	for ball in balls.duplicate():
		_player().power.on_ball_physics(ball, delta)
		if ball.position.y > FIELD_BOTTOM or ball.age > BALL_TIMEOUT:
			_remove_ball(ball)
		elif ball.slow_time > STUCK_TIME:
			# Paperella incastrata: si tolgono subito i pioli già colpiti.
			ball.slow_time = 0.0
			stuck_count += 1
			for peg in get_pegs():
				if peg.lit:
					peg.pop()
			if stuck_count >= NUDGE_AFTER:
				ball.apply_central_impulse(Vector2(rng.randf_range(-80, 80), -120))


func _process(delta: float) -> void:
	if measure and state != State.FINISHED:
		frame_times.append(delta)
		draw_calls_max = int(max(draw_calls_max, Performance.get_monitor(Performance.RENDER_2D_DRAW_CALLS_IN_FRAME)))


func _print_measure() -> void:
	if frame_times.size() < 10:
		return
	var sorted := frame_times.duplicate()
	sorted.sort()
	var total := 0.0
	for t in sorted:
		total += t
	var n := sorted.size()
	var low1: float = 1.0 / sorted[int(n * 0.99)]
	print("PRESTAZIONI fps medi %.1f | 1%% low %.1f | min %.1f | draw call max %d | durata %.0fs | %s" % [
		n / total, low1, 1.0 / sorted[n - 1], draw_calls_max, total, VisualServer.get_video_adapter_name()])


func _remove_ball(ball: RigidBody2D) -> void:
	balls.erase(ball)
	ball.queue_free()
	if balls.empty() and state == State.BALL_IN_PLAY:
		_end_shot()


func _end_shot() -> void:
	Engine.time_scale = 1.0
	_player().power.on_shot_end()
	_set_state(State.CLEARING)
	_clear_lit_pegs()


func _clear_lit_pegs() -> void:
	for peg in get_pegs():
		if is_instance_valid(peg) and peg.lit and not peg.popping:
			peg.pop()
			yield(get_tree().create_timer(POP_INTERVAL), "timeout")
	var player = _player()
	var extra := scoring.extra_balls_for_shot()
	if extra > 0:
		player.balls_left += extra
		player.extra_balls_won += extra
		Audio.play("extra")
		hud.flash("Paperella extra per %s!" % player.character.name if extra == 1 else "%d paperelle extra per %s!" % [extra, player.character.name])
	if targets_left <= 0:
		_ball_bonus()
	elif _total_balls_left() <= 0:
		_finish()
	else:
		_next_turn()


func _total_balls_left() -> int:
	var total := 0
	for player in players:
		total += player.balls_left
	return total


# Il turno passa all'altro giocatore, se ha ancora paperelle.
func _next_turn() -> void:
	var other := (current + 1) % players.size()
	if players[other].balls_left > 0 and other != current:
		current = other
		hud.flash("Tocca a %s" % _player().label())
		Audio.play("click")
	_start_turn()


# Bug finiti: ogni paperella rimasta vale punti per il suo giocatore.
func _ball_bonus() -> void:
	_set_state(State.BONUS)
	for i in players.size():
		var player = players[i]
		current = i
		player.bonus_balls = player.balls_left
		while player.balls_left > 0:
			yield(get_tree().create_timer(BALL_BONUS_INTERVAL), "timeout")
			player.balls_left -= 1
			player.score += Scoring.BALL_BONUS
			Audio.play("extra", 1.0 + 0.05 * player.balls_left)
			_float_text(launcher.position + Vector2(0, 40), "+" + Scoring.format(Scoring.BALL_BONUS), COLOR_BONUS)
			_update_hud()
	yield(get_tree().create_timer(BALL_BONUS_INTERVAL), "timeout")
	_finish()


func _finish() -> void:
	current = -1
	_set_state(State.FINISHED)
	result_time = OS.get_ticks_msec() / 1000.0
	var best := -1
	var tie := false
	for i in players.size():
		if best < 0 or players[i].score > players[best].score:
			best = i
			tie = false
		elif players[i].score == players[best].score:
			tie = true
	var title: String = "Pareggio!" if tie else "Vince %s!" % players[best].label()
	var lines := []
	for player in players:
		var line: String = "%s: %s" % [player.label(), Scoring.format(player.score)]
		if player.bonus_balls > 0:
			line += "  (bonus %d × %s)" % [player.bonus_balls, Scoring.format(Scoring.BALL_BONUS)]
		lines.append(line)
	if targets_left > 0:
		lines.append("Paperelle finite con %d bug ancora aperti" % targets_left)
	lines.append("")
	lines.append("Campo #%d" % field_seed)
	lines.append("")
	lines.append("A / click: nuovo campo · R: rivincita · Esc: menu")
	hud.show_result(title, lines)
	Audio.play("win")
	if measure:
		_print_measure()
	if autoplay:
		print("AUTOPLAY vincitore %s | tiri %d | G1 %s %d poteri %d | G2 %s %d poteri %d | bug rimasti %d | campo %d | %s | portali usati %d" % [
			"pari" if tie else "G%d" % (best + 1), shots,
			players[0].character.id, players[0].score, players[0].powers_used,
			players[1].character.id, players[1].score, players[1].powers_used,
			targets_left, field_seed, field_info, portal_uses])
		if not Session.screenshot_path:
			get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene(MENU_SCENE)
	elif state == State.FINISHED and OS.get_ticks_msec() / 1000.0 - result_time > RESTART_DELAY:
		if event is InputEventKey and event.pressed and event.scancode == KEY_R:
			# Rivincita sullo stesso campo, inizia l'altro giocatore.
			Session.field_seed = field_seed
			Session.first_player = (Session.first_player + 1) % 2
			get_tree().reload_current_scene()
		elif _is_confirm(event):
			Session.field_seed = 0
			get_tree().reload_current_scene()


func _is_confirm(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return not event.pressed and event.button_index == BUTTON_LEFT
	return event.is_action_pressed("ui_accept")


func _update_hud() -> void:
	if not scoring:
		return
	hud.update_players(players, current)
	hud.update_field(targets_left, scoring.multiplier())


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
