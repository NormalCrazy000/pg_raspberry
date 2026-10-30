extends Node
# Sceglie la scena iniziale: il benchmark se lanciato con --bench, altrimenti il gioco.

const GAME_SCENE := "res://scenes/game/game.tscn"
const BENCH_SCENE := "res://scenes/spike/peg_benchmark.tscn"


func _ready() -> void:
	var scene := BENCH_SCENE if Array(OS.get_cmdline_args()).has("--bench") else GAME_SCENE
	get_tree().call_deferred("change_scene", scene)
