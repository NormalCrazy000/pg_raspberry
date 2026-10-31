extends Reference
# Genera un campo di gioco da un seme: stesso seme = stesso campo.
#
# Il campo è composto da "figure" (archi, griglie, rampe, anelli fissi o rotanti, file che scorrono)
# piazzate a caso senza sovrapporsi, spesso in modo simmetrico. Può contenere una coppia di portali.
# Il risultato ha lo stesso formato di level_loader.gd, più "groups" e "portals":
#   pegs:    [{shape, position, rotation, group}]   group = indice in groups oppure -1
#   groups:  [{position, mode, speed, amplitude, axis, phase}]
#   portals: [[posizione_a, posizione_b], ...]

const AREA := Rect2(50, 95, 700, 330) # dove possono stare i pioli
const LAUNCHER_CLEARANCE := Rect2(330, 0, 140, 125) # spazio libero sotto il cannone
const CENTER_X := 400.0
const MIN_DIST_ROUND := 34.0 # distanza minima tra centri di pioli tondi (la paperella deve passare)
const MIN_DIST_RECT := 36.0 # se uno dei due è rettangolare
const PORTAL_CLEARANCE := 40.0
const TARGET_PEGS := 64
const MAX_ATTEMPTS := 400
const SYMMETRY_CHANCE := 0.8
const PORTAL_CHANCE := 0.6

const DEFAULTS := {
	"name": "",
	"balls": 8, # paperelle per giocatore
	"targets": 20,
	"powers": 2,
}
# Soglie di punteggio per 1, 2 e 3 stelle in allenamento sui campi generati. Con 40 allenamenti automatici
# per livello (e il dimezzamento dei tiri senza bug) la CPU normale fa a metà classifica 18.000 punti,
# la difficile 31.000 (100.000 nel 10% migliore).
const STARS := [15000, 35000, 100000]

var rng := RandomNumberGenerator.new()
var pegs := []
var groups := []
var portals := []
# Punti occupati (anche le posizioni attraversate dai pioli in movimento): [posizione, è_rettangolo]
var occupied := []


static func generate(seed_value: int) -> Dictionary:
	var generator = load("res://scripts/game/field_generator.gd").new()
	return generator._generate(seed_value)


func _generate(seed_value: int) -> Dictionary:
	rng.seed = seed_value
	var symmetric := rng.randf() < SYMMETRY_CHANCE
	var attempts := 0
	while pegs.size() < TARGET_PEGS and attempts < MAX_ATTEMPTS:
		attempts += 1
		var feature := _random_feature(symmetric)
		if feature.empty():
			continue
		if symmetric and feature.center.x < CENTER_X - 20.0:
			var mirrored := _mirror(feature)
			if _fits(feature.samples, feature.pegs) and _fits(mirrored.samples, mirrored.pegs) \
					and not _overlap(feature.samples, mirrored.samples):
				_add(feature)
				_add(mirrored)
		elif _fits(feature.samples, feature.pegs):
			_add(feature)
	if rng.randf() < PORTAL_CHANCE:
		_add_portals(symmetric)
	var level := DEFAULTS.duplicate()
	level.name = "Campo #%d" % seed_value
	level.pegs = pegs
	level.groups = groups
	level.portals = portals
	return level


# --- Figure ---

func _random_feature(symmetric: bool) -> Dictionary:
	# Con la simmetria le figure nascono nella metà sinistra (e vengono specchiate) o sull'asse centrale.
	var on_axis: bool = symmetric and rng.randf() < 0.3
	var center := Vector2(
		CENTER_X if on_axis else rng.randf_range(AREA.position.x + 40, (CENTER_X - 60) if symmetric else AREA.end.x - 40),
		rng.randf_range(AREA.position.y + 30, AREA.end.y - 30))
	match rng.randi_range(0, 5):
		0:
			return _arc(center, on_axis)
		1:
			return _grid(center)
		2:
			return _ramp(center)
		3:
			return _ring(center, false)
		4:
			return _ring(center, true)
		_:
			return _slider(center)


func _arc(center: Vector2, on_axis: bool) -> Dictionary:
	var radius := rng.randf_range(70, 170)
	var span := deg2rad(rng.randf_range(60, 150))
	# Sull'asse l'arco è centrato verso l'alto (simmetrico di suo).
	var mid := -PI / 2.0 if on_axis else rng.randf_range(-PI, PI)
	var count := int(clamp(radius * span / 38.0, 3, 12))
	var arc_center: Vector2 = center + Vector2(0, radius * 0.6) if on_axis else center
	var list := []
	for i in count:
		var angle: float = mid - span / 2.0 + span * i / max(1, count - 1)
		list.append(_peg("round", arc_center + Vector2(cos(angle), sin(angle)) * radius, 0.0))
	return _static_feature(center, list)


func _grid(center: Vector2) -> Dictionary:
	var rows := rng.randi_range(2, 3)
	var cols := rng.randi_range(3, 6)
	var step := Vector2(rng.randf_range(40, 56), rng.randf_range(38, 50))
	var origin := center - Vector2((cols - 1) * step.x, (rows - 1) * step.y) / 2.0
	var list := []
	for r in rows:
		var shifted: bool = r % 2 == 1
		for c in (cols - 1 if shifted else cols):
			var offset: float = step.x / 2.0 if shifted else 0.0
			list.append(_peg("round", origin + Vector2(c * step.x + offset, r * step.y), 0.0))
	return _static_feature(center, list)


func _ramp(center: Vector2) -> Dictionary:
	var count := rng.randi_range(3, 5)
	var angle := deg2rad(rng.randf_range(-35, 35))
	var dir := Vector2(cos(angle), sin(angle))
	var spacing := 40.0
	var list := []
	for i in count:
		list.append(_peg("rect", center + dir * (i - (count - 1) / 2.0) * spacing, angle))
	return _static_feature(center, list)


func _ring(center: Vector2, rotating: bool) -> Dictionary:
	var radius := rng.randf_range(38, 60)
	var count := int(clamp(TAU * radius / 40.0, 6, 9))
	var list := []
	for i in count:
		var angle: float = TAU * i / count
		list.append(_peg("round", Vector2(cos(angle), sin(angle)) * radius, 0.0))
	if not rotating:
		for peg in list:
			peg.position += center
		return _static_feature(center, list)
	var speed: float = rng.randf_range(0.6, 1.2) * (1 if rng.randf() < 0.5 else -1)
	var group := {"position": center, "mode": "rotate", "speed": speed, "amplitude": 0.0, "axis": Vector2.RIGHT, "phase": 0.0}
	# Ruotando, i pioli passano per tutto il cerchio: lo campioniamo come spazio occupato.
	var samples := []
	for i in 16:
		var a: float = TAU * i / 16.0
		samples.append([center + Vector2(cos(a), sin(a)) * radius, false])
	samples.append([center, false])
	return {"center": center, "pegs": list, "group": group, "samples": samples}


func _slider(center: Vector2) -> Dictionary:
	var count := rng.randi_range(2, 4)
	var spacing := 44.0
	var amplitude := rng.randf_range(35, 70)
	var list := []
	for i in count:
		list.append(_peg("round", Vector2((i - (count - 1) / 2.0) * spacing, 0), 0.0))
	var group := {"position": center, "mode": "slide", "speed": rng.randf_range(0.8, 1.5), "amplitude": amplitude,
			"axis": Vector2.RIGHT, "phase": rng.randf_range(0, TAU)}
	var samples := []
	for peg in list:
		for t in [-1.0, -0.5, 0.0, 0.5, 1.0]:
			samples.append([center + peg.position + Vector2(amplitude * t, 0), false])
	return {"center": center, "pegs": list, "group": group, "samples": samples}


func _static_feature(center: Vector2, list: Array) -> Dictionary:
	var samples := []
	for peg in list:
		samples.append([peg.position, peg.shape == "rect"])
	return {"center": center, "pegs": list, "group": {}, "samples": samples}


func _peg(shape: String, position: Vector2, rotation: float) -> Dictionary:
	return {"shape": shape, "position": position, "rotation": rotation, "group": -1}


# Copia speculare rispetto all'asse verticale centrale.
func _mirror(feature: Dictionary) -> Dictionary:
	var moving: bool = not feature.group.empty()
	var list := []
	for peg in feature.pegs:
		var p: Vector2 = peg.position
		# I pioli dei gruppi hanno coordinate locali: si specchia solo la x locale.
		var mirrored_pos: Vector2 = Vector2(-p.x, p.y) if moving else Vector2(2.0 * CENTER_X - p.x, p.y)
		list.append(_peg(peg.shape, mirrored_pos, PI - peg.rotation if peg.shape == "rect" else 0.0))
	var samples := []
	for sample in feature.samples:
		samples.append([Vector2(2.0 * CENTER_X - sample[0].x, sample[0].y), sample[1]])
	var group := {}
	if moving:
		group = feature.group.duplicate()
		group.position = Vector2(2.0 * CENTER_X - group.position.x, group.position.y)
		if group.mode == "rotate":
			group.speed = -group.speed
		else:
			group.phase = group.phase + PI
	return {"center": Vector2(2.0 * CENTER_X - feature.center.x, feature.center.y), "pegs": list, "group": group, "samples": samples}


# --- Spazio libero ---

func _fits(samples: Array, new_pegs: Array) -> bool:
	if new_pegs.empty():
		return false
	for sample in samples:
		var p: Vector2 = sample[0]
		if not AREA.has_point(p) or LAUNCHER_CLEARANCE.has_point(p):
			return false
		for other in occupied:
			var min_dist: float = MIN_DIST_RECT if sample[1] or other[1] else MIN_DIST_ROUND
			if p.distance_to(other[0]) < min_dist:
				return false
	return true


# Una figura e la sua copia speculare non devono toccarsi.
func _overlap(a: Array, b: Array) -> bool:
	for sa in a:
		for sb in b:
			var min_dist: float = MIN_DIST_RECT if sa[1] or sb[1] else MIN_DIST_ROUND
			if sa[0].distance_to(sb[0]) < min_dist:
				return true
	return false


func _add(feature: Dictionary) -> void:
	var group_index := -1
	if not feature.group.empty():
		groups.append(feature.group)
		group_index = groups.size() - 1
	for peg in feature.pegs:
		peg.group = group_index
		pegs.append(peg)
	occupied += feature.samples


func _add_portals(symmetric: bool) -> void:
	for _attempt in 60:
		var a := Vector2(rng.randf_range(AREA.position.x, CENTER_X - 80), rng.randf_range(AREA.position.y + 60, AREA.end.y))
		var b: Vector2 = Vector2(2.0 * CENTER_X - a.x, a.y) if symmetric else Vector2(
				rng.randf_range(CENTER_X + 80, AREA.end.x), rng.randf_range(AREA.position.y + 60, AREA.end.y))
		if _portal_free(a) and _portal_free(b):
			portals.append([a, b])
			return


func _portal_free(p: Vector2) -> bool:
	if LAUNCHER_CLEARANCE.has_point(p):
		return false
	for other in occupied:
		if p.distance_to(other[0]) < PORTAL_CLEARANCE:
			return false
	return true
