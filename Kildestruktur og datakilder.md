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
| Override (Kollektiv hukommelse) | MS List (Kollektiv hukommelse) | (Fane) Teams Spend 25 / Område | Kontinuerlig via Power App eller direkte via MS List | 
| Leverandørbeskrivelser | MS List (Beskrivelser)  | (Fane) Teams Spend 25 / Område | Kontinuerlig via Power App eller direkte via MS List |
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

En typisk Teams-mappestruktur:

```
/Datagrunnlag
    ├─ ERP/
    │    └─ InvoiceExport.xlsx
    ├─ Kontrakter/
    │    └─ ContractExport.xlsx
    ├─ Innkjoper/
    │    └─ Innkjoper.xlsx
    ├─ KollektivHukommelse/   (MS Lists – håndteres automatisk)
    └─ Beskrivelser/          (MS Lists – håndteres automatisk)
```
Alle queries er bygget slik at de kun refererer mappen, ikke filnavnet.
Så lenge en fil erstattes i samme mappe, fortsetter modellen å fungere uten manuelle endringer.

--- 
## 3. Lasting og oppdatering i Power BI / Fabric

### 3.1 Automatiske oppdateringer

Datasettene er satt til å oppdatere daglig kl. 08:00 i Fabric.
Dette kan justeres etter behov.

### 3.2 Manuell oppdatering
Hvis du trenger umiddelbar oppdatering:

- gå til datasetet i Fabric, LENKE! 
- trykk “Oppdater nå”.

Dette brukes hvis:
- nye unntak er lagt inn i MS Lists,
- man har lastet inn nye ERP- eller kontraktsfiler,
- man tester endringer eller feilsøker.

### 3.3 Begrensninger pga. lisens

Prosjektet kjører på en lisens som:
- ikke støtter hendelsesbasert refresh,
- ikke oppdaterer automatisk når filer endres.

Derfor er daglig oppdatering + manuell refresh den rette løsningen.

--- 
## 4. Datakvalitet og rutiner

For stabil drift anbefales følgende rutiner:

### 4.1 Månedlig

- Last ned og erstatt ERP-filen.
- Last ned og erstatt kontraktsfilen.
- Sjekk om nye budenhetsnumre finnes i ERP-data → oppdater Innkjøper-filen.

### 4.2 Løpende

- Registrer unntak via Power App når et kjøp står som rødt.
- Legg inn nye leverandørbeskrivelser i MS Lists ved behov.

### 4.3 Etter behov
-Manuell Refresh i Fabric ved oppdateringer i lister eller filer.

--- 
## 5. Oppsummering

Løsningen er bygget for å fungere i miljøer uten en fullintegrert innkjøpsplattform.
Derfor ligger all lagring i:

- Teams / SharePoint (filer + MS Lists)
- Power BI / Fabric (modell, refresh, visualiseringer)
- Power Apps (unntaksbehandling)

Når kildene vedlikeholdes etter rutinene ovenfor, leverer rapporten:

- stabile oppdateringer
- korrekt klassifisering
- gode analyser av avtaledekning
- ingen schema drift-problemer
- korrekt innkjøperfordeling

--- 
