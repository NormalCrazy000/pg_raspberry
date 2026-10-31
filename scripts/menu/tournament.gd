extends Control
# Torneo a eliminazione diretta. Pagine:
#   count    quanti partecipanti (4, 6 o 8)
#   name     nome del partecipante, con tastiera a schermo (gamepad e touch) o tastiera vera;
#            poi si sceglie il personaggio nella schermata dei personaggi, che torna qui
#   bracket  tabellone: prossima partita, abbandono del torneo, campione
# L'iscrizione in corso sta in Session (tournament_size, tournament_entries), il torneo in Tournament.

const Bracket := preload("res://scripts/tournament/bracket.gd")
const MenuStyle := preload("res://scripts/menu/menu_style.gd")
const BracketView := preload("res://scripts/menu/bracket_view.gd")
const FONT_TITLE := preload("res://assets/fonts/font_title.tres")
const FONT_BIG := preload("res://assets/fonts/font_big.tres")
const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const CHARACTER_SCENE := "res://scenes/menu/character_select.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"
const NAME_MAX := 10
const KEY_ROWS := ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]

var page := ""
var typed := ""
var confirm_abandon := false
var title := Label.new()
var subtitle := Label.new()
var content := Control.new()
var name_label: Label


func _ready() -> void:
	MenuStyle.add_background(self)
	Audio.play_music()
	title.text = tr("MENU_TOURNAMENT")
	title.add_font_override("font", FONT_TITLE)
	title.align = Label.ALIGN_CENTER
	title.anchor_right = 1.0
	title.margin_top = 12
	add_child(title)
	subtitle.align = Label.ALIGN_CENTER
	subtitle.modulate = Color(0.75, 0.8, 0.9)
	subtitle.anchor_right = 1.0
	subtitle.margin_top = 58
	add_child(subtitle)
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	var hint := Label.new()
	hint.text = tr("HINT_MENU")
	hint.modulate = Color(0.55, 0.6, 0.7)
	hint.align = Label.ALIGN_CENTER
	hint.anchor_right = 1.0
	hint.margin_top = 452
	add_child(hint)
	_show_current_page()


# Sceglie la pagina in base allo stato: iscrizione in corso, torneo salvato o niente.
func _show_current_page() -> void:
	var entries: Array = Session.tournament_entries
	if Session.tournament_size > 0:
		if entries.size() == Session.tournament_size and not entries.empty() and entries[-1].has("character"):
			Tournament.start(entries.duplicate(true))
			Session.tournament_entries = []
			Session.tournament_size = 0
			_go_page("bracket")
		else:
			_go_page("name")
	elif Tournament.exists():
		_go_page("bracket")
	else:
		_go_page("count")


func _go_page(name: String) -> void:
	call_deferred("_build_page", name)


func _build_page(name: String) -> void:
	page = name
	confirm_abandon = false
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	match name:
		"count":
			_build_count()
		"name":
			_build_name()
		_:
			_build_bracket()


# --- Numero di partecipanti ---

func _build_count() -> void:
	subtitle.text = tr("TOURNAMENT_COUNT")
	var buttons := _column(Vector2(400, 140))
	for count in Bracket.SIZES:
		_add_button(buttons, tr("TOURNAMENT_PLAYERS") % count, "_on_count_chosen", [count])
	_add_button(buttons, tr("MENU_BACK"), "_back_to_menu", [])
	buttons.get_child(0).grab_focus()


func _on_count_chosen(count: int) -> void:
	Session.mode = Session.MODE_TOURNAMENT
	Session.tournament_size = count
	Session.tournament_entries = []
	_go_page("name")


# --- Nome del partecipante ---

func _build_name() -> void:
	typed = ""
	var number: int = Session.tournament_entries.size() + 1
	subtitle.text = tr("TOURNAMENT_NAME") % [number, Session.tournament_size]
	name_label = Label.new()
	name_label.add_font_override("font", FONT_BIG)
	name_label.align = Label.ALIGN_CENTER
	name_label.rect_position = Vector2(250, 92)
	name_label.rect_size = Vector2(300, 36)
	name_label.valign = Label.VALIGN_CENTER
	content.add_child(name_label)
	_update_name()
	var keyboard := VBoxContainer.new()
	keyboard.add_constant_override("separation", 6)
	keyboard.rect_position = Vector2(0, 150)
	keyboard.rect_size = Vector2(800, 0)
	content.add_child(keyboard)
	var first: Button
	for row in KEY_ROWS:
		var line := _row(keyboard)
		for letter in row:
			var key := _add_button(line, letter, "_type", [letter], Vector2(44, 38))
			if not first:
				first = key
	var actions := _row(keyboard)
	_add_button(actions, tr("KEY_SPACE"), "_type", [" "], Vector2(150, 38))
	_add_button(actions, tr("KEY_DELETE"), "_delete", [], Vector2(130, 38))
	_add_button(actions, tr("KEY_OK"), "_confirm_name", [], Vector2(130, 38))
	first.grab_focus()


func _update_name() -> void:
	var shown := typed if typed else tr("TOURNAMENT_DEFAULT_NAME") % (Session.tournament_entries.size() + 1)
	name_label.text = shown + ("_" if typed.length() < NAME_MAX else "")
	name_label.modulate = Color(1, 1, 1) if typed else Color(0.55, 0.6, 0.7)


# Le lettere arrivano maiuscole dalla tastiera a schermo: il nome diventa "Anna", "Gian Luca".
func _type(letter: String) -> void:
	if typed.length() >= NAME_MAX or (letter == " " and (typed.empty() or typed.ends_with(" "))):
		return
	var capital := typed.empty() or typed.ends_with(" ")
	typed += letter.to_upper() if capital else letter.to_lower()
	_update_name()


func _delete() -> void:
	typed = typed.substr(0, max(0, typed.length() - 1))
	_update_name()


func _confirm_name() -> void:
	var name := typed.strip_edges()
	if name.empty():
		name = tr("TOURNAMENT_DEFAULT_NAME") % (Session.tournament_entries.size() + 1)
	Session.mode = Session.MODE_TOURNAMENT
	Session.tournament_entries.append({"name": name})
	get_tree().change_scene(CHARACTER_SCENE)


# --- Tabellone ---

func _build_bracket() -> void:
	var view := BracketView.new()
	view.rect_position = Vector2(20, 82)
	view.rect_size = Vector2(760, 318)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(view)
	var next: Array = Tournament.next_match()
	view.show_bracket(Tournament.data, next)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGN_CENTER
	buttons.add_constant_override("separation", 12)
	buttons.rect_position = Vector2(0, 410)
	buttons.rect_size = Vector2(800, 34)
	content.add_child(buttons)
	if next.empty():
		subtitle.text = tr("TOURNAMENT_CHAMPION") % Tournament.participant(Tournament.champion()).name
		_add_button(buttons, tr("TOURNAMENT_NEW"), "_new_tournament", [], Vector2(180, 34))
	else:
		var m: Dictionary = Tournament.match_data(next)
		subtitle.text = tr("TOURNAMENT_NEXT") % [tr(Bracket.round_key(Tournament.data, next[0]) + "_ONE"),
			Tournament.participant(int(m.a)).name, Tournament.participant(int(m.b)).name]
		_add_button(buttons, tr("TOURNAMENT_PLAY"), "_play", [], Vector2(180, 34))
		_add_button(buttons, tr("TOURNAMENT_ABANDON"), "_abandon", [], Vector2(180, 34))
	_add_button(buttons, tr("RESULT_MENU"), "_back_to_menu", [], Vector2(130, 34))
	buttons.get_child(0).grab_focus()


func _play() -> void:
	Tournament.begin_next_match()
	get_tree().change_scene(GAME_SCENE)


# Il primo clic chiede conferma, il secondo cancella il torneo.
func _abandon() -> void:
	if not confirm_abandon:
		confirm_abandon = true
		var button: Button = get_focus_owner()
		if button:
			button.text = tr("TOURNAMENT_ABANDON_CONFIRM")
		return
	Tournament.abandon()
	_go_page("count")


func _new_tournament() -> void:
	Tournament.abandon()
	_go_page("count")


func _back_to_menu() -> void:
	Session.tournament_entries = []
	Session.tournament_size = 0
	get_tree().change_scene(MENU_SCENE)


# --- Comuni ---

func _column(center_top: Vector2) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_constant_override("separation", 8)
	box.rect_position = Vector2(center_top.x - 140, center_top.y)
	box.rect_size = Vector2(280, 0)
	content.add_child(box)
	return box


func _row(parent: Control) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGN_CENTER
	line.add_constant_override("separation", 6)
	parent.add_child(line)
	return line


func _add_button(parent: Control, text: String, method: String, binds: Array, size := Vector2(280, 32)) -> Button:
	var button := Button.new()
	button.text = text
	button.rect_min_size = size
	button.connect("pressed", self, method, binds)
	MenuStyle.add_sounds(button)
	parent.add_child(button)
	return button


# Tastiera vera nella pagina del nome: lettere, spazio, cancella e invio. Gestita prima dei pulsanti,
# altrimenti Invio e spazio "premerebbero" il tasto a schermo che ha il focus.
func _input(event: InputEvent) -> void:
	if page != "name" or not event is InputEventKey or not event.pressed:
		return
	var code: int = event.unicode
	if event.scancode == KEY_BACKSPACE:
		_delete()
	elif event.scancode == KEY_ENTER or event.scancode == KEY_KP_ENTER:
		_confirm_name()
	elif event.scancode == KEY_SPACE:
		_type(" ")
	elif (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
		_type(char(code))
	else:
		return
	get_tree().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_tree().set_input_as_handled()
		if page == "name":
			# Si ricomincia l'iscrizione dal numero di partecipanti.
			Session.tournament_entries = []
			Session.tournament_size = 0
			_go_page("count")
		else:
			_back_to_menu()
