extends Control
# Opzioni: volumi, schermo intero, velocità di mira, lingua. Salvate subito da Settings.

const MenuStyle := preload("res://scripts/menu/menu_style.gd")
const FONT_TITLE := preload("res://assets/fonts/font_title.tres")
const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const LANGUAGE_NAMES := {"it": "Italiano", "en": "English"}

var rows := VBoxContainer.new()
var first_control: Control


func _ready() -> void:
	MenuStyle.add_background(self)
	var title := Label.new()
	title.text = tr("OPTIONS_TITLE")
	title.add_font_override("font", FONT_TITLE)
	title.align = Label.ALIGN_CENTER
	title.anchor_right = 1.0
	title.margin_top = 30
	add_child(title)
	rows.anchor_left = 0.5
	rows.anchor_right = 0.5
	rows.margin_left = -230
	rows.margin_right = 230
	rows.margin_top = 110
	rows.add_constant_override("separation", 14)
	add_child(rows)
	_add_slider(tr("OPT_MUSIC"), "music_volume", 0.0, 1.0, 0.1)
	_add_slider(tr("OPT_SFX"), "sfx_volume", 0.0, 1.0, 0.1)
	_add_slider(tr("OPT_AIM_SPEED"), "aim_speed", 0.5, 2.0, 0.25)
	var fullscreen := CheckButton.new()
	fullscreen.text = tr("OPT_FULLSCREEN")
	fullscreen.pressed = Settings.value("fullscreen")
	fullscreen.connect("toggled", self, "_on_fullscreen_toggled")
	MenuStyle.add_sounds(fullscreen)
	rows.add_child(fullscreen)
	var graphics := Button.new()
	graphics.text = _graphics_text()
	graphics.connect("pressed", self, "_on_graphics_pressed", [graphics])
	MenuStyle.add_sounds(graphics)
	rows.add_child(graphics)
	var language := Button.new()
	language.text = "%s: %s" % [tr("OPT_LANGUAGE"), LANGUAGE_NAMES[Settings.language()]]
	language.connect("pressed", self, "_on_language_pressed")
	MenuStyle.add_sounds(language)
	rows.add_child(language)
	var back := Button.new()
	back.text = tr("MENU_BACK")
	back.connect("pressed", self, "_back")
	MenuStyle.add_sounds(back)
	rows.add_child(back)
	first_control.grab_focus()


func _add_slider(text: String, key: String, min_value: float, max_value: float, step: float) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.rect_min_size = Vector2(250, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = Settings.value(key)
	slider.rect_min_size = Vector2(190, 24)
	slider.connect("value_changed", self, "_on_slider_changed", [key])
	row.add_child(label)
	row.add_child(slider)
	rows.add_child(row)
	if not first_control:
		first_control = slider


func _on_slider_changed(value: float, key: String) -> void:
	Settings.set_value(key, value)
	if key == "sfx_volume":
		Audio.play("peg")


func _on_fullscreen_toggled(pressed: bool) -> void:
	Settings.set_value("fullscreen", pressed)


func _graphics_text() -> String:
	var mode: String = Settings.value("graphics")
	var text: String = tr("GFX_" + mode.to_upper())
	if mode == "auto":
		text += " (%s)" % tr("GFX_LOW" if Settings.low_graphics() else "GFX_HIGH")
	return "%s: %s" % [tr("OPT_GRAPHICS"), text]


func _on_graphics_pressed(button: Button) -> void:
	var index: int = Settings.GRAPHICS.find(Settings.value("graphics"))
	Settings.set_value("graphics", Settings.GRAPHICS[(index + 1) % Settings.GRAPHICS.size()])
	button.text = _graphics_text()


func _on_language_pressed() -> void:
	# Passa alla lingua successiva e ricarica la schermata per aggiornare i testi.
	var index: int = Settings.LANGUAGES.find(Settings.language())
	Settings.set_value("language", Settings.LANGUAGES[(index + 1) % Settings.LANGUAGES.size()])
	get_tree().call_deferred("reload_current_scene")


func _back() -> void:
	get_tree().change_scene(MENU_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_tree().set_input_as_handled()
		_back()
