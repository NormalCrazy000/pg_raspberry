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

Dalla cartella del repo:

```bash
godot3 --path .                 # gioca
godot3 --path . --editor        # apre l'editor
godot3 --path . --bench         # benchmark delle prestazioni
```

### Creare e lanciare la build

```bash
tools/export.sh x86_64
cd build/linux-x86_64
./pg_raspberry.x86_64
```

L'archivio `build/pg_raspberry-linux-x86_64.tar.gz` si può copiare su qualsiasi PC Linux a 64 bit.

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
scp build/pg_raspberry-rpi-arm64.tar.gz pi@raspberrypi.local:~
```

Sul Pi:

```bash
tar -xzf pg_raspberry-rpi-arm64.tar.gz
cd rpi-arm64
./pg_raspberry.arm64            # gioca
./rpi_bench.sh                  # benchmark completo
```

Da SSH, per aprire il gioco sullo schermo del Pi:

```bash
DISPLAY=:0 ./pg_raspberry.arm64
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
git clone <url-del-repo> pg_raspberry
cd pg_raspberry
godot3 --path .                 # gioca
godot3 --path . --bench         # benchmark
```

Se `~/.local/bin` non è nel `PATH`, apri un nuovo terminale o lancia direttamente `~/.local/bin/godot3`.

---

## Opzioni da riga di comando

Valgono sia con `godot3 --path .` sia con l'eseguibile esportato.

| Opzione | Effetto |
|---|---|
| `--level=res://levels/level_01.json` | carica un livello specifico |
| `--autoplay` | partita automatica con tiri casuali, stampa il risultato ed esce |
| `--seed=N` | rende ripetibili obiettivi e tiri automatici |
| `--screenshot=FILE.png` | salva uno screenshot dopo `--screenshot-delay=S` secondi (default 2) |
| `--bench` | benchmark: opzioni in [raspberry-pi.md](raspberry-pi.md#3-benchmark) |
| `--fullscreen` | schermo intero (opzione standard di Godot) |

Test veloce senza finestra (solo dal sorgente su Linux desktop):

```bash
godot3-headless --path . --fixed-fps 60 --autoplay --seed=1
```

## Controlli

| Azione | Mouse | Touch | Tastiera / gamepad |
|---|---|---|---|
| Mirare | muovi il mouse | trascina | frecce / stick / d-pad |
| Lanciare | click | rilascia il dito | spazio / A |
| Ricominciare | | | `R` |
| Uscire | | | `Esc` |
