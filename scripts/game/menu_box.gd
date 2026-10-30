extends Control
# Riquadro con titolo, testo e pulsanti sopra la partita (schermata finale e pausa).
# Emette `choice` con l'id del pulsante premuto.

signal choice(id)

const MenuStyle := preload("res://scripts/menu/menu_style.gd")
const FONT_TITLE := preload("res://assets/fonts/font_title.tres")
const BOX_WIDTH := 460.0

var box := Rect2()
var title := Label.new()
var details := Label.new()
var buttons := HBoxContainer.new()


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	visible = false
	title.add_font_override("font", FONT_TITLE)
	title.align = Label.ALIGN_CENTER
	details.align = Label.ALIGN_CENTER
	buttons.alignment = BoxContainer.ALIGN_CENTER
	buttons.add_constant_override("separation", 12)
	for node in [title, details, buttons]:
		add_child(node)


# `options` è una lista di coppie [id, testo]. Il primo pulsante riceve il focus (gamepad e tastiera).
func open(title_text: String, lines: Array, options: Array) -> void:
	title.text = title_text
	details.text = PoolStringArray(lines).join("\n")
	for child in buttons.get_children():
		child.queue_free()
	for option in options:
		var button := Button.new()
		button.text = option[1]
		button.rect_min_size = Vector2(130, 34)
		button.connect("pressed", self, "emit_signal", ["choice", option[0]])
		MenuStyle.add_sounds(button)
		buttons.add_child(button)
	var lines_height := 18.0 * lines.size()
	box = Rect2((800.0 - BOX_WIDTH) / 2.0, 110.0, BOX_WIDTH, 120.0 + lines_height)
	title.rect_position = Vector2(box.position.x, box.position.y + 14)
	title.rect_size = Vector2(BOX_WIDTH, 40)
	details.rect_position = Vector2(box.position.x, box.position.y + 58)
	details.rect_size = Vector2(BOX_WIDTH, lines_height)
	buttons.rect_position = Vector2(box.position.x, box.end.y - 50)
	buttons.rect_size = Vector2(BOX_WIDTH, 34)
	visible = true
	update()
	if buttons.get_child_count() > 0:
		buttons.get_child(0).call_deferred("grab_focus")


func close() -> void:
	visible = false


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0, 0, 0, 0.45))
	draw_rect(box, Color(0.1, 0.11, 0.17, 0.95))
	draw_rect(box, Color(0.4, 0.45, 0.6), false, 2.0)
