# Domande aperte e decisioni

## Ancora aperte

1. **Benchmark sul Raspberry Pi 3.** Con `./rpi_bench.sh` (dentro l'archivio arm64/arm32, dalla versione 0.1.1)
   servono le righe `RISULTATO`, `PRESTAZIONI` e `PICCHI`, più temperatura e throttling (istruzioni in `docs/raspberry-pi.md`).
   Da questi dati dipendono le prossime ottimizzazioni e la qualità grafica predefinita sul Pi.
2. **Equilibrio dei personaggi con i nuovi bonus.** Nelle sfide automatiche (CPU normale) Giulia vince il 49%, Marco il 55%,
   Dario il 45%; Sara non è misurabile così (la sua mira estesa aiuta soprattutto le persone). Da confermare giocando.

## Decisioni prese (30 ottobre 2026)

### Sfida
| Tema | Decisione |
|---|---|
| Durata | 8 paperelle a testa, 20 bug, 2 caffè per campo |
| Moltiplicatore | condiviso tra i giocatori (x2 al 33%, x3 al 66%, x5 all'85% dei bug) |
| Chi inizia | il giocatore 1; nella rivincita si alterna |
| Paperella recuperata e paperelle extra | a chi ha tirato |
| Fine sfida | vincitore e punteggi, senza stelle |
| Bonus per tiri particolari | **sì**: "Tiro lungo" (due bug a 400+ px nello stesso tiro, 2.500 × moltiplicatore) e "Combo" (10+ pioli toccati dalla stessa paperella, 5.000 × moltiplicatore) |

### Personaggi e CPU
| Tema | Decisione |
|---|---|
| Hotfix di Dario | rafforzato: raggio 200 px, attrazione 900, dura anche il tiro successivo |
| Refactoring di Giulia | **una sola onda per tiro** (un secondo caffè dà solo i punti) |
| Stesso personaggio per entrambi | permesso |
| Personaggio della CPU | casuale |
| CPU difficile e Sara | **sì**: con la mira estesa attiva la CPU difficile si fida dei rimbalzi e prova più varianti |
| CPU difficile sul Pi | calcoli distribuiti su più frame (6 simulazioni per frame) per non bloccare il gioco |

### Grafica, audio e interfaccia
| Tema | Decisione |
|---|---|
| Paperella | immagine 22 px, collisione 14 px |
| Stile grafico e font | confermati (SVG originali, JetBrains Mono) |
| Suoni e musica | confermati; volumi regolabili in Opzioni |
| Bug rettangolari | chiari così (righe rosse con la sottolineatura degli errori) |
| Lingua iniziale | quella del sistema operativo |
| Statistiche | **aggiunta la classifica dei 10 migliori punteggi** |
| Pulsante di pausa e altre lingue | invariati |

### Progetto
| Tema | Decisione |
|---|---|
| Nome | **archivi ed eseguibili rinominati in `hotfix-friday`**; il repository su GitHub va rinominato dalle impostazioni del repo |
| Campi generati | invariati (80% simmetrici) |
| Grafica automatica sul Pi | bassa, da rivedere dopo il benchmark |
| Pacchetti | solo `.tar.gz` con `install.sh` |
