extends Node
# Dati condivisi tra le scene (personaggi scelti, uno per giocatore) e opzioni di debug globali:
#   --screenshot=FILE.png   salva uno screenshot dopo --screenshot-delay=S secondi (default 2) ed esce
#   --debug-power           il potere si attiva a inizio partita e al primo piolo colpito di ogni tiro

const DEFAULT_CHARACTER := "giulia"

var characters := [DEFAULT_CHARACTER]
var screenshot_path := ""
var screenshot_delay := 2.0
var debug_power := false


func _ready() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--screenshot="):
			screenshot_path = arg.split("=")[1]
		elif arg.begins_with("--screenshot-delay="):
			screenshot_delay = float(arg.split("=")[1])
		elif arg == "--debug-power":
			debug_power = true
	if screenshot_path:
		_take_screenshot()


func _take_screenshot() -> void:
	yield(get_tree().create_timer(screenshot_delay), "timeout")
	var img := get_viewport().get_texture().get_data()
	img.flip_y()
	img.save_png(screenshot_path)
	print("Screenshot: %s" % screenshot_path)
	get_tree().quit()
