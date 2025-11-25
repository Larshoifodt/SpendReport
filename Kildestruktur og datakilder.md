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
