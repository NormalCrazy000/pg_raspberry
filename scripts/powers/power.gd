extends Reference
# Base di tutti i poteri.
#
# Per aggiungere un potere:
#   1. crea uno script in scripts/powers/ che estende questo file;
#   2. sovrascrivi solo i metodi che ti servono;
#   3. registralo in scripts/powers/registry.gd;
#   4. assegnalo a un personaggio in data/characters.json.
#
# Dalla partita (`game`) i poteri possono usare:
#   game.balls                        paperelle in gioco
#   game.get_pegs()                   pioli del campo (usa global_position: alcuni si muovono)
#   game.spawn_ball(position, velocity)
#   game.hit_peg(peg, ball)           accende un piolo e assegna i punti
#   game.add_effect(node)             aggiunge un effetto visivo al campo

var game: Node


func setup(game_node: Node) -> void:
	game = game_node


# Il giocatore ha colpito una tazza di caffè: il potere si attiva.
func activate(_ball: RigidBody2D, _peg: Node2D) -> void:
	pass


# Inizio di un tiro di questo giocatore (ogni giocatore ha la sua istanza del potere).
func on_shot_start() -> void:
	pass


# Chiamato a ogni passo di fisica per ogni paperella in gioco.
func on_ball_physics(_ball: RigidBody2D, _delta: float) -> void:
	pass


# Fine di un tiro di questo giocatore (tutte le paperelle sono uscite).
func on_shot_end() -> void:
	pass


# Rimbalzi da mostrare nell'anteprima della mira (0 = solo la parabola iniziale).
func preview_bounces() -> int:
	return 0


# Stato del potere per l'HUD ("" se non è attivo). Usa tr() con una chiave di locale/translations.csv.
func status_text() -> String:
	return ""
