extends Node
# Sceglie la scena iniziale (il vsync, anche --novsync, è gestito da Settings):
#   --bench                        benchmark
#   --autoplay[=...], --character, --cpu, --training  direttamente in partita
#   altrimenti                      menu principale

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"
const BENCH_SCENE := "res://scenes/spike/peg_benchmark.tscn"
const FONTS := [
	preload("res://assets/fonts/font_ui.tres"),
	preload("res://assets/fonts/font_small.tres"),
	preload("res://assets/fonts/font_big.tres"),
	preload("res://assets/fonts/font_title.tres"),
]


func _ready() -> void:
	var args := Array(OS.get_cmdline_args())
	var scene := MENU_SCENE
	if args.has("--bench"):
		scene = BENCH_SCENE
	else:
		for arg in args:
			if arg.begins_with("--autoplay") or arg.begins_with("--character=") or arg.begins_with("--p1=") \
					or arg.begins_with("--cpu=") or arg == "--training":
				scene = GAME_SCENE
	_warm_up_fonts()
	# Due frame per far disegnare i caratteri, poi si parte.
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	get_tree().change_scene(scene)


# Godot disegna ogni carattere la prima volta che compare: sul Pi 3 costa, e durante la partita
# si vedrebbe come un piccolo blocco. Qui li disegniamo tutti subito, quasi trasparenti.
func _warm_up_fonts() -> void:
	var chars := ""
	for code in range(32, 127):
		chars += char(code)
	chars += "àèéìòùÀÈÉÌÒÙ×·»«•©’…●○"
	for font in FONTS:
		var label := Label.new()
		label.add_font_override("font", font)
		label.text = chars
		label.modulate.a = 0.01
		add_child(label)
