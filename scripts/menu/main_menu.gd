extends Control
# Menu principale: sfida a due giocatori o contro la CPU.

const MenuStyle := preload("res://scripts/menu/menu_style.gd")
const CHARACTER_SCENE := "res://scenes/menu/character_select.tscn"

onready var buttons := $Buttons


func _ready() -> void:
	MenuStyle.add_background(self)
	Audio.play_music()
	_add_button("Sfida a 2 giocatori", "_start", [Session.MODE_TWO_PLAYERS, ""])
	_add_button("Contro la CPU · facile", "_start", [Session.MODE_CPU, "easy"])
	_add_button("Contro la CPU · normale", "_start", [Session.MODE_CPU, "normal"])
	_add_button("Contro la CPU · difficile", "_start", [Session.MODE_CPU, "hard"])
	_add_button("Esci", "_quit", [])
	buttons.get_child(0).grab_focus()


func _add_button(text: String, method: String, binds: Array) -> void:
	var button := Button.new()
	button.text = text
	button.rect_min_size = Vector2(280, 36)
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


func _quit() -> void:
	get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
