extends Control
# Schermata di solo testo: "Come si gioca", "Statistiche" o "Crediti" (Session.text_screen).
# Il testo scorre con mouse, dito, frecce o stick.

const MenuStyle := preload("res://scripts/menu/menu_style.gd")
const Scoring := preload("res://scripts/game/scoring.gd")
const Characters := preload("res://scripts/game/characters.gd")
const FONT_TITLE := preload("res://assets/fonts/font_title.tres")
const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const SCROLL_SPEED := 300.0

var scroll := ScrollContainer.new()


func _ready() -> void:
	MenuStyle.add_background(self)
	var title := Label.new()
	title.add_font_override("font", FONT_TITLE)
	title.align = Label.ALIGN_CENTER
	title.anchor_right = 1.0
	title.margin_top = 20
	add_child(title)
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.margin_left = 70
	scroll.margin_right = -70
	scroll.margin_top = 80
	scroll.margin_bottom = -70
	scroll.scroll_horizontal_enabled = false
	add_child(scroll)
	var text := Label.new()
	text.autowrap = true
	text.rect_min_size = Vector2(800 - 140 - 16, 0)
	scroll.add_child(text)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGN_CENTER
	buttons.add_constant_override("separation", 12)
	buttons.anchor_right = 1.0
	buttons.anchor_top = 1.0
	buttons.anchor_bottom = 1.0
	buttons.margin_top = -54
	buttons.margin_bottom = -20
	add_child(buttons)
	var back := _add_button(buttons, tr("MENU_BACK"), "_back")
	match Session.text_screen:
		"stats":
			title.text = tr("STATS_TITLE")
			text.text = _stats_text()
			_add_button(buttons, tr("STATS_RESET"), "_reset_stats")
		"credits":
			title.text = tr("CREDITS_TITLE")
			var version: String = ProjectSettings.get_setting("application/config/version")
			text.text = "v%s\n\n%s\n\n%s" % [version, tr("CREDITS_BODY"), Engine.get_license_text()]
		_:
			title.text = tr("HOW_TO_TITLE")
			text.text = tr("HOW_TO_BODY")
	back.grab_focus()


func _add_button(parent: Control, text: String, method: String) -> Button:
	var button := Button.new()
	button.text = text
	button.rect_min_size = Vector2(160, 32)
	button.connect("pressed", self, method)
	MenuStyle.add_sounds(button)
	parent.add_child(button)
	return button


func _stats_text() -> String:
	var data: Dictionary = Stats.data
	if data.matches == 0 and data.training.played == 0:
		return tr("STATS_NONE")
	var lines := [tr("STATS_MATCHES") % data.matches, tr("STATS_BUGS") % data.bugs_fixed]
	if data.best.score > 0:
		lines.append(tr("STATS_BEST") % [Scoring.format(data.best.score), data.best.character])
	if not data.top.empty():
		lines.append("")
		lines.append(tr("STATS_TOP_HEADER"))
		for i in data.top.size():
			var entry: Dictionary = data.top[i]
			var mode: String = tr("MODE_2P") if entry.mode == "2p" else tr("MODE_CPU") % tr("CPU_" + entry.mode.to_upper())
			lines.append("  %2d. %8s  %-7s %-16s %s" % [i + 1, Scoring.format(int(entry.score)), entry.character, mode, entry.date])
	if data.training.played > 0:
		lines.append("")
		lines.append(tr("STATS_TRAINING_HEADER"))
		var t: Dictionary = data.training
		lines.append("  " + tr("STATS_TRAINING_LINE") % [t.played, Scoring.format(int(t.best)), t.character, t.three_stars])
	lines.append("")
	lines.append(tr("STATS_CPU_HEADER"))
	for level in ["easy", "normal", "hard"]:
		var r: Dictionary = data.cpu[level]
		lines.append("  " + tr("STATS_CPU_LINE") % [tr("CPU_" + level.to_upper()), r.won, r.lost, r.draw])
	lines.append("")
	lines.append(tr("STATS_CHAR_HEADER"))
	for character in Characters.load_all():
		var c: Dictionary = data.characters.get(character.id, {"played": 0, "won": 0})
		lines.append("  " + tr("STATS_CHAR_LINE") % [character.name, c.played, c.won])
	return PoolStringArray(lines).join("\n")


func _reset_stats() -> void:
	Stats.reset()
	get_tree().reload_current_scene()


func _process(delta: float) -> void:
	var axis := Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	if abs(axis) > 0.1:
		scroll.scroll_vertical += int(axis * SCROLL_SPEED * delta)


func _back() -> void:
	get_tree().change_scene(MENU_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_tree().set_input_as_handled()
		_back()
