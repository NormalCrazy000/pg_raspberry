extends Reference
# Punteggio: punti per piolo, moltiplicatore condiviso legato ai bug eliminati,
# paperelle extra per i tiri ad alto punteggio e bonus per le paperelle rimaste.
# I totali stanno nei giocatori (player.gd); qui c'è solo lo stato comune.

const POINTS := {"normal": 100, "target": 1000, "power": 500}
# [frazione di bug eliminati, moltiplicatore]
const MULTIPLIER_STEPS := [[0.0, 1], [0.33, 2], [0.66, 3], [0.85, 5]]
# Ogni soglia superata in un solo tiro vale una paperella extra.
const SHOT_EXTRA_BALL_THRESHOLDS := [10000, 25000, 50000]
const BALL_BONUS := 10000

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
	shot += points
	return points


func extra_balls_for_shot() -> int:
	var count := 0
	for threshold in SHOT_EXTRA_BALL_THRESHOLDS:
		if shot >= threshold:
			count += 1
	return count


static func format(value: int) -> String:
	var digits := str(value)
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += "."
		out += digits[i]
	return out
