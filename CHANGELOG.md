# Changelog

Formato ispirato a [Keep a Changelog](https://keepachangelog.com/it-IT/1.1.0/), versioni secondo [Semantic Versioning](https://semver.org/lang/it/).

## [Non rilasciato]

### Raspberry Pi (dal primo benchmark su Pi 3B+)
- Vsync spento in automatico sul Pi, con limite a 60 FPS: con il vsync il Pi 3 restava bloccato a circa 20 FPS.
  Nuova opzione "Sincronia verticale" (automatica, attiva, spenta).
- La CPU difficile calcola al massimo 5 ms per frame, qualunque sia la velocità del processore.
- `--measure` ignora il primo secondo (caricamento) e considera picchi i frame lunghi almeno 2,5 volte un frame tipico.
- `tools/pi_report.sh`: benchmark completo in un solo comando, con spiegazione dei codici di throttling.

### Gioco
- Bonus "Tiro lungo" (due bug lontani nello stesso tiro) e "Combo" (10+ pioli toccati dalla stessa paperella).
- Refactoring di Giulia: una sola onda d'urto per tiro.
- La CPU difficile sfrutta la mira estesa di Sara.
- Classifica dei 10 migliori punteggi nella schermata Statistiche.

### Licenza
- Il codice passa da MIT a **GNU GPL v3** e gli asset originali da CC BY 4.0 a **CC BY-SA 4.0**:
  chi distribuisce o vende il gioco deve farlo con la stessa licenza e con il codice sorgente.
  Le versioni 0.1.0 e 0.1.1 restano disponibili con le licenze con cui sono state pubblicate.

### Pacchetti
- Archivi ed eseguibili rinominati: `hotfix-friday-<piattaforma>.tar.gz`, `hotfix-friday.<arch>`.

## [0.1.1] - 2026-10-30

### Prestazioni
- La CPU "difficile" distribuisce i calcoli su più frame: niente più blocco di un frame a ogni suo turno sul Raspberry Pi.
- I caratteri dei font vengono preparati all'avvio invece che alla prima comparsa in partita.
- `--measure` stampa anche i frame più lenti (`PICCHI`) con gli eventi in corso, per diagnosticare i blocchi.

## [0.1.0] - 2026-10-30

Prima versione pubblica.

### Gioco
- Sfida a turni a due giocatori sullo stesso dispositivo, oppure contro la CPU (facile, normale, difficile).
- Campi generati da un seme: archi, griglie, rampe, anelli, pioli in movimento e portali; rivincita sullo stesso campo.
- Bug (obiettivi), puntine, righe di codice e tazze di caffè; moltiplicatore condiviso; paperelle extra e cestino mobile.
- Quattro personaggi con un potere ciascuno: Refactoring (Giulia), Fork (Marco), Test coverage (Sara), Hotfix (Dario).
- Sistema di poteri estendibile (`docs/poteri.md`).

### Grafica e audio
- Grafica vettoriale originale, sfondo "editor di codice", aloni, particelle e scia.
- Effetti sonori e musica lo-fi sintetizzati da codice; font JetBrains Mono (OFL).

### Interfaccia
- Menu, pausa, opzioni (volumi, schermo intero, velocità di mira, qualità grafica, lingua), statistiche, crediti.
- Italiano e inglese. Controlli con mouse, touch, tastiera e gamepad.

### Piattaforme
- Linux x86_64 e Raspberry Pi (arm64, arm32) con Godot 3.6.3 (GLES2); qualità grafica automatica sul Pi.
- `install.sh` per menu delle applicazioni e avvio automatico; build automatiche con GitHub Actions.

### Da verificare
- Prestazioni su Raspberry Pi 3 reale (vedi `docs/raspberry-pi.md`).
