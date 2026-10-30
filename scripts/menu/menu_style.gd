extends Reference
# Elementi comuni dei menu: sfondo e suoni dei pulsanti.

const BACKGROUND := preload("res://assets/sprites/background.svg")


static func add_background(menu: Control) -> void:
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(background)
	menu.move_child(background, 0)


# Clic da tastiera meccanica quando si cambia selezione o si conferma.
static func add_sounds(button: BaseButton) -> void:
	button.connect("focus_entered", Audio, "play", ["click", 1.3, -8.0])
	button.connect("pressed", Audio, "play", ["click", 0.9, 0.0])
