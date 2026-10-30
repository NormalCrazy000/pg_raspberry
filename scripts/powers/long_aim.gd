extends "res://scripts/powers/power.gd"
# Test coverage (Sara): per i prossimi tiri l'anteprima della mira mostra i rimbalzi.

const SHOTS := 2
const BOUNCES := 3

var shots_left := 0
var in_use := false


func activate(_ball: RigidBody2D, _peg: Node2D) -> void:
	shots_left += SHOTS


func on_shot_start() -> void:
	in_use = shots_left > 0
	if in_use:
		shots_left -= 1


func preview_bounces() -> int:
	return BOUNCES if shots_left > 0 else 0


func status_text() -> String:
	if shots_left <= 0:
		return ""
	return tr("POWER_LONG_AIM_ONE") if shots_left == 1 else tr("POWER_LONG_AIM_MANY") % shots_left
