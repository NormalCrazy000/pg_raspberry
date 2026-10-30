extends Reference
# Un giocatore della sfida: personaggio, potere, punteggio e paperelle.

var index := 0
var character := {}
var power: Reference
var cpu: Reference # null se è una persona
var score := 0
var balls_left := 0
var extra_balls_won := 0
var bonus_balls := 0
var powers_used := 0


func label() -> String:
	return "%s (%s)" % [character.name, "CPU" if cpu else "G%d" % (index + 1)]
