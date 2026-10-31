# Comandi per eseguire il gioco

Due modi per giocare, su entrambe le piattaforme:

- **Dal sorgente**: serve Godot 3.6.3, il gioco parte direttamente dalla cartella del repo. Comodo per sviluppare.
- **Dalla build esportata**: un eseguibile autonomo, senza bisogno di Godot. È quello che si distribuisce.

---

## Linux desktop (x86_64)

### Installare Godot 3.6.3 (una volta sola)

```bash
mkdir -p ~/.local/share/godot3 ~/.local/bin && cd ~/.local/share/godot3
B=https://github.com/godotengine/godot/releases/download/3.6.3-stable
curl -LO $B/Godot_v3.6.3-stable_x11.64.zip
curl -LO $B/Godot_v3.6.3-stable_linux_headless.64.zip
curl -LO $B/SHA512-SUMS.txt
grep -E "_x11.64.zip|linux_headless.64.zip" SHA512-SUMS.txt | grep -v mono | sha512sum -c
unzip -o Godot_v3.6.3-stable_x11.64.zip && unzip -o Godot_v3.6.3-stable_linux_headless.64.zip
ln -sf $PWD/Godot_v3.6.3-stable_x11.64 ~/.local/bin/godot3
ln -sf $PWD/Godot_v3.6.3-stable_linux_headless.64 ~/.local/bin/godot3-headless
```

Gli export template (servono solo per creare le build) si installano dall'editor:
_Editor → Manage Export Templates → Download_.

### Giocare dal sorgente

La prima volta dopo un `git clone`, Godot deve importare grafica, suoni e traduzioni
(si apre una finestra per qualche secondo e si chiude da sola):

```bash
godot3 --path . --editor --quit
```

> La versione headless (`godot3-headless --editor --quit`) importa ma non si chiude da sola a causa dei font:
> usa quella con finestra. Gli export (`tools/export.sh`) importano da soli e non hanno questo problema.

Poi, dalla cartella del repo:

```bash
godot3 --path .                 # gioca (parte dal menu dei personaggi)
godot3 --path . --editor        # apre l'editor
godot3 --path . --bench         # benchmark delle prestazioni
```

### Creare e lanciare la build

```bash
tools/export.sh x86_64
cd build/hotfix-friday-linux-x86_64
./hotfix-friday.x86_64
```

L'archivio `build/hotfix-friday-linux-x86_64.tar.gz` si può copiare su qualsiasi PC Linux a 64 bit.
Dentro c'è `install.sh`, che aggiunge il gioco al menu delle applicazioni (vedi [raspberry-pi.md](raspberry-pi.md#installazione-menu-delle-applicazioni-e-avvio-automatico)).

### Build automatiche (GitHub Actions)

A ogni push su `main` GitHub esporta le tre build e gioca 5 sfide automatiche di prova
(`.github/workflows/build.yml`). Gli archivi si scaricano dalla pagina della run, sezione *Artifacts*.
Quando si pubblica un tag `v*` (es. `v1.0.0`) il workflow crea anche una release con gli archivi allegati.

Test rapido in locale (dopo aver importato il progetto):

```bash
tools/smoke_test.sh 10
```

---

## Raspberry Pi 3

Requisiti del sistema: Raspberry Pi OS con desktop e driver grafico KMS attivo (vedi [raspberry-pi.md](raspberry-pi.md)).
Per sapere se il sistema è a 64 o 32 bit:

```bash
uname -m          # aarch64 = 64 bit (arm64), armv7l = 32 bit (arm32)
```

### Opzione A: build esportata dal PC (consigliata)

Sul PC:

```bash
tools/export.sh arm64           # oppure arm32
scp build/hotfix-friday-rpi-arm64.tar.gz pi@raspberrypi.local:~
```

Sul Pi:

```bash
tar -xzf hotfix-friday-rpi-arm64.tar.gz
cd hotfix-friday-rpi-arm64
./hotfix-friday.arm64            # gioca
./rpi_bench.sh                  # benchmark completo
```

Da SSH, per aprire il gioco sullo schermo del Pi:

```bash
DISPLAY=:0 ./hotfix-friday.arm64
```

### Opzione B: dal sorgente, direttamente sul Pi

Utile per provare modifiche senza passare dal PC. L'editor sul Pi 3 è lento, ma il gioco parte senza problemi.

```bash
# Godot 3.6.3 per ARM (una volta sola). Sostituisci arm64 con arm32 su sistema a 32 bit.
mkdir -p ~/.local/share/godot3 ~/.local/bin && cd ~/.local/share/godot3
B=https://github.com/godotengine/godot/releases/download/3.6.3-stable
curl -LO $B/Godot_v3.6.3-stable_linux.arm64.zip
curl -LO $B/SHA512-SUMS.txt
grep "linux.arm64.zip" SHA512-SUMS.txt | sha512sum -c
unzip -o Godot_v3.6.3-stable_linux.arm64.zip
ln -sf $PWD/Godot_v3.6.3-stable_linux.arm64 ~/.local/bin/godot3

# Sorgente del gioco
git clone <url-del-repo> hotfix-friday
cd hotfix-friday
godot3 --path .                 # gioca
godot3 --path . --bench         # benchmark
```

Se `~/.local/bin` non è nel `PATH`, apri un nuovo terminale o lancia direttamente `~/.local/bin/godot3`.

---

## Opzioni da riga di comando

Valgono sia con `godot3 --path .` sia con l'eseguibile esportato. Senza opzioni il gioco parte dal menu principale.

| Opzione | Effetto |
|---|---|
| `--cpu=easy\|normal\|hard` | salta il menu: sfida contro la CPU (il giocatore 2) |
| `--training` | salta il menu: allenamento in singolo (con `--autoplay` gioca la CPU) |
| `--p1=ID`, `--p2=ID` | personaggi dei due giocatori (`giulia`, `marco`, `sara`, `dario`); `--character=ID` equivale a `--p1` |
| `--seed=N` | campo e tiri della CPU riproducibili (il numero del campo è mostrato a fine sfida) |
| `--level=res://levels/level_01.json` | campo fisso da file JSON invece che generato |
| `--debug-power` | il potere si attiva a inizio sfida e al primo piolo di ogni tiro (per provarlo) |
| `--autoplay[=random\|easy\|normal\|hard]` | entrambi i giocatori sono CPU (default `normal`); stampa il risultato ed esce. Con due valori separati da virgola (es. `hard,easy`) uno per giocatore |
| `--screenshot=FILE.png` | salva uno screenshot dopo `--screenshot-delay=S` secondi (default 2) ed esce |
| `--novsync` | disattiva il vsync (con `--fixed-fps 60` la partita va più veloce del tempo reale) |
| `--bench` | benchmark della scena di prova: opzioni in [raspberry-pi.md](raspberry-pi.md#3-benchmark) |
| `--measure` | con `--autoplay`: misura FPS e draw call di una sfida vera, a tempo reale e con l'audio |
| `--lang=it\|en` | forza la lingua per questa esecuzione (senza salvarla nelle opzioni) |
| `--graphics=auto\|high\|low` | forza la qualità grafica per questa esecuzione |
| `--fullscreen` | schermo intero (opzione standard di Godot) |

Esempi:

```bash
godot3 --path . --cpu=hard --p1=sara              # tu con Sara contro la CPU difficile
godot3 --path . --cpu=normal --seed=44            # sempre lo stesso campo
godot3 --path . --p1=marco --cpu=easy --debug-power
```

Test veloce senza finestra (solo dal sorgente su Linux desktop):

```bash
godot3-headless --path . --fixed-fps 60 --autoplay=normal --seed=1
```

Statistiche su molte sfide (vincitore, punteggi, poteri, portali), utili per il bilanciamento:

```bash
seq 1 100 | xargs -P 8 -I{} godot3-headless --path . --fixed-fps 60 --autoplay=hard,normal --p1=sara --p2=sara --seed={} 2>/dev/null | grep AUTOPLAY
```

## Controlli

| Azione | Mouse | Touch | Tastiera / gamepad |
|---|---|---|---|
| Mirare | muovi il mouse | trascina | frecce / stick / d-pad |
| Lanciare | rilascia il click | rilascia il dito | spazio / A |
| Pausa | pulsante "II" in alto | pulsante "II" in alto | `Esc` / Start |
| Rivincita sullo stesso campo (a fine sfida) | pulsante | pulsante | pulsante oppure `R` |

Nei menu: frecce/stick per scegliere, Invio/A/click per confermare, Esc/B per tornare indietro.
A fine sfida e in pausa le scelte sono pulsanti, utilizzabili anche solo con il touch o il gamepad.

## Dati salvati

| File | Contenuto |
|---|---|
| `~/.local/share/hotfix_friday/settings.json` | opzioni (volumi, schermo intero, velocità di mira, lingua) |
| `~/.local/share/hotfix_friday/stats.json` | statistiche delle sfide giocate da persone |

Per tornare alle impostazioni iniziali basta cancellare questi file.
Nella sfida a 2 giocatori ci si passa il dispositivo: l'HUD evidenzia di chi è il turno.
