# Personaggi e poteri

Ogni personaggio ha un potere. Il potere si attiva quando il giocatore colpisce una **tazza di caffè** (piolo verde).

| Personaggio | Ruolo | Potere | Effetto | Script |
|---|---|---|---|---|
| Giulia | Senior Backend | Refactoring | onda d'urto: accende i pioli entro 110 px dal caffè | `scripts/powers/shockwave.gd` |
| Marco | Junior Frontend | Fork | la paperella si divide in tre | `scripts/powers/multiball.gd` |
| Sara | QA Tester | Test coverage | per 2 tiri la mira mostra fino a 3 rimbalzi | `scripts/powers/long_aim.gd` |
| Dario | DevOps | Hotfix | per il resto del tiro la paperella è attratta dai bug entro 160 px | `scripts/powers/magnet.gd` |

## Aggiungere un potere

1. Crea `scripts/powers/<nome>.gd` che estende la base e sovrascrive solo ciò che serve:

   ```gdscript
   extends "res://scripts/powers/power.gd"
   # Gravità ridotta per il resto del tiro.

   var active := false

   func activate(_ball, _peg) -> void:
   	active = true

   func on_ball_physics(ball, delta) -> void:
   	if active:
   		ball.apply_central_impulse(Vector2(0, -450) * delta * ball.mass)

   func on_shot_end() -> void:
   	active = false

   func status_text() -> String:
   	return "gravità ridotta" if active else ""
   ```

2. Registralo in `scripts/powers/registry.gd`:

   ```gdscript
   "low_gravity": preload("res://scripts/powers/low_gravity.gd"),
   ```

3. Assegnalo a un personaggio (nuovo o esistente) in `data/characters.json`:

   ```json
   {
   	"id": "elena",
   	"name": "Elena",
   	"role": "Data Scientist",
   	"power": "low_gravity",
   	"power_name": "Overfitting",
   	"description": "La paperella fluttua più a lungo.",
   	"color": "#e06fa0"
   }
   ```

Il menu mostra automaticamente tutti i personaggi del file JSON.

## Metodi disponibili

Tutti opzionali; li trovi documentati in `scripts/powers/power.gd`.

| Metodo | Quando viene chiamato |
|---|---|
| `activate(ball, peg)` | il giocatore colpisce un caffè (con `--debug-power` anche a inizio partita, con `ball` e `peg` nulli) |
| `on_shot_start()` | inizio di ogni tiro |
| `on_ball_physics(ball, delta)` | a ogni passo di fisica, per ogni paperella in gioco |
| `on_shot_end()` | tutte le paperelle del tiro sono uscite |
| `preview_bounces()` | quanti rimbalzi mostrare nella mira (0 = solo parabola) |
| `status_text()` | testo nell'HUD accanto al nome del personaggio |

Dalla partita il potere può usare `game.balls`, `game.pegs_root`, `game.spawn_ball()`, `game.hit_peg()` e `game.add_effect()`.

## Provare un potere

```bash
godot3 --path . --character=sara --debug-power
```

Con `--debug-power` il potere si attiva a inizio partita e al primo piolo colpito di ogni tiro, senza dover centrare un caffè.
