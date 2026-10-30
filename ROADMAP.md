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

### Da decidere
- [ ] **Livello di grafica.** Si sceglie già in Opzioni → Qualità grafica (Automatica, Alta, Bassa).
  Da decidere cosa usa "Automatica" sul Raspberry Pi: ora Bassa, ma anche Alta regge i 60 FPS sul Pi 3B+
  (Bassa consuma e scalda un po' meno). Valutare anche un livello intermedio (es. alone sì, particelle no).

### Da verificare
- [ ] Alimentazione del Pi: `sudo vcgencmd get_throttled` deve dare `throttled=0x0` (con 5,1 V 2,5 A e cavo corto).
- [ ] Temperatura del Pi: 64 °C sotto carico, sopra la soglia dei 60 °C a cui il 3B+ rallenta: dissipatore consigliato.
- [ ] Equilibrio dei personaggi con i nuovi bonus, giocando: nelle sfide automatiche Giulia vince il 49%, Marco il 55%,
  Dario il 45%; Sara non è misurabile così (la sua mira estesa aiuta soprattutto le persone).

### Pubblicazione
- [ ] Opzionale: pagina itch.io.

---

## Idee per dopo (backlog)
- Se si aggiungono funzioni online (classifica globale, multiplayer in rete): passare da GPL-3.0 ad **AGPL-3.0**, che obbliga a pubblicare il codice anche di chi gestisce un server modificato.
- Rinominare il repository su GitHub in `hotfix-friday` (Settings → General → Repository name) e poi aggiornare il remote locale.
- Modalità sfida giornaliera con seed condiviso.
- Campi creati dagli utenti caricabili da file.
- Modalità allenamento in singolo.
- Porting a Godot 4 se si abbandona il Pi 3.

---

## Decisioni tecniche chiave

### Engine: Godot **3.6** (non Godot 4)

Il Raspberry Pi 3 ha una GPU VideoCore IV che supporta solo **OpenGL ES 2.0**.
Godot 4 richiede almeno OpenGL ES 3.0 / OpenGL 3.3 (renderer "Compatibility") o Vulkan, quindi sul Pi 3 non gira in modo affidabile.
Godot 3.6 ha ancora il renderer **GLES2** e, dalla 3.6.3, export template ufficiali Linux arm64 e arm32.
Se in futuro si abbandona il Pi 3, il porting a Godot 4 è fattibile (esiste un convertitore ufficiale 3→4).

### Vincoli di design dovuti al Pi 3
- Risoluzione base **800×480** (display ufficiale 7"), scalata con `stretch_mode=2d` / `aspect=keep` sul desktop.
- Obiettivo **60 FPS** sul Pi 3, minimo accettabile 30.
- Niente shader pesanti, effetti disattivabili con la grafica "bassa", nessun post-processing.
- Input: mouse, **touch** e **gamepad** ovunque (per giocare "in giro" senza tastiera).

---

## Copyright e licenze

Le meccaniche di gioco non sono protette da copyright: il genere esiste da decenni (pachinko, bagatelle, flipper).
Nomi, loghi, grafica, suoni, musiche, personaggi e layout di livelli di altri giochi invece sì, e non vanno usati né imitati.

- Codice: licenza **GNU GPL v3** (`LICENSE`): chi distribuisce o vende il gioco deve rendere pubblico il codice con la stessa licenza.
- Asset originali: **CC BY-SA 4.0**; asset di terzi solo **CC0 / CC BY / CC BY-SA**, sempre registrati in `ASSETS.md`.
- Fino alla 0.1.1 il codice era MIT e gli asset CC BY 4.0: quelle versioni restano disponibili con quelle licenze.
- La licenza di Godot (MIT) e quella del font (OFL) sono mostrate nella schermata crediti.

Regole pratiche per chi contribuisce in [CONTRIBUTING.md](CONTRIBUTING.md). _Linee guida pratiche, non consulenza legale._
