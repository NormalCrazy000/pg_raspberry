# Architettura e scelte di progetto

Perché il gioco è fatto così: concept, modalità, engine e vincoli dovuti al Raspberry Pi.
Le novità di ogni versione sono in [CHANGELOG.md](../CHANGELOG.md).

## Concept

È venerdì pomeriggio in un ufficio di programmatori e bisogna chiudere i bug prima del rilascio.
Si lanciano paperelle di gomma (rubber duck debugging) su un campo di righe di codice per eliminare i bug.
Il genere è il "peg shooter": una palla lanciata dall'alto rimbalza su un campo di pioli, come in pachinko, bagatelle e flipper.

## Modalità di gioco

- **Sfida a 2 giocatori** a turni sullo stesso dispositivo.
- **Contro la CPU** (facile, normale, difficile).
- **Allenamento** in singolo: stesse regole della sfida, alla fine da 0 a 3 stelle in base al punteggio e record personale.
  Le soglie sui campi generati (`STARS` in `scripts/game/field_generator.gd`) vengono da allenamenti automatici della CPU.

I campi sono **generati da codice** a partire da un seme (stesso seme = stesso campo): non c'è una campagna a livelli fissi.
I campi JSON in `levels/` (opzione `--level`) servono solo per lo sviluppo.
Ogni personaggio ha un potere che si attiva colpendo una tazza di caffè: il sistema è estendibile ([poteri.md](poteri.md)).

## Engine: Godot 3.6 (non Godot 4)

I Raspberry Pi 2 e 3 hanno una GPU VideoCore IV che supporta solo **OpenGL ES 2.0**.
Godot 4 richiede almeno OpenGL ES 3.0 / OpenGL 3.3 (renderer "Compatibility") o Vulkan, quindi su questi modelli non gira in modo affidabile.
Godot 3.6 ha ancora il renderer **GLES2** e, dalla 3.6.3, export template ufficiali Linux arm64 e arm32.

Godot 3.6 è una scelta voluta per la **retrocompatibilità con i Raspberry Pi 2 e 3**:
il gioco non verrà portato a Godot 4 finché si vogliono supportare questi modelli.
Il gioco è misurato sul Pi 3B+ (60 FPS stabili); sul Pi 2 non è ancora stato provato.

## Vincoli dovuti al Raspberry Pi

- Risoluzione base **800×480** (display ufficiale 7"), scalata con `stretch_mode=2d` / `aspect=keep` sul desktop.
- Obiettivo **60 FPS**, minimo accettabile 30.
- Niente shader pesanti né post-processing; aloni, particelle e scia si disattivano con la grafica "bassa".
- Grafica: in "Automatica" il Raspberry Pi usa la qualità **Bassa**. Anche Alta regge i 60 FPS sul Pi 3B+,
  ma Bassa consuma e scalda meno. Si può sempre cambiare da Opzioni → Qualità grafica ([raspberry-pi.md](raspberry-pi.md#qualità-grafica)).
- Vsync spento in automatico sul Pi, con limite a 60 FPS ([raspberry-pi.md](raspberry-pi.md#vsync)).
- Sfondi: codice vero disegnato una volta sola in PNG da `tools/assets/make_background.py`, non testo disegnato in gioco:
  ogni sfondo è un'unica immagine e se ne carica una sola alla volta.
- Input: mouse, **touch** e **gamepad** ovunque, per giocare con il Pi portatile senza tastiera.

## Scelte escluse

- **Porting a Godot 4**: vedi sopra.
- **Pubblicazione su itch.io o altri negozi**: il gioco è distribuito solo da GitHub (Releases).
- **Sfida giornaliera** con seme condiviso.
- **Campi creati dagli utenti** caricabili da file: per ora non servono.
- **Funzioni online** (classifica globale, multiplayer in rete): non previste. Se arrivassero, la licenza del codice
  passerebbe da GPL-3.0 ad **AGPL-3.0**, che obbliga a pubblicare il codice anche a chi gestisce un server con una versione modificata.
