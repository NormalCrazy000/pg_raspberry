# Roadmap — Hotfix Friday

Gioco 2D originale del genere "peg shooter" (palla lanciata dall'alto che rimbalza su un campo di pioli, stile pachinko/flipper),
open source, giocabile su Linux desktop e su **Raspberry Pi 3**.

**Concept:** è venerdì pomeriggio in un ufficio di programmatori e bisogna chiudere i bug prima del rilascio.
Si lanciano paperelle di gomma (rubber duck debugging) su un campo di righe di codice per eliminare i bug.
Il gioco è pensato per **sfide a due giocatori** (a turni sullo stesso dispositivo, o contro la CPU) su campi generati da codice:
niente campagna a livelli fissi.

> **Stato:** versione **0.1.2** pubblicata. Quello che è già stato fatto è in [CHANGELOG.md](CHANGELOG.md).

---

## Prossimi passi — 0.2.0

- [x] **Modalità allenamento** in singolo: una partita da soli con le stesse regole della sfida (palle limitate, bug da eliminare);
  alla fine il punteggio con le stelle e il record personale.
- [ ] **Campi creati dagli utenti**, scritti a mano in JSON con il formato già usato da `levels/level_01.json`
  (archi, griglie, linee):
  - formato documentato in `docs/`, con un esempio commentato;
  - caricati dalla cartella `campi/` accanto all'eseguibile (con l'installazione: `~/.local/share/hotfix-friday-game/campi/`);
  - scelta del campo nel menu: generato a caso oppure uno dei campi trovati;
  - giocabili in tutte le modalità: sfida a 2 giocatori, contro la CPU e allenamento;
  - un file non valido non blocca il gioco: viene saltato con un messaggio d'errore.

---

## Idee per dopo (backlog)
- Rinominare il repository su GitHub in `hotfix-friday` (Settings → General → Repository name) e poi aggiornare il remote locale.

### Scartate
- Pubblicazione su itch.io o altri negozi: il gioco resta solo su GitHub.
- Sfida giornaliera con seed condiviso.
- Porting a Godot 4 (vedi sotto, "Engine").

---

## Decisioni tecniche chiave

### Engine: Godot **3.6** (non Godot 4)

Il Raspberry Pi 3 ha una GPU VideoCore IV che supporta solo **OpenGL ES 2.0**.
Godot 4 richiede almeno OpenGL ES 3.0 / OpenGL 3.3 (renderer "Compatibility") o Vulkan, quindi sul Pi 3 non gira in modo affidabile.
Godot 3.6 ha ancora il renderer **GLES2** e, dalla 3.6.3, export template ufficiali Linux arm64 e arm32.
Godot 3.6 è una scelta voluta per la **retrocompatibilità con i Raspberry Pi 2 e 3** (stessa GPU VideoCore IV, solo GLES2):
il gioco **non verrà portato a Godot 4** finché si vogliono supportare questi modelli.

### Vincoli di design dovuti al Pi 3
- Risoluzione base **800×480** (display ufficiale 7"), scalata con `stretch_mode=2d` / `aspect=keep` sul desktop.
- Obiettivo **60 FPS** sul Pi 3, minimo accettabile 30.
- Niente shader pesanti, effetti disattivabili con la grafica "bassa", nessun post-processing.
- Input: mouse, **touch** e **gamepad** ovunque (per giocare "in giro" senza tastiera).
- Grafica: in "Automatica" il Raspberry Pi usa la qualità **Bassa** (consuma e scalda meno, anche se Alta regge i 60 FPS sul Pi 3B+);
  si può sempre cambiare da Opzioni → Qualità grafica.

---

## Copyright e licenze

Le meccaniche di gioco non sono protette da copyright: il genere esiste da decenni (pachinko, bagatelle, flipper).
Nomi, loghi, grafica, suoni, musiche, personaggi e layout di livelli di altri giochi invece sì, e non vanno usati né imitati.

- Codice: licenza **GNU GPL v3** (`LICENSE`): chi distribuisce o vende il gioco deve rendere pubblico il codice con la stessa licenza.
- **AGPL-3.0:** per ora non serve. Se in futuro si aggiungono funzioni online (classifica globale, multiplayer in rete)
  si passerà ad AGPL-3.0, che obbliga a pubblicare il codice anche a chi gestisce un server con una versione modificata.
- Asset originali: **CC BY-SA 4.0**; asset di terzi solo **CC0 / CC BY / CC BY-SA**, sempre registrati in `ASSETS.md`.
- Fino alla 0.1.1 il codice era MIT e gli asset CC BY 4.0: quelle versioni restano disponibili con quelle licenze.
- La licenza di Godot (MIT) e quella del font (OFL) sono mostrate nella schermata crediti.

Regole pratiche per chi contribuisce in [CONTRIBUTING.md](CONTRIBUTING.md). _Linee guida pratiche, non consulenza legale._
