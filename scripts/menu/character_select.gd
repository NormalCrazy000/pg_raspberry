extends Control
# Scelta del personaggio: una scheda per ogni personaggio in data/characters.json.

const Characters := preload("res://scripts/game/characters.gd")
const GAME_SCENE := "res://scenes/game/game.tscn"
const CARD_SIZE := Vector2(180, 250)

onready var cards := $Cards


func _ready() -> void:
	for character in Characters.load_all():
		cards.add_child(_make_card(character))
	if cards.get_child_count() > 0:
		cards.get_child(0).grab_focus()


func _make_card(character: Dictionary) -> Button:
	var card := Button.new()
	card.rect_min_size = CARD_SIZE
	card.connect("pressed", self, "_on_card_pressed", [character.id])
	var stripe := ColorRect.new()
	stripe.color = Color(character.color)
	stripe.rect_position = Vector2(8, 8)
	stripe.rect_size = Vector2(CARD_SIZE.x - 16, 6)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(stripe)
	var text := Label.new()
	text.rect_position = Vector2(10, 26)
	text.rect_size = Vector2(CARD_SIZE.x - 20, CARD_SIZE.y - 36)
	text.autowrap = true
	text.align = Label.ALIGN_CENTER
	text.text = "%s\n%s\n\n%s\n\n%s" % [character.name, character.role, character.power_name.to_upper(), character.description]
	card.add_child(text)
	return card


func _on_card_pressed(id: String) -> void:
	Session.characters[0] = id
	get_tree().change_scene(GAME_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
