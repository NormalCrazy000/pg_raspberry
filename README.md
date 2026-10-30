# pg_raspberry

Gioco 2D originale del genere "peg shooter": si lancia una palla dall'alto e la si fa rimbalzare su un campo di pioli.
Open source, pensato per Linux desktop e per **Raspberry Pi 3** (versione portatile).

> **Stato:** Fase 1, prototipo giocabile con un livello e grafica provvisoria. Vedi [ROADMAP.md](ROADMAP.md).

## Requisiti

- [Godot 3.6.3](https://godotengine.org/download/3.x/) (non Godot 4: il Pi 3 supporta solo OpenGL ES 2.0)
- Export template di Godot 3.6.3 (servono solo per creare le build)

## Avvio rapido

```bash
godot3 --path .             # Linux, dal sorgente
tools/export.sh arm64       # build per Raspberry Pi (anche: x86_64, arm32, oppure tutte senza argomenti)
```

Obiettivo: eliminare tutti i pioli rossi prima di finire le palle. Se la palla cade nel cestino mobile, viene recuperata.
Si mira con mouse, touch, frecce o stick e si lancia con click, spazio o A.

Guide:
- [docs/comandi.md](docs/comandi.md): tutti i comandi per giocare su Linux e Raspberry Pi, dal sorgente o dalla build, opzioni e controlli
- [docs/raspberry-pi.md](docs/raspberry-pi.md): preparazione del Pi e benchmark

## Struttura

```
scenes/    scene Godot (.tscn)
scripts/   script GDScript
assets/    grafica, suoni, musica, font
levels/    livelli (JSON, formato descritto in scripts/game/level_loader.gd)
tools/     script di build e benchmark
docs/      documentazione
```

## Licenza

Codice sotto licenza [MIT](LICENSE). Asset e attribuzioni in [ASSETS.md](ASSETS.md).
