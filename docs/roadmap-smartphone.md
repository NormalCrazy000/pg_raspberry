# Roadmap smartphone: Android e multigiocatore su due dispositivi

Piano per portare Hotfix Friday su **Android** e aggiungere il **multigiocatore su due dispositivi** nella stessa rete.
Niente di questo è ancora implementato. Le scelte già fatte sul gioco sono in [architettura.md](architettura.md).

---

## Fase 1: Android

Godot 3.6 esporta per Android e il renderer GLES2 usato per il Raspberry Pi funziona su quasi tutti i telefoni:
il gioco non va riscritto. Touch, salvataggi (`user://`) e la tastiera a schermo del torneo funzionano già.

### Da decidere
- [ ] **Proporzioni dello schermo.** Il gioco è 800×480 (5:3), i telefoni sono più allungati (19,5:9, 20:9).
  - bande nere ai lati (nessun lavoro, è il comportamento attuale con `aspect=keep`);
  - oppure sfondo allargato a tutto lo schermo con il campo invariato (`aspect=expand` e HUD ancorato ai bordi).
- [ ] **Distribuzione.** Proposta: APK solo nelle Releases di GitHub, installabile a mano ("origini sconosciute"),
  coerente con la scelta di non pubblicare nei negozi. Il Play Store richiederebbe un account sviluppatore e il formato AAB.

### Da fare
- [ ] Ambiente di build: Android SDK configurato nell'editor di Godot (i template Android 3.6.3, Java e `adb` ci sono già).
- [ ] Chiave di firma per l'APK, conservata in un posto sicuro: senza la stessa chiave gli aggiornamenti non si installano sopra.
- [ ] Preset di esportazione Android: orientamento orizzontale bloccato, icona, nessun permesso.
- [ ] Tasto "indietro" di Android come Esc (pausa, torna indietro) invece di chiudere il gioco (`quit_on_go_back` spento).
- [ ] Nascondere sul telefono le opzioni che non servono: schermo intero e vsync.
- [ ] HUD fuori da notch e angoli arrotondati (area sicura dello schermo).
- [ ] Pulsanti abbastanza grandi per un dito su 6": in particolare la tastiera a schermo del torneo (oggi tasti 44×38 su 800×480).
- [ ] Build automatica su GitHub: esportazione Android con la chiave tra i segreti del repository,
  `hotfix-friday-android.apk` in ogni release.
- [ ] Prova su un telefono vero (installazione con `adb install`).

### Rischi
- Configurazione di SDK e firma, in locale e su GitHub: la parte con più tentativi ed errori.
- Tastiera a schermo e HUD vanno verificati su schermi veri, non solo negli screenshot.

---

## Fase 2: multigiocatore su due dispositivi (rete locale)

Due dispositivi sulla stessa Wi-Fi o sull'hotspot del telefono (Pi e telefono, due telefoni, PC e telefono).
Una sfida a 2 come quella sullo stesso dispositivo, ma ognuno tira dal suo schermo.

### Scelte di base
- **Solo rete locale, niente internet.** Nessun server da gestire, nessun account, nessun problema di NAT.
  La licenza resta **GPL-3.0**: l'AGPL serve solo se c'è un server (vedi [architettura.md](architettura.md#scelte-escluse)).
- **Ricerca della partita** sulla rete locale: l'host annuncia la partita con un pacchetto UDP broadcast
  ("partita Hotfix Friday di Anna") e l'altro dispositivo la vede in un elenco, senza scrivere indirizzi IP.
- **L'host decide tutto, l'ospite manda solo la mira.**
  - La fisica di Godot non dà lo stesso risultato su processori diversi (ARM e x86): due simulazioni separate divergerebbero.
  - L'host simula paperella, pioli, punti e poteri e manda posizioni ed eventi circa 20 volte al secondo (pochi byte).
  - L'ospite, nel suo turno, manda solo **l'angolo di tiro**; per il resto disegna quello che riceve.
  - Un ospite modificato non può barare sui punti. Il gioco è a turni: un piccolo ritardo di rete non si nota.

### Sicurezza
**Canale cifrato.** `NetworkedMultiplayerENet` con **DTLS** (il TLS di UDP): nessuno sulla stessa rete può leggere
o modificare il traffico. L'host genera al momento un certificato autofirmato con la classe `Crypto` di Godot.

**Abbinamento con codice**, come il Bluetooth:
- l'host mostra un **codice di 6 cifre**, l'ospite lo inserisce per entrare: un dispositivo qualsiasi della rete non può unirsi;
- dopo 3 codici sbagliati l'host blocca quel dispositivo per qualche secondo (forza bruta impraticabile);
- con 2 giocatori l'host non accetta altre connessioni (`refuse_new_network_connections`);
- **protezione da chi si mette in mezzo:** i due schermi mostrano un'impronta corta del certificato (es. 6 cifre)
  e i giocatori controllano che coincida. Alternativa: l'ospite riceve il certificato dell'host con un codice QR
  e lo usa come unico certificato fidato (`dtls_verify` e `set_dtls_certificate`).

**Messaggi ricevuti mai fidati**, anche con cifratura e codice:
- controllo di tipo, lunghezza e valori di ogni messaggio (es. angolo nel range del cannone, tiro solo nel proprio turno);
  i messaggi malformati si scartano senza bloccare il gioco;
- **mai decodificare oggetti dalla rete**: `allow_object_decoding` e `bytes2var` con oggetti restano disattivati
  (un messaggio potrebbe creare oggetti con script, cioè eseguire codice); solo dizionari e numeri;
- RPC solo dove servono, esplicite (`master` / `puppet`); l'ospite non può chiamare funzioni che cambiano la partita;
- controllo della versione del gioco all'inizio della connessione: versioni diverse non si collegano;
- limite di messaggi al secondo in arrivo, per non intasare l'host (soprattutto il Pi).

**Fuori da questa fase:**
- il gioco su internet (server ponte, account, passaggio ad AGPL, molta più superficie da proteggere): un progetto a sé;
- un host modificato può barare, perché decide lui: accettabile tra amici sulla stessa rete.

### Da fare
- [ ] **Prova tecnica, prima di tutto il resto:** DTLS con certificato autofirmato tra Pi e PC con Godot 3.6,
  per capire quale verifica del certificato è davvero possibile. Da qui dipende come si fa l'abbinamento sicuro
  (impronta a schermo, QR o solo codice).
- [ ] Separare in `scripts/game/game.gd` chi simula (host) da chi disegna (host e ospite).
- [ ] Protocollo dei messaggi: stato del campo all'inizio, posizioni delle paperelle, eventi (piolo colpito, punti,
  poteri, cambio turno, fine partita), angolo di tiro dell'ospite.
- [ ] Schermate: "Ospita partita" (codice, attesa), "Entra in partita" (elenco della rete locale, inserimento del codice).
- [ ] Casi di errore: disconnessione a metà partita, Wi-Fi che cade, host che chiude il gioco.
- [ ] Test automatici del protocollo (messaggi malformati, fuori turno, versione diversa) nello stile di `tools/test_bracket.gd`.
- [ ] Prova con due dispositivi veri: Pi e telefono, due telefoni.

### Rischi
- È il lavoro più grosso: più di Android e torneo messi insieme.
- La verifica del certificato in Godot 3.6 va provata prima di promettere la protezione completa da chi si mette in mezzo.
- Su reti pubbliche o aziendali il broadcast UDP e le connessioni tra dispositivi sono spesso bloccati:
  in quel caso serve l'hotspot del telefono.

---

## Ordine consigliato
1. Fase 1 (Android): utile da sola, e dà il secondo dispositivo per provare la fase 2.
2. Prova tecnica DTLS.
3. Fase 2 (multigiocatore in rete locale).
