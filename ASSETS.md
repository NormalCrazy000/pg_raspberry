# Asset e licenze

Il codice è rilasciato sotto licenza **GNU GPL v3** (vedi `LICENSE`).
Gli asset originali del progetto sono rilasciati sotto **CC BY-SA 4.0** salvo diversa indicazione.
Fino alla versione 0.1.1 le licenze erano MIT (codice) e CC BY 4.0 (asset).

Regole:
- Sono ammessi solo asset originali o di terzi con licenza **CC0**, **CC BY** o **CC BY-SA** (con attribuzione).
- Ogni asset di terzi va aggiunto alla tabella qui sotto **nello stesso commit** in cui entra nel repo.
- Vietato usare o ricreare asset, nomi, personaggi, musiche o livelli di giochi esistenti.

| File | Autore | Fonte | Licenza |
|---|---|---|---|
| `assets/sprites/*.svg`, `assets/sprites/characters/*.svg` | progetto Hotfix Friday | disegnati a mano per questo gioco | CC BY-SA 4.0 |
| `assets/sprites/background.svg` | progetto Hotfix Friday | generato da `tools/assets/make_background.py` | CC BY-SA 4.0 |
| `assets/audio/*.wav`, `assets/audio/music.ogg` | progetto Hotfix Friday | sintetizzati da `tools/assets/make_audio.py` (nessun campione esterno) | CC BY-SA 4.0 |
| `assets/fonts/JetBrainsMono-Regular.ttf`, `assets/fonts/JetBrainsMono-Bold.ttf` | The JetBrains Mono Project Authors | [github.com/JetBrains/JetBrainsMono](https://github.com/JetBrains/JetBrainsMono) v2.304 | SIL OFL 1.1 (`assets/fonts/OFL.txt`) |

Per rigenerare sfondo e suoni: `python3 tools/assets/make_background.py` e `python3 tools/assets/make_audio.py` (servono numpy e ffmpeg).

## Software di terzi

| Componente | Licenza |
|---|---|
| [Godot Engine](https://godotengine.org/license) 3.6.3 | MIT |
| JetBrains Mono (font) | SIL OFL 1.1 |
