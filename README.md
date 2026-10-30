# pg_raspberry

Gioco 2D originale del genere "peg shooter": si lancia una palla dall'alto e la si fa rimbalzare su un campo di pioli.
Open source, pensato per Linux desktop e per **Raspberry Pi 3** (versione portatile).

> **Stato:** Fase 0, prototipo tecnico per misurare le prestazioni. Vedi [ROADMAP.md](ROADMAP.md).

## Requisiti

- [Godot 3.6.3](https://godotengine.org/download/3.x/) (non Godot 4: il Pi 3 supporta solo OpenGL ES 2.0)
- Export template di Godot 3.6.3 (servono solo per creare le build)

## Avvio

```bash
godot3 --path .             # avvia il gioco
godot3 --path . --editor    # apre l'editor
```

Comandi del prototipo: mouse/touch per mirare e lanciare, frecce/stick per mirare, spazio/A per lanciare,
`R` per ripristinare i pioli, `Esc` per uscire.

## Build

```bash
tools/export.sh             # tutte le piattaforme
tools/export.sh arm64       # solo Raspberry Pi 64 bit (anche: x86_64, arm32)
```

Gli archivi finiscono in `build/`. Per installare e provare il gioco sul Pi: [docs/raspberry-pi.md](docs/raspberry-pi.md).

## Struttura

```
scenes/    scene Godot (.tscn)
scripts/   script GDScript
assets/    grafica, suoni, musica, font
levels/    livelli
tools/     script di build e benchmark
docs/      documentazione
```

## Licenza

Codice sotto licenza [MIT](LICENSE). Asset e attribuzioni in [ASSETS.md](ASSETS.md).
