# Hotfix Friday

Venerdì pomeriggio, ufficio di programmatori: bisogna chiudere i bug prima del rilascio.
Gioco 2D originale del genere "peg shooter": si lanciano paperelle di gomma su un campo di righe di codice per eliminare i bug.
Ogni personaggio ha un potere che si attiva colpendo una tazza di caffè.
Open source, pensato per Linux desktop e per **Raspberry Pi 3** (versione portatile).

> **Stato:** Fase 3, quattro personaggi con poteri, menu di selezione, un campo di gioco; grafica provvisoria. Vedi [ROADMAP.md](ROADMAP.md).

## Requisiti

- [Godot 3.6.3](https://godotengine.org/download/3.x/) (non Godot 4: il Pi 3 supporta solo OpenGL ES 2.0)
- Export template di Godot 3.6.3 (servono solo per creare le build)

## Avvio rapido

```bash
godot3 --path .             # Linux, dal sorgente
tools/export.sh arm64       # build per Raspberry Pi (anche: x86_64, arm32, oppure tutte senza argomenti)
```

Obiettivo: eliminare tutti i bug (pioli rossi) prima di finire le paperelle. Se la paperella cade nel cestino mobile, viene recuperata.
Si mira con mouse, touch, frecce o stick e si lancia rilasciando il click/dito, oppure con spazio o A.

Guide:
- [docs/comandi.md](docs/comandi.md): tutti i comandi per giocare su Linux e Raspberry Pi, dal sorgente o dalla build, opzioni e controlli
- [docs/raspberry-pi.md](docs/raspberry-pi.md): preparazione del Pi e benchmark
- [docs/poteri.md](docs/poteri.md): personaggi, poteri e come aggiungerne di nuovi

## Struttura

```
scenes/    scene Godot (.tscn)
scripts/   script GDScript
assets/    grafica, suoni, musica, font
levels/    livelli (JSON, formato descritto in scripts/game/level_loader.gd)
data/      dati di gioco (personaggi)
tools/     script di build e benchmark
docs/      documentazione
```

## Licenza

Codice sotto licenza [MIT](LICENSE). Asset e attribuzioni in [ASSETS.md](ASSETS.md).
