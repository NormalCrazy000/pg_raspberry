extends SceneTree
# Test del tabellone del torneo (scripts/tournament/bracket.gd), senza finestra:
#   godot3-headless --path . -s tools/test_bracket.gd
# Gioca molti tornei con risultati casuali, anche dopo un salvataggio e una rilettura in JSON
# (come quando si spegne il Pi), e controlla che ognuno finisca con un solo campione. Stampa "TEST BRACKET OK".

const Bracket := preload("res://scripts/tournament/bracket.gd")

var failures := 0


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for size in Bracket.SIZES:
		for run in 50:
			_play_tournament(size, rng)
	_check_ties(rng)
	print("TEST BRACKET %s" % ("OK" if failures == 0 else "FALLITO (%d errori)" % failures))
	quit(1 if failures else 0)


func _play_tournament(size: int, rng: RandomNumberGenerator) -> void:
	var participants := []
	for i in size:
		participants.append({"name": "P%d" % i, "character": "giulia"})
	var data := Bracket.create(participants, rng)
	var expected_rounds := 2 if size == 4 else 3
	_expect(data.rounds.size() == expected_rounds, "%d partecipanti: %d turni" % [size, data.rounds.size()])
	var byes := 0
	for m in data.rounds[0]:
		if m.b == Bracket.BYE:
			byes += 1
	_expect(byes == (4 if size <= 4 else 8) - size, "%d partecipanti: %d turni saltati" % [size, byes])
	var played := 0
	var seen := {}
	while true:
		# Salvataggio e rilettura a ogni partita: i numeri tornano come float, come dal file vero.
		data = JSON.parse(JSON.print(data)).result
		var at := Bracket.next_match(data)
		if at.empty():
			break
		var m: Dictionary = data.rounds[at[0]][at[1]]
		var a := int(m.a)
		var b := int(m.b)
		_expect(a != b and a >= 0 and b >= 0, "partita con sfidanti validi")
		for p in [a, b]:
			seen[p] = true
		var winner := Bracket.record(data, at[0], at[1], [rng.randi_range(0, 3) * 1000, rng.randi_range(0, 3) * 1000],
			[rng.randi_range(0, 2), rng.randi_range(0, 2)], rng)
		_expect(winner == a or winner == b, "il vincitore è uno dei due")
		played += 1
		if played > 20:
			_expect(false, "torneo infinito")
			break
	_expect(played == size - 1, "%d partecipanti: %d partite giocate (attese %d)" % [size, played, size - 1])
	_expect(seen.size() == size or size == 6, "tutti hanno giocato")
	_expect(Bracket.champion(data) >= 0, "c'è un campione")


func _check_ties(rng: RandomNumberGenerator) -> void:
	var participants := []
	for i in 4:
		participants.append({"name": "P%d" % i, "character": "marco"})
	var data := Bracket.create(participants, rng)
	var m: Dictionary = data.rounds[0][0]
	Bracket.record(data, 0, 0, [5000, 5000], [3, 7], rng)
	_expect(m.decided_by == "bugs" and m.winner == m.b, "pareggio: passa chi ha più bug")
	m = data.rounds[0][1]
	Bracket.record(data, 0, 1, [5000, 5000], [4, 4], rng)
	_expect(m.decided_by == "draw" and (m.winner == m.a or m.winner == m.b), "pareggio anche nei bug: sorteggio")


func _expect(condition: bool, what: String) -> void:
	if not condition:
		failures += 1
		print("ERRORE: ", what)
