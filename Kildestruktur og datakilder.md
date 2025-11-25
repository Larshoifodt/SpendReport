# Kildestruktur og datakilder

## Kildestruktur og Datakilder

Denne oversikten beskriver hvordan datakildene i SpendReport-løsningen er organisert, 
vedlikeholdes og lastes inn i Power BI-modellen. Dokumentet er laget for analytikere, 
innkjøpere og forvaltere som skal forstå hvordan rapporten fungerer i praksis, samt hvilke rutiner som kreves for stabil drift.

---
## 1. Hovedkilder i løsningen
Løsningen bygger på fem sentrale kilder som alle ligger i et felles Teams-område (SharePoint-bibliotek). Disse blir automatisk hentet av Power BI gjennom planlagte oppdateringer.


| Kategori | Kilde | Lokasjon | Oppdatering | 
|----------|-----------|-----------|-----------|
| ERP (Unit4) | Fakturaeksport | Teams → DATAGRUNNLAG → UNIT4 | Månedlig (manuell opplasting, erstatt eksisterende fil) | 
| Avtaler (Tendsign) | Tendsign-eksport  | Teams → DATAGRUNNLAG → Tendsign | Månedlig (erstatt eksisterende fil) |
| Override (Kollektiv hukommelse) | MS List (Kollektiv hukommelse) | (Fane) Teams Spend 25 / Sharepoint-område | Kontinuerlig via Power App eller direkte via MS List | 
| Leverandørbeskrivelser | MS List (Beskrivelser)  | (Fane) Teams Spend 25 / Sharepoint-område | Kontinuerlig via Power App eller direkte via MS List |
| Innkjøper/Ansvarsområder | Excel-fil “INNKJOPER.xlsx”  | Teams → DATAGRUNNLAG | Ved behov (sjekk vedlikeholdsfane i rapport - antall nye budenheter >0?) |

## 2. Rutiner for hver kilde

### 1.1 ERP-data (Unit4 / økonomisystemet)
- Månedlig uttrekk fra ERP-systemet.
- Filen erstattes i samme mappe hver måned (ikke last opp ny fil → unngå schema drift).
- Inneholder alle bokførte fakturalinjer.
- Brukes som faktatabellen Invoices i datamodellen.

### 1.2 Avtaledata (Tendsign / KAV-eksport)
- Månedlig uttrekk av rammeavtaler.
- Også her skal filen overskrive den forrige for å unngå kolonnesvingninger.
- Modellens kontraktsdimensjon bygges fra denne kilden.
- Et eget bridge-query kobler kontrakter mot ERP-data via organisasjonsnummer.

### 1.3 Kollektiv Hukommelse (MS Lists)
En SharePoint / Teams-liste som brukes til å registrere:

- dokumenterte unntak,
- årsakskoder,
- periode for "override" (start/stopp),
- innkjøper,
- beskrivelse.

Når en bruker registrerer et unntak via Power App-en:
- blir posten skrevet hit,
- modellen klassifiserer kjøpet fra rødt → grønt ved neste refresh.

### 1.4 Beskrivelser (MS Lists)

En enkel liste for å lagre:
- fritekstforklaringer,
- leverandørbeskrivelser,
- ekstra kontekst som ikke eksisterer i ERP-dataene.

Denne informasjonen kobles inn via organisasjonsnummer og vises i tabeller og tooltips.

### 1.5 Innkjøper-fil (Teams → DATAGRUNNLAG-mappen)
En Excel-fil som kobler 4-sifret budenhetsnummer til:

- ansvarlig innkjøper,
- organisasjonstilgang,
- eventuelle grupperinger.

Når et nytt budenhetsnummer opptrer i ERP-dataene:
1. brukeren slår det opp i Unit4,
2. finner tilhørende enhet,
3. legger det inn i denne filen.

Dette sikrer korrekt filtrering og fordeling i rapporten.

--- 
## 2. Mappe- og filstruktur

Følgende kilder må vedlikeholdes. 


```
Teams-mappestruktur:

/Datagrunnlag
    ├─ Unit4/
    │    └─ Spend-Export 202201-202502.xlsx
    ├─ Tendsign/
    │    └─ Tendsign.xlsx
    └─ Innkjøper/
         └─ Innkjoper.xlsx

Teams / Sharepoint-område:

KollektivHukommelse/   (MS Lists – håndteres via power app)
Beskrivelser/          (MS Lists – håndteres via power app)

```
Queries er bygget slik at de refererer filnavnet og arkfanen i excel, ikke kun mappen. Det er derfor lurt å oppdatere
innholdet fremfor å erstatte filen. Dette kan imidlertid endres i M-koden i power query. 

--- 
## 3. Lasting og oppdatering i Power BI / Fabric

### 3.1 Automatiske oppdateringer

Datasettene er satt til å oppdatere daglig kl. 08:00 i [Fabric](https://app.powerbi.com/groups/b73bdcb0-32f4-407a-b6bf-de3dcecbbd29/lineage?tenant=bc758dd0-ab53-4372-9a7c-e98a9620862c&experience=power-bi).
Dette kan justeres etter behov.

### 3.2 Manuell oppdatering
Hvis man trenger umiddelbar oppdatering:

- gå til datasetets semantiske modell i [Fabric](https://app.powerbi.com/groups/b73bdcb0-32f4-407a-b6bf-de3dcecbbd29/lineage?tenant=bc758dd0-ab53-4372-9a7c-e98a9620862c&experience=power-bi).
- trykk “Oppdater nå”.

Dette kan brukes hvis man ikke vil vente til automatisk oppdatering. 

### 3.3 Begrensninger pga. lisens

Prosjektet kjører på en lisens som:
- ikke støtter hendelsesbasert refresh,
- ikke oppdaterer automatisk når filer endres.

Derfor er daglig oppdatering + manuell refresh eneste løsning.

--- 
## 4. Datakvalitet og rutiner

For stabil drift anbefales følgende rutiner:

### 4.1 Månedlig

- Last ned de 2 siste månedene med ERP-data når regnskapet er klart.
- Nedlastingen gjøres fra Unit4  → SPEND-EKSPORT. Det kan være hensiktsmessig å hente ut 2 måneder med data. Forrige måned - og måneden før det (i tilfelle det er gjort korregeringer siden sist).
- <img width="1965" height="417" alt="image" src="https://github.com/user-attachments/assets/744638dc-05f3-47aa-a821-5b4689b7331f" />

- Åpne Excel-filen Spend-Export 202201-202502 (som ligger i Teams Spend 25. Filtrer på periode og slett siste måned (delete rows) og legg til de to nye månedene. Sørg for at filen er oppdatert og lagret. 
    - Dersom man endrer navn på filen eller arkfanen - må man endre M-koden i power Query - hvis ikke vil framtidige oppdaringeringer kræsje.         
    - Marker og bruk hurtigstastene ctrl + pil og "ctrl + Alt + Home" for raskere navigering. 

 (Kapasitetsmessig kan rapporten få inn årevis med fakturadata - legg inn antall år du ønsker - rundt 2 år kan være hensiktsmessig) 

- Etter oppdatering av rapport - gå inn på rapportens fane "Vedlikehold" - Sjekk om nye budenhetsnumre finnes i ERP-data → oppdater Innkjøper-filen. Samme prinsipp - ikke endre navn på fil, arkfane eller filens lokasjon.  

### 4.2 Løpende

- Registrer unntak via Power App når et kjøp står som rødt.
- Legg inn nye leverandørbeskrivelser i MS Lists ved behov. Fint sted for å lage huskelapp til oppfølging. 

### 4.3 Etter behov
- Manuell Refresh i Fabric ved oppdateringer for å se endringen.

### 4.3 Kræsj-rapport 
- Fabric gir gode kræsj-rapporter. I de fleste tilfeller er det feil i nøkkelvariabel i en av kildene, blank eller dublikat. Les feilmelding på oppdatering i fabric nøye - gir ofte god indikasjon på hva som har gått galt.
- Ved duplikater eller blanke felt i nøkkelvariabel for beskrivelse/kollektiv hukommelse. Gå inn i fanen i teams og slett raden.

**Eksempel på feilmelding på dublikat/blank rad i nøkkelvariabel:**
```
Datakildefeil:	Column '<oii>Organisasjonsnummer</oii>' in Table '<oii>Kollektiv_hukommelse</oii>' contains blank values and this is not allowed for columns on the one side of a many-to-one relationship or for columns that are used as the primary key of a table. (Organisasjonsnummer (16634)).
Klynge-URI:	WABI-NORTH-EUROPE-O-PRIMARY-redirect.analysis.windows.net
Aktivitets-ID:	f908d504-9fff-4080-af46-05f753c1ccaf
Forespørsels-ID:	815aea6c-c0e4-47bb-acaf-692ee65fe5df
Klokkeslett:	2025-10-20 00:30:01Z
Detaljer	
#	Type	Start	Slutt	Varighet	Status	Detaljer
1	Data	20.10.2025, 02:01:02	20.10.2025, 02:21:41	20 m 39 s	Mislyktes	(Vis)
2	Data	20.10.2025, 02:21:41	20.10.2025, 02:21:46	4s	Mislyktes	(Vis)
3	Data	20.10.2025, 02:22:46	20.10.2025, 02:22:51	5s	Mislyktes	(Vis)
4	Data	20.10.2025, 02:24:51	20.10.2025, 02:24:57	5s	Mislyktes	(Vis)
5	Data	20.10.2025, 02:29:57	20.10.2025, 02:30:01	4s	Mislyktes	(Vis)
```

--- 
## 5. Oppsummering

Løsningen er bygget for å fungere i miljøer uten en fullintegrert innkjøpsplattform.
Derfor ligger all lagring i:

- Teams / SharePoint (filer + MS Lists)
- Power BI / Fabric (modell, refresh, visualiseringer)
- Power Apps (unntaksbehandling)

--- 
