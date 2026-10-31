extends Reference
# Sfondi: un editor di codice con codice vero, uno per linguaggio (generati da tools/assets/make_background.py).
# Caricati solo quando servono: in memoria c'è sempre un solo sfondo.

const DIR := "res://assets/sprites/backgrounds/%s.png"
const LANGUAGES := ["python", "java", "c", "javascript", "rust", "go", "html", "sql", "bash"]


# Sfondo legato a un numero (es. il seme del campo: stesso campo, stesso sfondo).
static func for_seed(value: int) -> Texture:
	return load(DIR % LANGUAGES[int(abs(value)) % LANGUAGES.size()]) as Texture


# Sfondo dei menu: scelto a caso al primo menu e poi sempre lo stesso, per non cambiarlo a ogni schermata.
static func for_menus() -> Texture:
	if Session.menu_background < 0:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		Session.menu_background = rng.randi_range(0, LANGUAGES.size() - 1)
	return for_seed(Session.menu_background)
