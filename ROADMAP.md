# Roadmap — Hotfix Friday

Gioco 2D originale del genere "peg shooter" (palla lanciata dall'alto che rimbalza su un campo di pioli, stile pachinko/flipper),
open source, giocabile su Linux desktop e su **Raspberry Pi 3**.

**Concept:** è venerdì pomeriggio in un ufficio di programmatori e bisogna chiudere i bug prima del rilascio.
Si lanciano paperelle di gomma (rubber duck debugging) su un campo di righe di codice per eliminare i bug.
Il gioco è pensato per **sfide a due giocatori** (a turni sullo stesso dispositivo, o contro la CPU) su campi generati da codice:
niente campagna a livelli fissi.

| Elemento | Nel gioco |
|---|---|
| Palla | paperella di gomma |
| Pioli obiettivo | bug |
| Pioli normali | righe di codice / post-it |
| Pioli potere | tazze di caffè |
| Cestino mobile | cestino della carta |
| Personaggi | colleghi d'ufficio, ognuno con un potere |

---

## Decisioni tecniche chiave

### Engine: Godot **3.6** (non Godot 4)

Il Raspberry Pi 3 ha una GPU VideoCore IV che supporta solo **OpenGL ES 2.0**.
Godot 4 richiede almeno OpenGL ES 3.0 / OpenGL 3.3 (renderer "Compatibility") o Vulkan, quindi sul Pi 3 non gira in modo affidabile.
Godot 3.6 ha ancora il renderer **GLES2**, è maturo, MIT, e per un gioco 2D di questo tipo non manca nulla.

| | Godot 3.6 (GLES2) | Godot 4.x |
|---|---|---|
| Raspberry Pi 3 | ✅ con renderer GLES2 | ❌ GPU non supportata |
| Raspberry Pi 4/5 | ✅ | ✅ |
| Linux desktop | ✅ | ✅ |
| Linguaggio | GDScript | GDScript |

Se in futuro si abbandona il Pi 3, il porting a Godot 4 è fattibile (esiste un convertitore ufficiale 3→4).

Dalla 3.6.3 Godot distribuisce **export template ufficiali Linux arm64 e arm32**: per il Pi non serve compilare nulla.

### Vincoli di design dovuti al Pi 3
- Risoluzione base **800×480** (display ufficiale 7"), scalata con `stretch_mode=2d` / `aspect=keep` sul desktop.
- Obiettivo **60 FPS** sul Pi 3, minimo accettabile 30.
- Niente shader pesanti, particelle con budget limitato, texture in atlas, nessun post-processing.
- Input: mouse, **touch** e **gamepad** fin dall'inizio (per giocare "in giro" senza tastiera).

---

## Copyright e licenze

**Cosa si può fare liberamente:** le meccaniche di gioco (lanciare una palla, colpire pioli, cestino mobile, punteggi) non sono protette da copyright. Il genere esiste da decenni (pachinko, bagatelle, flipper).

**Cosa NON fare:**
- Usare il nome, il logo o termini commerciali di giochi esistenti (sono marchi registrati) — né nel titolo, né nei nomi file, né nella descrizione dello store.
- Usare o ricreare grafica, suoni, musiche, personaggi, testi o **layout di livelli** di altri giochi.
- Copiare l'identità visiva/sonora riconoscibile di un gioco specifico (look, personaggi-mascotte, sequenze di vittoria caratteristiche).
- Usare asset trovati online senza licenza chiara.

**Regole del repo:**
- Codice: licenza **MIT** (file `LICENSE`).
- Asset originali: **CC BY 4.0** (o CC0), dichiarato in `ASSETS.md`.
- Asset di terzi: solo **CC0 / CC BY** (es. Kenney.nl, OpenGameArt filtrando per licenza, freesound CC0), ognuno tracciato in `ASSETS.md` con autore, link e licenza.
- Includere la notice di licenza di Godot (MIT) nel gioco distribuito (schermata crediti).

_Nota: queste sono linee guida pratiche, non consulenza legale._

Il modo migliore per evitare problemi è anche quello che rende il gioco più interessante: **un'identità propria** (tema, personaggi, poteri, modalità). Vedi Fase 3.

---

## Fasi

### Fase 0 — Fondamenta e verifica Raspberry Pi
Obiettivo: essere sicuri che la pipeline funzioni **prima** di scrivere il gioco.
- [x] Installare Godot 3.6.3 + export template su desktop.
- [x] Struttura repo: `.gitignore` Godot, `LICENSE`, `README.md`, `ASSETS.md`, cartelle `scenes/`, `scripts/`, `assets/`, `levels/`.
- [x] Progetto Godot con renderer GLES2, risoluzione 800×480.
- [x] Spike: campo di pioli + palla con fisica, modalità interattiva e benchmark (`--bench`).
- [x] Export per Linux x86_64, Raspberry Pi arm64 e arm32 (`tools/export.sh`).
- [ ] Lanciare lo spike sul Pi 3 e il benchmark (`rpi_bench.sh`, vedi `docs/raspberry-pi.md`).
- [ ] Decidere i budget (numero pioli, palle, particelle) in base ai risultati.

**Uscita:** lo spike gira sul Pi 3 a frame rate accettabile. Se non è così, si rivaluta qui (prima di aver investito tempo).

### Fase 1 — Prototipo del core gameplay
- [x] Cannone in alto che mira (mouse / stick / touch) con anteprima della traiettoria.
- [x] Palla con fisica (gravità, rimbalzo, attrito): per ora `RigidBody2D` con CCD; si passa a fisica custom solo se i rimbalzi risultano imprevedibili.
- [x] Pioli rotondi e rettangolari; colpiti = si illuminano, rimossi a fine tiro.
- [x] Pioli "obiettivo" scelti a caso a ogni partita: il livello si vince eliminandoli tutti.
- [x] Numero limitato di palle; si perde quando finiscono.
- [x] Cestino mobile in fondo: se la palla ci cade, palla recuperata.
- [x] Anti-blocco: se la palla resta quasi ferma, i pioli colpiti vengono rimossi subito; dopo 3 tentativi riceve una spinta.
- [x] Primo livello in JSON (`levels/level_01.json`) con pattern (linea, arco, griglia), anticipo del formato della Fase 4.
- [x] Modalità `--autoplay` per test automatici e bilanciamento.

**Uscita:** un livello giocabile dall'inizio alla fine, con grafica placeholder.

### Fase 2 — Punteggio e game loop
- [x] Punti per piolo (normale 100, obiettivo 1.000) × moltiplicatore che cresce con gli obiettivi eliminati (x2 al 33%, x3 al 66%, x5 all'85%).
- [x] Punti a comparsa sui pioli colpiti, avviso quando sale il moltiplicatore.
- [x] Palla extra per ogni soglia superata in un singolo tiro (10.000 / 25.000 / 50.000).
- [x] Rallentatore sull'ultimo obiettivo; a fine livello ogni palla rimasta vale 10.000 punti.
- [x] Schermata di risultato con stelle (soglie di punteggio nel JSON del livello, tarate con `--autoplay=smart`).
- [ ] Bonus per tiri particolari (tiro lungo, tanti pioli in un tiro...): rimandato, da decidere.

### Fase 3 — Identità, personaggi e poteri
- [x] Nome: **Hotfix Friday** (verificato che non esista un gioco noto con lo stesso nome). Tema: ufficio di programmatori.
- [x] Testi e colori a tema (paperelle, bug, caffè); grafica vera nella Fase 5.
- [x] Pioli di tipo diverso (normale, bug, potere) e più paperelle in gioco nello stesso tiro.
- [x] **Sistema di poteri estendibile**: un potere = uno script + una riga di registrazione (guida in `docs/poteri.md`).
- [x] **Personaggi** (dati in JSON), ognuno con un potere, scelti nel menu:

| Personaggio | Ruolo | Potere | Effetto |
|---|---|---|---|
| Giulia | Senior Backend | Refactoring | onda d'urto: accende i pioli attorno |
| Marco | Junior Frontend | Fork | la paperella si divide in 3 |
| Sara | QA Tester | Test coverage | per 2 tiri la mira mostra i rimbalzi |
| Dario | DevOps | Hotfix | la paperella è attratta dai bug vicini |

- [x] Pioli potere (2 per campo): chi li colpisce attiva il potere del proprio personaggio.
- [x] Menu di selezione del personaggio.

### Fase 4 — Modalità di gioco e campi generati
- [x] **Generatore di campi** (`scripts/game/field_generator.gd`): archi, griglie, rampe, anelli, file mobili piazzati senza sovrapporsi, simmetrici nell'80% dei casi; stesso seme = stesso campo.
- [x] **Pioli in movimento** (anelli che ruotano, file che scorrono) e **portali** (in circa 2 campi su 3).
- [x] **Sfida a due giocatori**: turni alterni sullo stesso campo, 8 paperelle a testa, punti a chi tira, moltiplicatore condiviso; vince chi ha più punti quando i bug finiscono o le paperelle sono esaurite.
- [x] **Sfida contro la CPU** con 3 difficoltà (facile, normale, difficile). La difficile calcola la mira esatta su ogni bug e simula i rimbalzi.
- [x] Menu principale, scelta personaggi per entrambi i giocatori (CPU con personaggio casuale), rivincita sullo stesso campo o nuovo campo.
- [x] Bilanciamento con partite automatiche: vantaggio di chi inizia ~52%; Giulia, Marco e Dario tra 49% e 51% di vittorie dopo aver rafforzato Hotfix (Sara non è misurabile: la CPU non sfrutta la mira estesa); difficoltà difficile > normale > facile (~62% negli scontri diretti).

### Fase 5 — Arte e audio
- [x] Grafica vettoriale originale (SVG): paperella, puntine, bug, tazze di caffè, righe di codice, cannone, cestino, ritratti dei personaggi.
- [x] Sfondo "editor di codice" generato da script (`tools/assets/make_background.py`).
- [x] Effetti: alone sui pioli colpiti, scia della paperella, particelle su bug e caffè (8 sistemi riutilizzati, budget contenuto per il Pi).
- [x] Effetti sonori sintetizzati da codice (`tools/assets/make_audio.py`): colpi con intonazione crescente in scala pentatonica, squittio della paperella al lancio, cestino, portali, caffè, moltiplicatore, vittoria, clic dei menu.
- [x] Musica lo-fi originale in loop (OGG, 23 s, senza salti al punto di loop).
- [x] Font JetBrains Mono (OFL) per tutta l'interfaccia.
- [x] `ASSETS.md` aggiornato.
- [x] `--measure`: benchmark della sfida vera (incluso in `rpi_bench.sh`).

### Fase 6 — UI, UX e salvataggi
- [x] Menu principale a pagine: sfida a 2, contro la CPU (scelta difficoltà), come si gioca, statistiche, opzioni, crediti.
- [x] Pausa (Esc, Start del gamepad o pulsante "II" a schermo per il touch): riprendi, ricomincia la sfida, torna al menu.
- [x] Fine sfida con pulsanti (nuovo campo, rivincita, menu): tutto usabile con solo touch o solo gamepad.
- [x] Opzioni salvate in `user://settings.json`: volume musica ed effetti, schermo intero, velocità di mira, lingua.
- [x] Statistiche in `user://stats.json`: sfide giocate, bug eliminati, miglior punteggio, record contro la CPU per difficoltà, sfide e vittorie per personaggio.
- [x] Schermata crediti con le licenze (gioco, asset, font e licenza di Godot).
- [x] Italiano e inglese (`locale/translations.csv`), lingua iniziale da sistema operativo.

### Fase 7 — Ottimizzazione e packaging
- [x] Qualità grafica automatica/alta/bassa: in automatico bassa su GPU VideoCore o ARM (circa -40% di draw call).
- [x] `--measure` e `rpi_bench.sh` per misurare la sfida vera sul Pi.
- [x] Build automatiche con **GitHub Actions** per x86_64, arm64 e arm32, con 5 sfide di prova; release automatica sui tag `v*`.
- [x] `tools/smoke_test.sh`: test rapido locale con sfide automatiche.
- [x] Icona del gioco; `install.sh` negli archivi: menu delle applicazioni e avvio automatico a schermo intero (Pi in modalità kiosk).
- [x] Guida hardware per la versione portatile (`docs/raspberry-pi.md`).
- [ ] Profiling sul Pi 3 vero (in attesa del benchmark).

### Fase 8 — Release
- [ ] Versioning semantico, `CHANGELOG.md`, tag git.
- [ ] Release su GitHub con binari; opzionale pagina itch.io.
- [ ] Screenshot/GIF nel README.
- [ ] `CONTRIBUTING.md` per contributi esterni (livelli della community?).

---

## Idee per dopo (backlog)
- Modalità sfida giornaliera con seed condiviso.
- Multiplayer locale a turni (stesso dispositivo).
- Campi creati dagli utenti caricabili da file.
- Modalità allenamento in singolo.
- Porting a Godot 4 se si abbandona il Pi 3.
