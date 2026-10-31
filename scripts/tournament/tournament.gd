extends Node
# Torneo in corso (autoload "Tournament"): il tabellone di scripts/tournament/bracket.gd,
# salvato in user://tournament.json dopo ogni partita, così si riprende anche dopo aver spento il Pi.

const Bracket := preload("res://scripts/tournament/bracket.gd")
const JsonFile := preload("res://scripts/common/json_file.gd")
const PATH := "user://tournament.json"

var data := {}
var current := [] # [turno, partita] della partita in corso, [] se nessuna
var rng := RandomNumberGenerator.new()
var persist := true # false nei tornei di prova (--tournament con --autoplay): niente salvataggio


func _ready() -> void:
	rng.randomize()
	data = JsonFile.load_dict(PATH)
	if not data.has("rounds") or not data.has("participants"):
		data = {}


# C'è un torneo salvato (anche finito, finché non se ne inizia un altro o lo si abbandona).
func exists() -> bool:
	return not data.empty()


func finished() -> bool:
	return exists() and champion() != Bracket.EMPTY


# Torneo di prova da 4 CPU, solo in memoria (per i test automatici).
func start_test() -> void:
	persist = false
	var characters := ["giulia", "marco", "sara", "dario"]
	var participants := []
	for i in characters.size():
		participants.append({"name": "CPU %d" % (i + 1), "character": characters[i]})
	start(participants)


func start(participants: Array) -> void:
	data = Bracket.create(participants, rng)
	current = []
	_save()


func abandon() -> void:
	data = {}
	current = []
	var dir := Directory.new()
	if dir.file_exists(PATH):
		dir.remove(PATH)


func next_match() -> Array:
	return Bracket.next_match(data) if exists() else []


func participant(index: int) -> Dictionary:
	return data.participants[index]


func match_data(at: Array) -> Dictionary:
	return data.rounds[at[0]][at[1]]


func champion() -> int:
	return Bracket.champion(data)


func is_final(at: Array) -> bool:
	return at[0] == data.rounds.size() - 1


# Prepara la partita successiva per la scena di gioco (Session): personaggi e nomi dei due sfidanti.
func begin_next_match() -> void:
	current = next_match()
	var m := match_data(current)
	var a := participant(int(m.a))
	var b := participant(int(m.b))
	Session.mode = Session.MODE_TOURNAMENT
	Session.characters = [a.character, b.character]
	Session.names = [a.name, b.name]
	Session.field_seed = 0
	Session.first_player = 0


# Risultato della partita in corso; restituisce l'indice del partecipante che passa il turno.
func record_current(scores: Array, bugs: Array) -> int:
	var winner := Bracket.record(data, current[0], current[1], scores, bugs, rng)
	_save()
	return winner


func _save() -> void:
	if persist:
		JsonFile.save_dict(PATH, data)
