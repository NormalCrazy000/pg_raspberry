extends Reference
# Elenco dei poteri disponibili: id usato in data/characters.json -> script.

const POWERS := {
	"shockwave": preload("res://scripts/powers/shockwave.gd"),
	"multiball": preload("res://scripts/powers/multiball.gd"),
	"long_aim": preload("res://scripts/powers/long_aim.gd"),
	"magnet": preload("res://scripts/powers/magnet.gd"),
}


static func create(id: String, game: Node) -> Reference:
	if not POWERS.has(id):
		push_error("Potere sconosciuto: %s" % id)
		return null
	var power: Reference = POWERS[id].new()
	power.setup(game)
	return power
