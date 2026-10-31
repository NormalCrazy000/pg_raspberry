extends Node2D
# Sfida a turni: due giocatori (persone o CPU) tirano a turno sullo stesso campo.
# I punti vanno a chi tira, il moltiplicatore è condiviso. La sfida finisce quando
# i bug sono tutti eliminati o nessuno ha più paperelle: vince chi ha più punti.
# In allenamento c'è un solo giocatore: alla fine prende da 0 a 3 stelle in base al punteggio.
#
# Le impostazioni arrivano dal menu (Session); da riga di comando si possono forzare:
#   --autoplay[=random|easy|normal|hard]   entrambi i giocatori sono CPU (default normal), stampa il risultato ed esce;
#                                          con due valori separati da virgola (es. hard,easy) uno per giocatore
#   --cpu=easy|normal|hard                 il giocatore 2 è la CPU
#   --training                             allenamento in singolo (con --autoplay il giocatore è la CPU)
#   --p1=ID (oppure --character=ID), --p2=ID   personaggi (id in data/characters.json)
#   --seed=N                               campo e tiri della CPU riproducibili
#   --level=res://levels/level_01.json     campo fisso da JSON invece che generato
#   --measure                              misura FPS e draw call durante la sfida e li stampa alla fine
#                                          (da usare con --autoplay, a tempo reale: è il benchmark della partita vera)
# Altre opzioni globali (--screenshot, --debug-power) in scripts/session.gd.

enum State { AIMING, BALL_IN_PLAY, CLEARING, BONUS, FINISHED }

const Textures := preload("res://scripts/common/textures.gd")
const Backgrounds := preload("res://scripts/common/backgrounds.gd")
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
const SPIKE_MIN := 0.05 # s: un frame più lungo di così si nota come un blocco...
const SPIKE_FACTOR := 2.5 # ...se dura anche almeno 2,5 volte un frame tipico
const MEASURE_WARMUP := 1.0 # s: il primo secondo (caricamento della scena) non conta
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
var training := false
var stars := [] # soglie di punteggio per 1, 2 e 3 stelle (allenamento)
var rng := RandomNumberGenerator.new()
var textures := {}
var shot_hits := 0
var shot_bug_positions := [] # bug colpiti nel tiro corrente (per il bonus "tiro lungo")
var shot_bonuses := [] # bonus già assegnati nel tiro corrente
var bursts := []
var next_burst := 0
var measure := false
var low_graphics := false
var frame_tags := [] # cosa è successo dall'ultimo frame (solo con --measure)
var spikes := [] # [durata, eventi] dei frame (possibili picchi; filtrati alla fine)
var measure_time := 0.0
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
	training = Session.mode == Session.MODE_TRAINING
	if field_seed == 0:
		field_seed = rng.randi_range(1, 999999)
	low_graphics = Settings.low_graphics()
	textures = SPRITES.duplicate()
	if not low_graphics:
		textures.glow = Textures.make_glow(64)
		textures.glow_material = CanvasItemMaterial.new()
		textures.glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_build_background()
	if not low_graphics:
		_build_bursts()
	Audio.play_music()
	var level: Dictionary = LevelLoader.load_level(level_path) if level_path else FieldGenerator.generate(field_seed)
	stars = level.get("stars", [])
	if stars.size() != 3:
		stars = FieldGenerator.STARS
	_create_players(level.balls)
	_build_field(level)
	launcher.connect("fire", self, "_on_launcher_fire")
	bucket.connect("ball_caught", self, "_on_ball_caught")
	hud.connect("menu_choice", self, "_on_menu_choice")
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
		elif arg == "--training":
			Session.mode = Session.MODE_TRAINING
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
	background.texture = Backgrounds.for_seed(field_seed)
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
	if bursts.empty():
		return
	var p: CPUParticles2D = bursts[next_burst]
	next_burst = (next_burst + 1) % bursts.size()
	p.position = at
	p.color = color
	p.restart()


func _create_players(balls_each: int) -> void:
	for i in 1 if training else 2:
		var player := Player.new()
		player.index = i
		player.solo = training
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
		yield(get_tree().create_timer(CPU_THINK_TIME, false), "timeout")
	mark_perf("cpu")
	var angle: float = yield(player.cpu.decide(self), "completed")
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
	mark_perf("paperella")
	var ball := Ball.new()
	ball.setup(textures.duck, bounce_material, not low_graphics)
	ball.position = at
	ball.linear_velocity = velocity
	ball.connect("touched", self, "_on_ball_touched")
	# Differito: i poteri possono creare paperelle durante una collisione, quando la fisica è bloccata.
	balls_root.call_deferred("add_child", ball)
	balls.append(ball)
	return ball


# `direct` è false quando il piolo è acceso da un potere (es. onda d'urto) e non toccato da una paperella.
func hit_peg(peg: Node, ball: RigidBody2D, direct := true) -> void:
	if not peg.hit():
		return
	if direct and ball:
		ball.hits += 1
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
	_check_shot_bonuses(peg, ball if direct else null)
	if peg.is_target:
		targets_left -= 1
		if targets_left == 0:
			_start_slowmo()
		elif scoring.multiplier() > multiplier_before:
			hud.flash(tr("FLASH_MULTIPLIER") % scoring.multiplier())
			Audio.play("multiplier")
	if (peg.kind == Peg.KIND_POWER and player.power.can_activate()) or debug_hit_pending:
		debug_hit_pending = false
		hud.flash("%s: %s!" % [player.character.name, player.character.power_name.to_upper()])
		player.powers_used += 1
		mark_perf("potere " + player.character.power)
		player.power.activate(ball, peg)
	_update_hud()


# Bonus "tiro lungo" (due bug lontani nello stesso tiro) e "combo" (tanti pioli toccati da una paperella).
func _check_shot_bonuses(peg: Node, ball: RigidBody2D) -> void:
	if peg.is_target and not "long" in shot_bonuses:
		for other in shot_bug_positions:
			if other.distance_to(peg.global_position) >= Scoring.LONG_SHOT_DISTANCE:
				_award_bonus("long", tr("FLASH_LONG_SHOT"), Scoring.LONG_SHOT_BONUS, peg.global_position)
				break
		shot_bug_positions.append(peg.global_position)
	# La combo conta i pioli toccati da una stessa paperella (non quelli accesi dai poteri).
	if ball and ball.hits >= Scoring.COMBO_PEGS and not "combo" in shot_bonuses:
		_award_bonus("combo", tr("FLASH_COMBO") % ball.hits, Scoring.COMBO_BONUS, peg.global_position)


func _award_bonus(id: String, text: String, base: int, at: Vector2) -> void:
	shot_bonuses.append(id)
	var points := scoring.bonus(base)
	_player().score += points
	_player().bonuses += 1
	hud.flash("%s +%s" % [text, Scoring.format(points)])
	_float_text(at + Vector2(0, -18), "+" + Scoring.format(points), COLOR_BONUS)
	Audio.play("extra", 1.2)
	mark_perf("bonus")


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
	shot_bug_positions.clear()
	shot_bonuses.clear()
	debug_hit_pending = Session.debug_power
	scoring.start_shot()
	player.power.on_shot_start()
	spawn_ball(launcher.position + direction * launcher.MUZZLE, direction * launcher.launch_speed)
	Audio.play("launch", rng.randf_range(0.95, 1.08))
	_set_state(State.BALL_IN_PLAY)


func _on_portal_used(_ball: Node) -> void:
	portal_uses += 1
	mark_perf("portale")
	Audio.play("portal")


func _on_ball_touched(body: Node, ball: RigidBody2D) -> void:
	if body.has_method("hit"):
		hit_peg(body, ball)


func _start_slowmo() -> void:
	mark_perf("rallentatore")
	Engine.time_scale = SLOWMO_SCALE
	yield(get_tree().create_timer(SLOWMO_TIME, false), "timeout")
	Engine.time_scale = 1.0


func _on_ball_caught(ball: Node) -> void:
	if not ball in balls or state != State.BALL_IN_PLAY:
		return
	if not recovered_this_shot:
		# Al massimo una paperella recuperata per tiro, anche con Fork.
		recovered_this_shot = true
		_player().balls_left += 1
		hud.flash(tr("FLASH_RECOVERED"))
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


# Annota un evento del frame corrente: con --measure i frame più lenti vengono stampati con i loro eventi.
func mark_perf(tag: String) -> void:
	if measure and not tag in frame_tags:
		frame_tags.append(tag)


func _process(delta: float) -> void:
	if measure and state != State.FINISHED:
		measure_time += delta
		if measure_time > MEASURE_WARMUP:
			frame_times.append(delta)
			draw_calls_max = int(max(draw_calls_max, Performance.get_monitor(Performance.RENDER_2D_DRAW_CALLS_IN_FRAME)))
			if delta > SPIKE_MIN:
				spikes.append([delta, PoolStringArray(frame_tags).join(", ") if frame_tags else "-"])
		frame_tags.clear()


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
	var typical: float = sorted[n / 2]
	print("PRESTAZIONI fps medi %.1f | 1%% low %.1f | min %.1f | draw call max %d | durata %.0fs | grafica %s | %s" % [
		n / total, low1, 1.0 / sorted[n - 1], draw_calls_max, total, "bassa" if low_graphics else "alta",
		VisualServer.get_video_adapter_name()])
	# I frame più lenti, con quello che stava succedendo: servono a capire i blocchi.
	var threshold: float = max(SPIKE_MIN, typical * SPIKE_FACTOR)
	var real_spikes := []
	for spike in spikes:
		if spike[0] > threshold:
			real_spikes.append(spike)
	spikes = real_spikes
	spikes.sort_custom(self, "_slower_first")
	print("PICCHI %d frame oltre %d ms (frame tipico %.0f ms) | vsync %s" % [
		spikes.size(), threshold * 1000, typical * 1000, "sì" if OS.vsync_enabled else "no"])
	for spike in spikes.slice(0, min(spikes.size(), 8) - 1):
		print("  %4.0f ms  %s" % [spike[0] * 1000.0, spike[1]])


func _slower_first(a: Array, b: Array) -> bool:
	return a[0] > b[0]


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
			mark_perf("pioli via")
			peg.pop()
			yield(get_tree().create_timer(POP_INTERVAL, false), "timeout")
	var player = _player()
	var extra := scoring.extra_balls_for_shot()
	if extra > 0:
		player.balls_left += extra
		player.extra_balls_won += extra
		Audio.play("extra")
		hud.flash(tr("FLASH_EXTRA_ONE") % player.character.name if extra == 1 else tr("FLASH_EXTRA_MANY") % [extra, player.character.name])
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
	mark_perf("cambio turno")
	var other := (current + 1) % players.size()
	if players[other].balls_left > 0 and other != current:
		current = other
		hud.flash(tr("FLASH_TURN") % _player().label())
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
			yield(get_tree().create_timer(BALL_BONUS_INTERVAL, false), "timeout")
			player.balls_left -= 1
			player.score += Scoring.BALL_BONUS
			Audio.play("extra", 1.0 + 0.05 * player.balls_left)
			_float_text(launcher.position + Vector2(0, 40), "+" + Scoring.format(Scoring.BALL_BONUS), COLOR_BONUS)
			_update_hud()
	yield(get_tree().create_timer(BALL_BONUS_INTERVAL, false), "timeout")
	_finish()


func _finish() -> void:
	current = -1
	_set_state(State.FINISHED)
	result_time = OS.get_ticks_msec() / 1000.0
	if training:
		_finish_training()
		return
	var best := -1
	var tie := false
	for i in players.size():
		if best < 0 or players[i].score > players[best].score:
			best = i
			tie = false
		elif players[i].score == players[best].score:
			tie = true
	var title: String = tr("RESULT_TIE") if tie else tr("RESULT_WINNER") % players[best].label()
	var lines := []
	for player in players:
		var line: String = "%s: %s" % [player.label(), Scoring.format(player.score)]
		if player.bonus_balls > 0:
			line += "  " + tr("RESULT_BONUS") % [player.bonus_balls, Scoring.format(Scoring.BALL_BONUS)]
		lines.append(line)
	if targets_left > 0:
		lines.append(tr("RESULT_OPEN_BUGS") % targets_left)
	lines.append("")
	lines.append(tr("RESULT_FIELD") % field_seed)
	mark_perf("fine sfida")
	hud.show_result(title, lines)
	Audio.play("win")
	if not autoplay:
		var cpu_difficulty: String = Session.cpu_difficulty if Session.mode == Session.MODE_CPU else ""
		Stats.record_match(players, -1 if tie else best, scoring.targets_hit, cpu_difficulty)
	if measure:
		_print_measure()
	if autoplay:
		print("AUTOPLAY vincitore %s | tiri %d | G1 %s %d poteri %d | G2 %s %d poteri %d | bonus %d | bug rimasti %d | campo %d | %s | portali usati %d" % [
			"pari" if tie else "G%d" % (best + 1), shots,
			players[0].character.id, players[0].score, players[0].powers_used,
			players[1].character.id, players[1].score, players[1].powers_used, players[0].bonuses + players[1].bonuses,
			targets_left, field_seed, field_info, portal_uses])
		if not Session.screenshot_path:
			get_tree().quit()


# Fine dell'allenamento: punteggio, stelle e record personale.
func _finish_training() -> void:
	var player = players[0]
	var earned := 0
	for threshold in stars:
		if player.score >= int(threshold):
			earned += 1
	var lines := [tr("RESULT_SCORE") % Scoring.format(player.score)]
	if player.bonus_balls > 0:
		lines[0] += "  " + tr("RESULT_BONUS") % [player.bonus_balls, Scoring.format(Scoring.BALL_BONUS)]
	# Il font non ha la stella: piene ● e vuote ○.
	var dots := ""
	for i in 3:
		dots += "●" if i < earned else "○"
	var star_line: String = tr("RESULT_STARS") % dots
	if earned < 3:
		star_line += "  " + tr("RESULT_NEXT_STAR") % Scoring.format(int(stars[earned]))
	lines.append(star_line)
	if targets_left > 0:
		lines.append(tr("RESULT_OPEN_BUGS") % targets_left)
	if not autoplay:
		var previous: int = Stats.training_best()
		Stats.record_training(player, earned, scoring.targets_hit)
		if player.score > previous:
			lines.append(tr("RESULT_NEW_RECORD"))
		else:
			lines.append(tr("RESULT_RECORD") % Scoring.format(previous))
	lines.append("")
	lines.append(tr("RESULT_FIELD") % field_seed)
	mark_perf("fine sfida")
	hud.show_result(tr("RESULT_TRAINING_DONE") if targets_left <= 0 else tr("RESULT_TRAINING_OVER"), lines, true)
	Audio.play("win")
	if measure:
		_print_measure()
	if autoplay:
		print("AUTOPLAY allenamento %s %d stelle %d | tiri %d | poteri %d | bonus %d | bug rimasti %d | campo %d | %s" % [
			player.character.id, player.score, earned, shots, player.powers_used, player.bonuses,
			targets_left, field_seed, field_info])
		if not Session.screenshot_path:
			get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and state != State.FINISHED:
		get_tree().set_input_as_handled()
		hud.show_pause()
	elif state == State.FINISHED and OS.get_ticks_msec() / 1000.0 - result_time > RESTART_DELAY:
		if event is InputEventKey and event.pressed and event.scancode == KEY_R:
			_on_menu_choice("rematch")
		elif event.is_action_pressed("pause"):
			_on_menu_choice("menu")


# Scelte dal menu di pausa e dalla schermata finale.
func _on_menu_choice(choice: String) -> void:
	get_tree().paused = false
	match choice:
		"new":
			Session.field_seed = 0
			get_tree().reload_current_scene()
		"rematch":
			# Stesso campo, inizia l'altro giocatore.
			Session.field_seed = field_seed
			Session.first_player = (Session.first_player + 1) % 2
			get_tree().reload_current_scene()
		"restart":
			Session.field_seed = field_seed
			get_tree().reload_current_scene()
		"menu":
			get_tree().change_scene(MENU_SCENE)


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
