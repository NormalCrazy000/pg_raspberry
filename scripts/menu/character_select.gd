extends Control
# Scelta del personaggio: una scheda per ogni personaggio in data/characters.json.
# In sfida a due sceglie prima il giocatore 1, poi il giocatore 2; contro la CPU il suo personaggio è casuale.

const Characters := preload("res://scripts/game/characters.gd")
const MenuStyle := preload("res://scripts/menu/menu_style.gd")
const FONT_BIG := preload("res://assets/fonts/font_big.tres")
const FONT_SMALL := preload("res://assets/fonts/font_small.tres")
const PORTRAITS_DIR := "res://assets/sprites/characters/%s.svg"
const GAME_SCENE := "res://scenes/game/game.tscn"
const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const CARD_SIZE := Vector2(180, 250)

onready var cards = $Cards
onready var subtitle = $Subtitle


func _ready() -> void:
	MenuStyle.add_background(self)
	Audio.play_music()
	subtitle.text = tr("CHOOSE_CHARACTER") % (Session.selecting_player + 1)
	$Hint.text = tr("HINT_MENU")
	for character in Characters.load_all():
		cards.add_child(_make_card(character))
	if cards.get_child_count() > 0:
		cards.get_child(0).grab_focus()


func _make_card(character: Dictionary) -> Button:
	var card := Button.new()
	card.rect_min_size = CARD_SIZE
	card.connect("pressed", self, "_on_card_pressed", [character.id])
	MenuStyle.add_sounds(card)
	var stripe := ColorRect.new()
	stripe.color = Color(character.color)
	stripe.rect_position = Vector2(8, 8)
	stripe.rect_size = Vector2(CARD_SIZE.x - 16, 6)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stripe)
	var portrait_path: String = PORTRAITS_DIR % character.id
	if ResourceLoader.exists(portrait_path):
		var portrait := TextureRect.new()
		portrait.texture = load(portrait_path)
		portrait.rect_position = Vector2((CARD_SIZE.x - 64) / 2.0, 20)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)
	var name_label := _card_label(character.name, 88, 24)
	name_label.add_font_override("font", FONT_BIG)
	name_label.add_color_override("font_color", Color(character.color))
	card.add_child(name_label)
	var role_label := _card_label(character.role, 112, 18)
	role_label.modulate = Color(0.8, 0.84, 0.92)
	card.add_child(role_label)
	var power_label := _card_label(character.power_name.to_upper(), 140, 18)
	power_label.add_color_override("font_color", Color(character.color))
	card.add_child(power_label)
	var description := _card_label(tr(character.description), 164, CARD_SIZE.y - 170)
	description.add_font_override("font", FONT_SMALL)
	description.modulate = Color(0.8, 0.84, 0.92)
	card.add_child(description)
	return card


func _card_label(text: String, top: float, height: float) -> Label:
	var label := Label.new()
	label.rect_position = Vector2(8, top)
	label.rect_size = Vector2(CARD_SIZE.x - 16, height)
	label.autowrap = true
	label.align = Label.ALIGN_CENTER
	label.text = text
	return label


func _on_card_pressed(id: String) -> void:
	Session.characters[Session.selecting_player] = id
	if Session.mode == Session.MODE_TWO_PLAYERS and Session.selecting_player == 0:
		Session.selecting_player = 1
		get_tree().reload_current_scene()
		return
	if Session.mode == Session.MODE_CPU:
		var all := Characters.load_all()
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		Session.characters[1] = all[rng.randi_range(0, all.size() - 1)].id
	get_tree().change_scene(GAME_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_tree().set_input_as_handled()
		get_tree().change_scene(MENU_SCENE)
