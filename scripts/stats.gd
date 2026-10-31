extends Node
# Statistiche delle sfide giocate da persone (autoload "Stats"), salvate in user://stats.json.
# Le partite automatiche (--autoplay) non vengono registrate.

const JsonFile := preload("res://scripts/common/json_file.gd")
const PATH := "user://stats.json"
const TOP_SIZE := 10

var data := {}


func _ready() -> void:
	data = JsonFile.load_dict(PATH)
	_ensure_defaults()


func _ensure_defaults() -> void:
	for key in ["matches", "bugs_fixed"]:
		if not data.has(key):
			data[key] = 0
	if not data.has("best"):
		data.best = {"score": 0, "character": ""}
	if not data.has("cpu"):
		data.cpu = {}
	for level in ["easy", "normal", "hard"]:
		if not data.cpu.has(level):
			data.cpu[level] = {"won": 0, "lost": 0, "draw": 0}
	if not data.has("characters"):
		data.characters = {}
	if not data.has("top"):
		data.top = [] # migliori punteggi: {score, character, mode, date}
	if not data.has("training"):
		data.training = {"played": 0, "best": 0, "character": "", "three_stars": 0}


# Registra una sfida conclusa. `winner` è l'indice del vincitore, -1 in caso di pareggio.
func record_match(players: Array, winner: int, bugs_fixed: int, cpu_difficulty: String) -> void:
	data.matches += 1
	data.bugs_fixed += bugs_fixed
	for i in players.size():
		var player = players[i]
		if player.cpu:
			continue
		var id: String = player.character.id
		if not data.characters.has(id):
			data.characters[id] = {"played": 0, "won": 0}
		data.characters[id].played += 1
		if winner == i:
			data.characters[id].won += 1
		if player.score > data.best.score:
			data.best = {"score": player.score, "character": player.character.name}
		_add_top_score(player, cpu_difficulty)
		if cpu_difficulty and data.cpu.has(cpu_difficulty):
			var result := "draw" if winner < 0 else ("won" if winner == i else "lost")
			data.cpu[cpu_difficulty][result] += 1
	JsonFile.save_dict(PATH, data)


# Registra un allenamento concluso: ha un record a parte, non conta tra le sfide né nei migliori punteggi.
func record_training(player, stars: int, bugs_fixed: int) -> void:
	data.training.played += 1
	data.bugs_fixed += bugs_fixed
	if stars == 3:
		data.training.three_stars += 1
	if player.score > data.training.best:
		data.training.best = player.score
		data.training.character = player.character.name
	JsonFile.save_dict(PATH, data)


func training_best() -> int:
	return int(data.training.best)


func _add_top_score(player, cpu_difficulty: String) -> void:
	var date := OS.get_date()
	data.top.append({
		"score": player.score,
		"character": player.character.name,
		"mode": cpu_difficulty if cpu_difficulty else "2p",
		"date": "%04d-%02d-%02d" % [date.year, date.month, date.day],
	})
	data.top.sort_custom(self, "_higher_first")
	data.top.resize(min(data.top.size(), TOP_SIZE))


func _higher_first(a: Dictionary, b: Dictionary) -> bool:
	return a.score > b.score


func reset() -> void:
	data = {}
	_ensure_defaults()
	JsonFile.save_dict(PATH, data)
