# Domande aperte

Decisioni da confermare. Per ognuna c'è la scelta applicata **per ora** (✅ = già nel codice), così lo sviluppo può andare avanti.
Rispondi quando vuoi: basta il numero e la risposta.

## Gameplay e personaggi

1. **Magnete di Dario.** Nei test automatici Dario vinceva meno degli altri (45% contro 56–57%).
   Ho rafforzato Hotfix: raggio 200 px (era 160), attrazione 900 (era 700) e dura anche il tiro successivo.
   Ora i personaggi vincono tra il 49% e il 51%. Ti va bene così?
   - Per ora: ✅ rafforzato.
2. **Stesso personaggio per entrambi.** Nella sfida a due, i due giocatori possono scegliere lo stesso personaggio?
   - Per ora: ✅ sì, è permesso.
3. **Catena di Refactoring.** L'onda d'urto di Giulia, se prende un altro caffè, fa partire un'altra onda. Lo teniamo come effetto spettacolare o lo limitiamo a una sola onda per tiro?
   - Per ora: ✅ catena permessa.
4. **Bonus per tiri particolari** (tiro lungo tra due bug lontani, 10+ pioli in un tiro...). Li vuoi o teniamo il gioco semplice?
   - Per ora: nessun bonus extra.
5. **Moltiplicatore e soglie.** Il moltiplicatore sale con i bug eliminati (x2 al 33%, x3 al 66%, x5 all'85%) ed è condiviso tra i due giocatori. Va bene così?
   - Per ora: ✅ condiviso.

## Grafica e leggibilità

6. **Dimensione della paperella.** È grande 14 px, quasi irriconoscibile sul 7" del Pi. La ingrandisco subito (es. 20 px, cambia un po' fisica e difficoltà) o nella Fase 5 con la grafica vera?
   - Per ora: 14 px, si decide nella Fase 5.
7. **Font.** Il font di base di Godot è piccolo. Anticipo un font libero (licenza OFL) più leggibile, o aspettiamo la Fase 5?
   - Per ora: font di base.

## Sfida a due

8. **Stelle.** Con la sfida a due le stelle di fine partita hanno poco senso. Le sostituisco con l'annuncio del vincitore e i punteggi?
   - Per ora: ✅ stelle tolte, la schermata finale mostra vincitore e punteggi.
9. **Paperelle e bug per sfida.** 8 paperelle a testa e 20 bug per campo: una sfida dura circa 14 tiri in totale e quasi sempre finisce con tutti i bug eliminati. Più lunga o più corta?
   - Per ora: ✅ 8 paperelle a testa, 20 bug, 2 caffè.
10. **Chi inizia.** Nella prima sfida inizia il giocatore 1, nella rivincita si alterna. Il vantaggio di chi inizia è piccolo (~52%).
    - Per ora: ✅ alternanza nella rivincita.
11. **Personaggio della CPU.** Contro la CPU il suo personaggio è scelto a caso. Preferisci sceglierlo tu?
    - Per ora: ✅ casuale.
12. **Paperella recuperata e paperelle extra** vanno a chi ha tirato. Ok?
    - Per ora: ✅ a chi tira.
13. **Sara e la CPU.** La CPU non sfrutta la mira estesa di Sara, quindi nei test Sara risulta più debole di quanto è per una persona. Vuoi che la CPU difficile la sfrutti (più calcolo, più lenta sul Pi)?
    - Per ora: no.

## Tecniche

14. **CPU difficile sul Raspberry Pi.** Per ogni tiro simula circa 60 traiettorie: sul PC è istantaneo, sul Pi 3 potrebbe richiedere fino a circa un secondo (mascherato dalla "pausa per pensare" della CPU). Da verificare quando farai il benchmark.
15. **Campi generati.** Ti piace l'equilibrio tra figure fisse, in movimento e portali? Vuoi più o meno simmetria (ora 80%)?
16. **Nome del repository.** Il repo si chiama ancora `pg_raspberry` mentre il gioco è *Hotfix Friday*. Vuoi rinominarlo (anche su GitHub) e rinominare gli eseguibili esportati?
    - Per ora: invariato.
