# Raspberry Pi 3: setup e benchmark

## 1. Sistema operativo

- **Raspberry Pi OS (Bookworm) con desktop**, 64 bit (usa la build `arm64`) oppure 32 bit (usa la build `arm32`).
- Il driver grafico deve essere quello **KMS** (`vc4`), attivo di default. Verifica in `/boot/firmware/config.txt`:
  ```
  dtoverlay=vc4-kms-v3d
  ```
- Controllo del driver OpenGL:
  ```bash
  sudo apt install mesa-utils
  glxinfo -B | grep -E "renderer|version"
  ```
  Deve comparire `VC4 V3D 2.1` e supporto a OpenGL ES 2.0.

## 2. Copiare il gioco sul Pi

Sul PC, dalla root del repo:
```bash
tools/export.sh arm64            # oppure arm32
scp build/pg_raspberry-rpi-arm64.tar.gz pi@raspberrypi.local:~
```

Sul Pi:
```bash
tar -xzf pg_raspberry-rpi-arm64.tar.gz
cd rpi-arm64
./pg_raspberry.arm64             # modalità interattiva
```

Se sei collegato via SSH, il gioco va aperto sullo schermo del Pi:
```bash
DISPLAY=:0 ./pg_raspberry.arm64
```

## 3. Benchmark

```bash
./rpi_bench.sh          # 6 configurazioni da 20 s (circa 2,5 minuti)
./rpi_bench.sh 10       # più veloce
```

Lo script stampa i risultati e li aggiunge a
`~/.local/share/godot/app_userdata/pg_raspberry/bench_results.csv`.

Lancio manuale di una singola configurazione:
```bash
./pg_raspberry.arm64 --bench --pegs=150 --balls=3 --fx --duration=30
```

| Opzione | Significato |
|---|---|
| `--bench` | modalità benchmark: lancia palle automaticamente, stampa i risultati ed esce |
| `--pegs=N` | numero di pioli (default 100) |
| `--balls=N` | palle contemporaneamente in gioco (default 1) |
| `--duration=S` | durata in secondi, esclusi 2 s di riscaldamento (default 30) |
| `--fx` | particelle a ogni colpo |
| `--novsync` | disattiva il vsync per misurare il margine oltre i 60 FPS |

## 4. Come leggere i risultati

Il caso di riferimento è `--pegs=100 --balls=1` con vsync (una partita normale).

| Risultato (fps medi / 1% low) | Decisione |
|---|---|
| ≥ 55 / ≥ 45 | ✅ Via libera, si procede con la Fase 1 |
| 30–55 | ⚠️ Si procede, ma con budget ridotti (meno pioli/effetti, fisica a 30 Hz, risoluzione più bassa) |
| < 30 | ❌ Si rivaluta lo stack prima di andare avanti |

I test con `--novsync` dicono quanto margine resta: più è alto, più spazio c'è per grafica ed effetti.

## Problemi comuni

- **"Your video card driver does not support any of the supported OpenGL versions"**: driver KMS non attivo, vedi punto 1.
- **Il gioco non si apre via SSH**: manca `DISPLAY=:0`, oppure nessuno ha fatto login sul desktop del Pi.
- **Prestazioni molto basse**: verifica che il Pi non vada in throttling (`vcgencmd get_throttled` deve restituire `0x0`): serve un alimentatore da 2,5 A.
