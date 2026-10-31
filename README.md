# Hotfix Friday

Venerdì pomeriggio, ufficio di programmatori: bisogna chiudere i bug prima del rilascio.
Gioco 2D originale del genere "peg shooter": si lanciano paperelle di gomma su un campo di righe di codice per eliminare i bug.
Ogni personaggio ha un potere che si attiva colpendo una tazza di caffè.
Open source, pensato per Linux desktop e per **Raspberry Pi 3** (versione portatile).

> **Versione 0.2.3.** Gioco completo per Linux e Raspberry Pi (60 FPS stabili sul Pi 3B+).
> Novità in [CHANGELOG.md](CHANGELOG.md), scelte di progetto in [docs/architettura.md](docs/architettura.md).

| | | |
|---|---|---|
| ![Menu principale](docs/screenshots/menu.png) | ![Scelta del personaggio](docs/screenshots/personaggi.png) | ![Una sfida in corso](docs/screenshots/partita.png) |

## Scaricare e giocare

Dalla pagina [Releases](../../releases) scarica l'archivio per il tuo sistema:

| Archivio | Per |
|---|---|
| `hotfix-friday-linux-x86_64.tar.gz` | PC Linux a 64 bit |
| `hotfix-friday-rpi-arm64.tar.gz` | Raspberry Pi con sistema a 64 bit |
| `hotfix-friday-rpi-arm32.tar.gz` | Raspberry Pi con sistema a 32 bit |

```bash
tar -xzf hotfix-friday-linux-x86_64.tar.gz
cd hotfix-friday-linux-x86_64
./hotfix-friday.x86_64        # gioca subito
./install.sh                 # oppure aggiungilo al menu delle applicazioni
```

## Requisiti

- [Godot 3.6.3](https://godotengine.org/download/3.x/) (non Godot 4: i Raspberry Pi 2 e 3 supportano solo OpenGL ES 2.0)
- Export template di Godot 3.6.3 (servono solo per creare le build)

## Dal sorgente

```bash
godot3 --path . --editor --quit   # solo la prima volta dopo il clone: importa gli asset
godot3 --path .             # Linux, dal sorgente
tools/export.sh arm64       # build per Raspberry Pi (anche: x86_64, arm32, oppure tutte senza argomenti)
```

Sfida a turni, a due giocatori sullo stesso dispositivo o contro la CPU: si tira una paperella a testa sullo stesso campo,
i punti vanno a chi tira e vince chi ne ha di più quando i bug (pioli rossi) sono finiti.
Attenzione: un tiro che non elimina nessun bug dimezza il tuo punteggio. Ogni campo è generato da codice.
In **Allenamento** si gioca da soli per prendere fino a 3 stelle e battere il proprio record.
Nel **Torneo** da 4 a 8 persone si sfidano a eliminazione diretta; il torneo si salva e si riprende dopo ogni partita.
Si mira con mouse, touch, frecce o stick e si lancia rilasciando il click/dito, oppure con spazio o A.

Guide:
- [docs/architettura.md](docs/architettura.md): concept, modalità, perché Godot 3.6 e vincoli dovuti al Raspberry Pi
- [docs/comandi.md](docs/comandi.md): tutti i comandi per giocare su Linux e Raspberry Pi, dal sorgente o dalla build, opzioni e controlli
- [docs/raspberry-pi.md](docs/raspberry-pi.md): preparazione del Pi e benchmark
- [docs/poteri.md](docs/poteri.md): personaggi, poteri e come aggiungerne di nuovi

## Struttura

```
scenes/    scene Godot (.tscn)
scripts/   script GDScript
levels/    campi fissi in JSON (opzionali, formato in scripts/game/level_loader.gd)
assets/    grafica (SVG), suoni, musica e font
data/      dati di gioco (personaggi)
locale/    traduzioni italiano/inglese (translations.csv)
tools/     build, installazione, test, benchmark e generazione di sfondo e suoni
docs/      documentazione
```

## Contribuire

Nuovi poteri, personaggi, lingue e figure dei campi sono pensati per essere aggiunti facilmente:
vedi [CONTRIBUTING.md](CONTRIBUTING.md).

## Licenza

Copyright © 2026 normalcrazy.

- **Codice:** [GNU GPL v3](LICENSE). Puoi usare, modificare, distribuire e anche vendere il gioco,
  ma chi lo distribuisce (modificato o no) deve farlo con la stessa licenza e rendere disponibile il codice sorgente.
- **Grafica, suoni e musica originali:** [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.it):
  stesse regole, chi li modifica deve condividerli con la stessa licenza.
- Componenti di terzi con le loro licenze (Godot Engine MIT, font JetBrains Mono OFL): dettagli in [ASSETS.md](ASSETS.md).

Se in futuro arrivassero funzioni online (classifica globale, multiplayer in rete) il codice passerebbe ad AGPL-3.0:
per ora resta GPL-3.0.

Le versioni fino alla 0.1.1 sono state pubblicate con licenza MIT (codice) e CC BY 4.0 (asset) e restano disponibili con quelle licenze.
