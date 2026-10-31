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
var bonuses := 0
var penalties := 0 # tiri senza bug (punteggio dimezzato)
var solo := false # allenamento: unico giocatore, senza "G1"


func label() -> String:
	if solo and not cpu:
		return character.name
	return "%s (%s)" % [character.name, "CPU" if cpu else tr("PLAYER_SHORT") % (index + 1)]
