# Raspberry Pi 3: setup, installazione e benchmark

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
scp build/hotfix-friday-rpi-arm64.tar.gz pi@raspberrypi.local:~
```

Sul Pi:
```bash
tar -xzf hotfix-friday-rpi-arm64.tar.gz
cd hotfix-friday-rpi-arm64
./hotfix-friday.arm64             # modalità interattiva
```

Se sei collegato via SSH, il gioco va aperto sullo schermo del Pi:
```bash
DISPLAY=:0 ./hotfix-friday.arm64
```

### Installazione (menu delle applicazioni e avvio automatico)

Dalla cartella estratta:

```bash
./install.sh               # aggiunge Hotfix Friday al menu delle applicazioni (Giochi)
./install.sh --autostart   # in più lo avvia a schermo intero all'accensione: ideale per il Pi portatile
./install.sh --uninstall   # rimuove tutto (statistiche e opzioni restano)
```

Non servono permessi di amministratore: tutto va in `~/.local` e `~/.config/autostart`.

### Qualità grafica

In Opzioni → Qualità grafica:

| Modalità | Effetto |
|---|---|
| Automatica (predefinita) | bassa se rileva la GPU del Raspberry Pi (VideoCore) o un processore ARM, altrimenti alta |
| Alta | aloni sui pioli colpiti, particelle, scia della paperella |
| Bassa | senza questi effetti: circa il 40% di draw call in meno |

Per una prova senza cambiare le opzioni: `./hotfix-friday.arm64 --graphics=high` (oppure `low`).

## 3. Benchmark

```bash
./rpi_bench.sh          # 6 configurazioni da 20 s + una sfida vera (circa 4 minuti)
./rpi_bench.sh 10       # più veloce
```

L'ultima prova (`--autoplay=normal --measure`) gioca una sfida CPU contro CPU con grafica, effetti e audio
e stampa una riga `PRESTAZIONI`: è il dato più vicino all'esperienza reale.
Subito dopo, `PICCHI` elenca i frame più lenti (oltre 50 ms, cioè i blocchi visibili) con quello che stava succedendo:

```
PICCHI 3 frame oltre 50 ms
   180 ms  cpu
    75 ms  pioli via, cambio turno
```

Lo script stampa i risultati e li aggiunge a
`~/.local/share/hotfix_friday/bench_results.csv`.

Lancio manuale di una singola configurazione:
```bash
./hotfix-friday.arm64 --bench --pegs=150 --balls=3 --fx --duration=30
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

## 5. Versione portatile

Configurazione pensata per giocare in giro:

| Componente | Note |
|---|---|
| Raspberry Pi 3 (B o B+) | con dissipatore: evita il throttling durante le sessioni lunghe |
| Display touch ufficiale 7" (800×480) | è la risoluzione nativa del gioco; con il touch si gioca senza altro |
| Powerbank USB da almeno 2,5 A | sotto questa soglia il Pi rallenta (vedi `vcgencmd get_throttled`) |
| Gamepad USB o Bluetooth (opzionale) | stick o d-pad per mirare, A per lanciare, Start per la pausa |
| Case per Pi + display | meglio se lascia accesso alle porte USB per il gamepad |

Con `./install.sh --autostart` il Pi avvia direttamente il gioco a schermo intero: accendi e giochi.
Nella sfida a due ci si passa il Pi (touch) o il gamepad; l'HUD evidenzia di chi è il turno.

## Problemi comuni

- **"Your video card driver does not support any of the supported OpenGL versions"**: driver KMS non attivo, vedi punto 1.
- **Il gioco non si apre via SSH**: manca `DISPLAY=:0`, oppure nessuno ha fatto login sul desktop del Pi.
- **Prestazioni molto basse**: verifica che il Pi non vada in throttling (`vcgencmd get_throttled` deve restituire `0x0`): serve un alimentatore da 2,5 A.
