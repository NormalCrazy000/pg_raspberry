# Contribuire a Hotfix Friday

Grazie dell'interesse! Il gioco è scritto in GDScript con **Godot 3.6.3** (non Godot 4: deve girare sul Raspberry Pi 3).

## Preparare l'ambiente

1. Installa Godot 3.6.3 (vedi [docs/comandi.md](docs/comandi.md)).
2. Dopo il clone, importa gli asset una volta: `godot3 --path . --editor --quit`.
3. Gioca con `godot3 --path .`.

## Prima di aprire una pull request

```bash
tools/smoke_test.sh 10      # 10 sfide automatiche senza errori
```

GitHub Actions ripete il test ed esporta le build a ogni push e pull request.

## Cosa si può aggiungere facilmente

| Cosa | Dove | Guida |
|---|---|---|
| Un potere | `scripts/powers/` + `scripts/powers/registry.gd` | [docs/poteri.md](docs/poteri.md) |
| Un personaggio | `data/characters.json` (+ ritratto in `assets/sprites/characters/<id>.svg`) | [docs/poteri.md](docs/poteri.md) |
| Una lingua | una colonna in `locale/translations.csv` | intestazione = codice lingua (es. `fr`) |
| Una figura dei campi | `scripts/game/field_generator.gd` (`_random_feature`) | commenti nel file |
| Un campo fisso | `levels/*.json` | formato in `scripts/game/level_loader.gd` |

Per i bilanciamenti usa le sfide automatiche: `docs/comandi.md` spiega come raccogliere statistiche su molte partite.

## Regole

- **Niente asset di terzi senza licenza chiara.** Solo opere originali o CC0/CC BY/CC BY-SA, registrate in [ASSETS.md](ASSETS.md) nello stesso commit.
- Niente nomi, grafica, suoni o livelli presi da altri giochi.
- I testi visibili vanno in `locale/translations.csv` (italiano e inglese).
- Pensa al Raspberry Pi 3: pochi draw call, niente shader pesanti, effetti disattivabili con la grafica "bassa".
- Stile del codice: quello dei file vicini (tab, commenti in italiano, nomi in inglese).

Il codice è sotto licenza GNU GPL v3, gli asset originali sotto CC BY-SA 4.0: contribuendo accetti di rilasciare il tuo lavoro con le stesse licenze.
