extends Node
# Sceglie la scena iniziale e applica le opzioni globali (--novsync disattiva il vsync):
#   --bench                        benchmark
#   --autoplay[=...] o --character  direttamente in partita
#   altrimenti                      menu principale

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"
const BENCH_SCENE := "res://scenes/spike/peg_benchmark.tscn"


func _ready() -> void:
	var args := Array(OS.get_cmdline_args())
	if args.has("--novsync"):
		OS.vsync_enabled = false
	var scene := MENU_SCENE
	if args.has("--bench"):
		scene = BENCH_SCENE
	else:
		for arg in args:
			if arg.begins_with("--autoplay") or arg.begins_with("--character=") or arg.begins_with("--p1=") \
					or arg.begins_with("--cpu="):
				scene = GAME_SCENE
	get_tree().call_deferred("change_scene", scene)
