extends Reference
# Punteggio: punti per piolo, moltiplicatore legato agli obiettivi eliminati,
# palle extra per i tiri ad alto punteggio, bonus palle rimaste e stelle.

const POINTS := {"normal": 100, "target": 1000, "power": 500}
# [frazione di obiettivi eliminati, moltiplicatore]
const MULTIPLIER_STEPS := [[0.0, 1], [0.33, 2], [0.66, 3], [0.85, 5]]
# Ogni soglia superata in un solo tiro vale una palla extra.
const SHOT_EXTRA_BALL_THRESHOLDS := [10000, 25000, 50000]
const BALL_BONUS := 10000

var total := 0
var shot := 0
var targets_total := 0
var targets_hit := 0


func _init(targets: int) -> void:
	targets_total = targets


func multiplier() -> int:
	var fraction := float(targets_hit) / max(1, targets_total)
	var result := 1
	for step in MULTIPLIER_STEPS:
		if fraction >= step[0]:
			result = step[1]
	return result


func start_shot() -> void:
	shot = 0


# Registra un piolo colpito ("normal", "target" o "power") e restituisce i punti guadagnati.
func peg_hit(kind: String) -> int:
	var points: int = POINTS[kind] * multiplier()
	if kind == "target":
		targets_hit += 1
	total += points
	shot += points
	return points


func extra_balls_for_shot() -> int:
	var count := 0
	for threshold in SHOT_EXTRA_BALL_THRESHOLDS:
		if shot >= threshold:
			count += 1
	return count


func add_ball_bonus() -> void:
	total += BALL_BONUS


# Stelle per un livello vinto: una per ogni soglia di punteggio del livello superata (massimo 3).
func stars(thresholds: Array) -> int:
	var count := 0
	for threshold in thresholds:
		if total >= threshold:
			count += 1
	return int(min(count, 3))


static func format(value: int) -> String:
	var digits := str(value)
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += "."
		out += digits[i]
	return out
