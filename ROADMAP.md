# Roadmap

Gioco 2D originale del genere "peg shooter" (palla lanciata dall'alto che rimbalza su un campo di pioli, stile pachinko/flipper),
open source, giocabile su Linux desktop e su **Raspberry Pi 3**.

> Nome di lavoro: _da definire_ (vedi Fase 3). Il nome **non** deve richiamare titoli esistenti.

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
- [ ] Sistema punti per tipo di piolo + moltiplicatore che cresce man mano che si eliminano gli obiettivi.
- [ ] Bonus per tiri lunghi / combo / rimbalzi.
- [ ] Palla extra al raggiungimento di soglie di punteggio.
- [ ] Rallentatore sull'ultimo obiettivo e celebrazione di fine livello (con un design nostro).
- [ ] Schermata di risultato, stelle/valutazione per livello.

### Fase 3 — Identità originale
Qui il gioco diventa "nostro". Da decidere insieme:
- [ ] **Nome** e tema (es. spazio, fondale marino, laboratorio alchemico, giardino zen, circuito elettronico...).
- [ ] **Poteri originali** (3–5) attivati da pioli speciali — es. palla che si divide, gravità invertita per un tiro, piolo-portale, palla magnetica, bomba a tempo.
- [ ] **Elementi di livello originali**: pioli mobili/rotanti, pioli che richiedono 2 colpi, bumper, muri che cambiano, portali.
- [ ] Eventuale twist di design (es. modalità puzzle con un solo tiro, roguelite con potenziamenti tra un livello e l'altro, sfida giornaliera con seed).
- [ ] Style guide visiva: palette, forme, font (font con licenza OFL).

### Fase 4 — Livelli e contenuti
- [ ] Formato livello (scene Godot `.tscn` oppure JSON) — leggibile e diffabile in git.
- [ ] **Editor di livelli** in-game o tool Godot per piazzare pioli su griglie, archi, spirali.
- [ ] Campagna iniziale: 15–25 livelli con curva di difficoltà, divisi in 3–5 mondi.
- [ ] Livelli tutorial per introdurre ogni meccanica.
- [ ] Playtest e bilanciamento (palle per livello, numero obiettivi, punteggi stelle).

### Fase 5 — Arte e audio
- [ ] Sprite pioli, palla, cannone, cestino, sfondi (originali o CC0).
- [ ] Effetti: illuminazione pioli, scie, particelle leggere (nel budget del Pi 3).
- [ ] Effetti sonori (colpo piolo con pitch crescente, lancio, cestino, vittoria) — formato OGG.
- [ ] Musica originale o CC0/CC BY, una traccia per mondo.
- [ ] `ASSETS.md` aggiornato per ogni asset aggiunto.

### Fase 6 — UI, UX e salvataggi
- [ ] Menu principale, selezione mondo/livello, pausa, opzioni (volume, schermo intero, sensibilità).
- [ ] Navigazione completa con **gamepad e touch**, non solo mouse.
- [ ] Salvataggio progressi e record in `user://` (JSON).
- [ ] Schermata crediti con licenze.
- [ ] Localizzazione IT/EN (Godot `TranslationServer` + CSV).

### Fase 7 — Ottimizzazione e packaging
- [ ] Profiling sul Pi 3: fisica, draw call, memoria; impostazioni qualità (bassa/alta).
- [ ] Export Linux x86_64 (desktop) e ARM (Pi), possibilmente via **GitHub Actions** (build automatiche).
- [ ] Pacchettizzazione: archivio `.tar.gz` / AppImage per desktop; script di installazione + avvio automatico in modalità kiosk per il Pi.
- [ ] Guida hardware per la versione portatile (Pi 3 + display 7" + powerbank + gamepad).

### Fase 8 — Release
- [ ] Versioning semantico, `CHANGELOG.md`, tag git.
- [ ] Release su GitHub con binari; opzionale pagina itch.io.
- [ ] Screenshot/GIF nel README.
- [ ] `CONTRIBUTING.md` per contributi esterni (livelli della community?).

---

## Idee per dopo (backlog)
- Modalità sfida giornaliera con seed condiviso.
- Multiplayer locale a turni (stesso dispositivo).
- Livelli creati dagli utenti caricabili da file.
- Porting a Godot 4 se si abbandona il Pi 3.
