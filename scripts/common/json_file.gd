extends Reference
# Lettura e scrittura di dizionari in file JSON (impostazioni, statistiche).


static func load_dict(path: String) -> Dictionary:
	var file := File.new()
	if not file.file_exists(path) or file.open(path, File.READ) != OK:
		return {}
	var parsed := JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		push_warning("File non valido, uso i valori predefiniti: %s" % path)
		return {}
	return parsed.result


static func save_dict(path: String, data: Dictionary) -> void:
	var file := File.new()
	if file.open(path, File.WRITE) != OK:
		push_error("Impossibile salvare %s" % path)
		return
	file.store_string(JSON.print(data, "\t"))
	file.close()
