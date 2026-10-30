extends Node
# Sceglie la scena iniziale (il benchmark se lanciato con --bench, altrimenti il gioco)
# e applica le opzioni globali: --novsync disattiva il vsync.

const GAME_SCENE := "res://scenes/game/game.tscn"
const BENCH_SCENE := "res://scenes/spike/peg_benchmark.tscn"


func _ready() -> void:
	var args := Array(OS.get_cmdline_args())
	if args.has("--novsync"):
		OS.vsync_enabled = false
	var scene := BENCH_SCENE if args.has("--bench") else GAME_SCENE
	get_tree().call_deferred("change_scene", scene)
