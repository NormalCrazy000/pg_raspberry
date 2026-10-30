# Hotfix Friday

Venerdì pomeriggio, ufficio di programmatori: bisogna chiudere i bug prima del rilascio.
Gioco 2D originale del genere "peg shooter": si lanciano paperelle di gomma su un campo di righe di codice per eliminare i bug.
Ogni personaggio ha un potere che si attiva colpendo una tazza di caffè.
Open source, pensato per Linux desktop e per **Raspberry Pi 3** (versione portatile).

> **Stato:** Fase 4, sfida a 2 giocatori o contro la CPU (3 difficoltà) su campi generati con pioli mobili e portali; grafica provvisoria. Vedi [ROADMAP.md](ROADMAP.md).

## Requisiti

- [Godot 3.6.3](https://godotengine.org/download/3.x/) (non Godot 4: il Pi 3 supporta solo OpenGL ES 2.0)
- Export template di Godot 3.6.3 (servono solo per creare le build)

## Avvio rapido

```bash
godot3 --path .             # Linux, dal sorgente
tools/export.sh arm64       # build per Raspberry Pi (anche: x86_64, arm32, oppure tutte senza argomenti)
```

Sfida a turni, a due giocatori sullo stesso dispositivo o contro la CPU: si tira una paperella a testa sullo stesso campo,
i punti vanno a chi tira e vince chi ne ha di più quando i bug (pioli rossi) sono finiti. Ogni campo è generato da codice.
Si mira con mouse, touch, frecce o stick e si lancia rilasciando il click/dito, oppure con spazio o A.

Guide:
- [docs/comandi.md](docs/comandi.md): tutti i comandi per giocare su Linux e Raspberry Pi, dal sorgente o dalla build, opzioni e controlli
- [docs/raspberry-pi.md](docs/raspberry-pi.md): preparazione del Pi e benchmark
- [docs/poteri.md](docs/poteri.md): personaggi, poteri e come aggiungerne di nuovi
- [docs/domande-aperte.md](docs/domande-aperte.md): decisioni di design ancora da confermare

## Struttura

```
scenes/    scene Godot (.tscn)
scripts/   script GDScript
assets/    grafica, suoni, musica, font
levels/    campi fissi in JSON (opzionali, formato in scripts/game/level_loader.gd)
data/      dati di gioco (personaggi)
tools/     script di build e benchmark
docs/      documentazione
```

## Licenza

Codice sotto licenza [MIT](LICENSE). Asset e attribuzioni in [ASSETS.md](ASSETS.md).
