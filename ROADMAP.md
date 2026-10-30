# Roadmap — Hotfix Friday

Gioco 2D originale del genere "peg shooter" (palla lanciata dall'alto che rimbalza su un campo di pioli, stile pachinko/flipper),
open source, giocabile su Linux desktop e su **Raspberry Pi 3**.

**Concept:** è venerdì pomeriggio in un ufficio di programmatori e bisogna chiudere i bug prima del rilascio.
Si lanciano paperelle di gomma (rubber duck debugging) su un campo di righe di codice per eliminare i bug.
Il gioco è pensato per **sfide a due giocatori** (a turni sullo stesso dispositivo, o contro la CPU) su campi generati da codice:
niente campagna a livelli fissi.

> **Stato:** versione **0.1.1** pubblicata. Quello che è già stato fatto è in [CHANGELOG.md](CHANGELOG.md);
> le decisioni ancora da confermare sono in [docs/domande-aperte.md](docs/domande-aperte.md).

---

## Prossimi passi — 0.2.0

### Prestazioni sul Raspberry Pi 3
- [ ] Benchmark sul Pi 3 vero (`rpi_bench.sh` + sfida con `--measure`, vedi `docs/raspberry-pi.md`).
- [ ] Capire i blocchi ("freeze") segnalati sul Pi: con `--measure` il gioco ora stampa i frame più lenti
  (`PICCHI`) con quello che stava succedendo (CPU, pioli che spariscono, poteri, portali, messaggi...).
- [x] Misurati i sospetti sul PC: la CPU "difficile" bloccava un frame (12 ms sul PC, circa 120–250 ms stimati sul Pi);
  la mira estesa di Sara è trascurabile (meno di 0,1 ms).
- [x] La CPU "difficile" ora distribuisce i calcoli su più frame (6 simulazioni per frame), con la stessa forza di gioco.
- [x] I caratteri dei font vengono preparati all'avvio, così non costano la prima volta che compaiono in partita.
- [ ] Da valutare dopo il benchmark: generazione del campo (11–23 ms sul PC, all'inizio della sfida) e rallentatore
  sull'ultimo bug (voluto, ma potrebbe sembrare un blocco).
- [ ] Decidere i budget definitivi (pioli per campo, particelle, qualità grafica predefinita) in base ai risultati.

### Gioco
- [ ] Applicare le risposte alle domande aperte (`docs/domande-aperte.md`).
- [ ] Bonus per tiri particolari (tiro lungo, tanti pioli in un tiro...): da decidere (domanda 4).

### Pubblicazione
- [ ] Opzionale: pagina itch.io.

---

## Idee per dopo (backlog)
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

- Codice: licenza **MIT** (`LICENSE`).
- Asset originali: **CC BY 4.0**; asset di terzi solo **CC0 / CC BY**, sempre registrati in `ASSETS.md`.
- La licenza di Godot (MIT) e quella del font (OFL) sono mostrate nella schermata crediti.

Regole pratiche per chi contribuisce in [CONTRIBUTING.md](CONTRIBUTING.md). _Linee guida pratiche, non consulenza legale._
