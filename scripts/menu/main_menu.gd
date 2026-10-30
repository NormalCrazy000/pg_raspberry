extends Control
# Menu principale. Ha due pagine: quella principale e la scelta della difficoltà della CPU.

const MenuStyle := preload("res://scripts/menu/menu_style.gd")
const CHARACTER_SCENE := "res://scenes/menu/character_select.tscn"
const OPTIONS_SCENE := "res://scenes/menu/options.tscn"
const TEXT_SCENE := "res://scenes/menu/text_screen.tscn"

var page := "main"

onready var buttons = $Buttons
onready var subtitle = $Subtitle
onready var hint = $Hint


func _ready() -> void:
	MenuStyle.add_background(self)
	Audio.play_music()
	hint.text = tr("HINT_MENU")
	var version := Label.new()
	version.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	version.modulate = Color(0.45, 0.5, 0.6)
	version.anchor_left = 1.0
	version.anchor_right = 1.0
	version.margin_left = -90
	version.margin_right = -10
	version.margin_top = 8
	version.align = Label.ALIGN_RIGHT
	add_child(version)
	_show_page("main")


func _show_page(name: String) -> void:
	page = name
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	if name == "cpu":
		subtitle.text = tr("MENU_CPU_TITLE")
		_add_button(tr("CPU_EASY"), "_start", [Session.MODE_CPU, "easy"])
		_add_button(tr("CPU_NORMAL"), "_start", [Session.MODE_CPU, "normal"])
		_add_button(tr("CPU_HARD"), "_start", [Session.MODE_CPU, "hard"])
		_add_button(tr("MENU_BACK"), "_go_page", ["main"])
	else:
		subtitle.text = tr("MENU_SUBTITLE")
		_add_button(tr("MENU_TWO_PLAYERS"), "_start", [Session.MODE_TWO_PLAYERS, ""])
		_add_button(tr("MENU_VS_CPU"), "_go_page", ["cpu"])
		_add_button(tr("MENU_HOW_TO"), "_open_text", ["how_to"])
		_add_button(tr("MENU_STATS"), "_open_text", ["stats"])
		_add_button(tr("MENU_OPTIONS"), "_open_scene", [OPTIONS_SCENE])
		_add_button(tr("MENU_CREDITS"), "_open_text", ["credits"])
		_add_button(tr("MENU_QUIT"), "_quit", [])
	buttons.get_child(0).grab_focus()


# I pulsanti vengono ricreati: meglio farlo dopo che il clic è stato gestito.
func _go_page(name: String) -> void:
	call_deferred("_show_page", name)


func _add_button(text: String, method: String, binds: Array) -> void:
	var button := Button.new()
	button.text = text
	button.rect_min_size = Vector2(280, 32)
	button.connect("pressed", self, method, binds)
	MenuStyle.add_sounds(button)
	buttons.add_child(button)


func _start(mode: String, difficulty: String) -> void:
	Session.mode = mode
	if difficulty:
		Session.cpu_difficulty = difficulty
	Session.field_seed = 0
	Session.first_player = 0
	Session.selecting_player = 0
	get_tree().change_scene(CHARACTER_SCENE)


func _open_text(screen: String) -> void:
	Session.text_screen = screen
	get_tree().change_scene(TEXT_SCENE)


func _open_scene(path: String) -> void:
	get_tree().change_scene(path)


func _quit() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_tree().set_input_as_handled()
		if page == "main":
			get_tree().quit()
		else:
			_go_page("main")
