extends Reference
# Avversario controllato dal computer.
#
#   random   tiri a caso (solo per i test)
#   easy     mira a un bug a caso con la parabola, molto impreciso
#   normal   come easy, ma più preciso
#   hard     calcola la mira per ogni bug e caffè, simula i rimbalzi di ciascun tiro
#            e sceglie quello che promette di più (i primi urti contano di più: sono i più affidabili)

const Trajectory := preload("res://scripts/game/trajectory.gd")

const NOISE := {"easy": 0.12, "normal": 0.035, "hard": 0.01}
const HARD_OFFSETS := [-0.03, 0.0, 0.03] # varianti attorno alla mira esatta (radianti)
const HARD_BOUNCES := 5
const HARD_STEPS := 200
const HIT_VALUE := {"target": 10.0, "power": 6.0, "normal": 1.0}
const HIT_DECAY := 0.7 # peso dell'urto n-esimo = HIT_DECAY^n

var difficulty := "normal"
var rng: RandomNumberGenerator


func _init(level: String, random: RandomNumberGenerator) -> void:
	difficulty = level
	rng = random


func choose_angle(game: Node) -> float:
	var launcher = game.launcher
	match difficulty:
		"random":
			return rng.randf_range(-launcher.MAX_AIM_ANGLE, launcher.MAX_AIM_ANGLE)
		"hard":
			return _best_simulated_angle(game) + rng.randf_range(-NOISE.hard, NOISE.hard)
		_:
			var noise: float = NOISE.get(difficulty, NOISE.normal)
			return _parabola_angle(game) + rng.randf_range(-noise, noise)


# Sceglie un bug a caso e mira dritto su di lui.
func _parabola_angle(game: Node) -> float:
	var targets := _open_pegs(game, false)
	if targets.empty():
		return 0.0
	var target: Node2D = targets[rng.randi_range(0, targets.size() - 1)]
	var angle = aim_angle_to(game.launcher, target.global_position)
	return angle if angle != null else 0.0


# Prova la mira esatta su ogni bug e caffè (più piccole varianti), simulando i rimbalzi.
func _best_simulated_angle(game: Node) -> float:
	var launcher = game.launcher
	var space: Physics2DDirectSpaceState = game.get_world_2d().direct_space_state
	var best_angle := 0.0
	var best_value := -1.0
	for peg in _open_pegs(game, true):
		var aim = aim_angle_to(launcher, peg.global_position)
		if aim == null:
			continue
		for offset in HARD_OFFSETS:
			var angle: float = clamp(aim + offset, -launcher.MAX_AIM_ANGLE, launcher.MAX_AIM_ANGLE)
			var dir := Vector2.DOWN.rotated(angle)
			var result := Trajectory.simulate(space, launcher.global_position + dir * launcher.MUZZLE,
					dir * launcher.launch_speed, HARD_BOUNCES, HARD_STEPS, 500.0)
			var value := 0.0
			var weight := 1.0
			for body in result.hits:
				if body.has_method("hit"):
					if not body.lit:
						value += HIT_VALUE[body.kind] * weight
					weight *= HIT_DECAY
			if value > best_value:
				best_value = value
				best_angle = angle
	return best_angle


func _open_pegs(game: Node, include_power: bool) -> Array:
	var list := []
	for peg in game.get_pegs():
		if not peg.lit and not peg.popping and (peg.is_target or (include_power and peg.kind == "power")):
			list.append(peg)
	return list


# Angolo (0 = verso il basso) per cui la parabola del lancio passa per `target`,
# risolvendo l'equazione del moto parabolico. Preferisce la traiettoria più tesa.
# Restituisce null se il punto non è raggiungibile.
static func aim_angle_to(launcher: Node2D, target: Vector2):
	var rel := target - launcher.global_position
	var v: float = launcher.launch_speed
	var g: float = ProjectSettings.get_setting("physics/2d/default_gravity")
	var x := abs(rel.x)
	if x < 0.5:
		return 0.0 if rel.y > 0.0 else null
	var y_up := -rel.y
	var disc := v * v * v * v - g * (g * x * x + 2.0 * y_up * v * v)
	if disc < 0.0:
		return null
	for side in [-1.0, 1.0]:
		var phi := atan((v * v + side * sqrt(disc)) / (g * x))
		var screen_dir := Vector2(cos(phi), -sin(phi))
		var angle := Vector2.DOWN.angle_to(screen_dir)
		if abs(angle) <= launcher.MAX_AIM_ANGLE:
			return angle if rel.x > 0.0 else -angle
	return null
