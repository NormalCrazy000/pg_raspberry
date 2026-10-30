extends Reference
# Personaggi giocabili, letti da data/characters.json.

const PATH := "res://data/characters.json"


static func load_all() -> Array:
	var file := File.new()
	if file.open(PATH, File.READ) != OK:
		push_error("File personaggi non trovato: %s" % PATH)
		return []
	var parsed := JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK:
		push_error("%s:%d %s" % [PATH, parsed.error_line, parsed.error_string])
		return []
	return parsed.result


static func find(id: String) -> Dictionary:
	for character in load_all():
		if character.id == id:
			return character
	return {}
