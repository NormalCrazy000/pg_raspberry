extends Reference
# Tabellone di un torneo a eliminazione diretta (solo dati, nessuna grafica: si salva in JSON così com'è).
#
# data = {
#   "participants": [{"name", "character"}, ...],
#   "rounds": [[match, ...], ...],   dal primo turno alla finale
# }
# match = {"a", "b", "winner", "scores": [a, b], "bugs": [a, b], "decided_by"}
#   a, b, winner: indici in participants; EMPTY = non ancora noto, BYE = nessun avversario (si passa senza giocare).
#   decided_by: "score", "bugs" (pareggio, passa chi ha eliminato più bug), "draw" (sorteggio), "bye".

const EMPTY := -1
const BYE := -2
const SIZES := [4, 6, 8]


# Nuovo tabellone con sorteggio casuale. Con 6 partecipanti il tabellone è da 8: 2 passano il primo turno,
# uno per metà tabellone, così ogni semifinale ha un giocatore che ha riposato.
static func create(participants: Array, rng: RandomNumberGenerator) -> Dictionary:
	assert(participants.size() in SIZES)
	var order := range(participants.size())
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = order[i]
		order[i] = order[j]
		order[j] = tmp
	var size := 4 if participants.size() <= 4 else 8
	var first_round_count := size / 2
	var byes := size - participants.size()
	var bye_slots := []
	for i in byes:
		bye_slots.append(i * first_round_count / byes)
	var rounds := []
	var first := []
	var next := 0
	for i in first_round_count:
		var a: int = order[next]
		next += 1
		var b: int = BYE
		if not i in bye_slots:
			b = order[next]
			next += 1
		first.append(_match(a, b))
	rounds.append(first)
	var count := first_round_count / 2
	while count >= 1:
		var round_matches := []
		for i in count:
			round_matches.append(_match(EMPTY, EMPTY))
		rounds.append(round_matches)
		count /= 2
	var data := {"participants": participants, "rounds": rounds}
	for i in first.size():
		if first[i].b == BYE:
			first[i].winner = first[i].a
			first[i].decided_by = "bye"
			_advance(data, 0, i)
	return data


static func _match(a: int, b: int) -> Dictionary:
	return {"a": a, "b": b, "winner": EMPTY, "scores": [0, 0], "bugs": [0, 0], "decided_by": ""}


# Prossima partita da giocare: [turno, partita], oppure [] se il torneo è finito.
static func next_match(data: Dictionary) -> Array:
	for r in data.rounds.size():
		for i in data.rounds[r].size():
			var m: Dictionary = data.rounds[r][i]
			if int(m.winner) == EMPTY and int(m.a) >= 0 and int(m.b) >= 0:
				return [r, i]
	return []


# Registra il risultato di una partita: vince chi ha più punti; a parità chi ha eliminato più bug; poi sorteggio.
# Restituisce l'indice del partecipante che passa il turno.
static func record(data: Dictionary, round_index: int, match_index: int, scores: Array, bugs: Array,
		rng: RandomNumberGenerator) -> int:
	var m: Dictionary = data.rounds[round_index][match_index]
	m.scores = scores.duplicate()
	m.bugs = bugs.duplicate()
	var first_wins: bool
	if scores[0] != scores[1]:
		first_wins = scores[0] > scores[1]
		m.decided_by = "score"
	elif bugs[0] != bugs[1]:
		first_wins = bugs[0] > bugs[1]
		m.decided_by = "bugs"
	else:
		first_wins = rng.randi_range(0, 1) == 0
		m.decided_by = "draw"
	m.winner = int(m.a) if first_wins else int(m.b)
	_advance(data, round_index, match_index)
	return m.winner


static func _advance(data: Dictionary, round_index: int, match_index: int) -> void:
	if round_index + 1 >= data.rounds.size():
		return
	var target: Dictionary = data.rounds[round_index + 1][match_index / 2]
	if match_index % 2 == 0:
		target.a = data.rounds[round_index][match_index].winner
	else:
		target.b = data.rounds[round_index][match_index].winner


# Indice del vincitore del torneo, EMPTY se non è ancora finito.
static func champion(data: Dictionary) -> int:
	if data.empty() or data.rounds.empty():
		return EMPTY
	return int(data.rounds[-1][0].winner)


# Nome del turno in base a quante partite ha: "ROUND_FINAL", "ROUND_SEMI" o "ROUND_QUARTER" (chiavi di traduzione;
# con "_ONE" in fondo il nome di una singola partita: "Semifinale" invece di "Semifinali").
static func round_key(data: Dictionary, round_index: int) -> String:
	match data.rounds[round_index].size():
		1:
			return "ROUND_FINAL"
		2:
			return "ROUND_SEMI"
	return "ROUND_QUARTER"
