# Spend Report – Avtaledekning & Analyse av Innkjøp (Power BI)
(Norsk versjon) [Read in English](README.md)

Spend Report er en Power BI-løsning som kobler kontraktsdata (rammeavtaler) med fakturadata fra ERP-systemet. Løsningen viser:

- hvor stor del av innkjøpene som faktisk skjer på avtale
- hvilke kjøp som faller utenfor avtaler
- når avtalte verdier og perioder overskrides
- hvilke avvik som er legitime og dokumenterte (unntak), og hvilke som krever oppfølging

Løsningen er utviklet for miljøer uten et fullstendig integrert innkjøpssystem — typisk organisasjoner som bruker et ERP for fakturahåndtering og et separat kontrakts- og avtaleoppfølgingssystem (KAV/CLM) for kontraktens livssyklus. Slike systemer kan integreres, men dette krever gjerne kostbare moduler og teknisk infrastruktur som universitets- og offentlig sektor sjelden har tilgjengelig.

Ved å kombinere SharePoint/Teams, Power BI, Power Query, DAX og Power Apps tilbyr denne løsningen et praktisk og rimelig alternativ.

## 1. Hva rapporten leverer

**For virksomheten**
- Dekningsgrad for rammeavtaler (andel av kjøp og kostnad)
- Oversikt over avtaler som nærmer seg utløp
- Identifikasjon av kjøp utenfor avtaler (røde) vs. aksepterte avvik (grønne)
- Forbruk mot avtaleverdi (potensiell overskridelse)
- Innsikt i hvordan kostnader flyter gjennom kontoer, kostnadssteder og enheter

**For tekniske brukere**
- Robust match mellom ERP og kontraktseksport ved bruk av organisasjonsnummer + datointervaller
- Bridge-tabeller som håndterer many-to-many-relasjoner
- Suffix-baserte kontraktsnøkler for å følge overlappende avtaler over tid
- Integrert Power App for å dokumentere unntak (manuelle overskrivelser)
- Egendefinerte SVG-tooltips (Deneb) for kompakte visuelle historikker

Mer om rapportens sider:
/docs/report-structure.md

--- 

## 2. Arkitekturoversikt
Flyten er:

**Teams / SharePoint → Power Query → Datamodell → DAX → Visualiseringer & Power Apps**

### 2.1 Dataimport (Power Query / M)

Alle råtransformasjoner gjøres i Power Query.
Løsningen fungerer både når:

- data lastes ned automatisk via APIer, og
- filer lastes opp manuelt måned for måned

Power Query håndterer:

- lasting av kontraktseksporter og faktura-eksporter
- standardisering av kolonner og navngivning
- skjemaendringer («schema drift»)
- bygging av bridge-tabell mellom ERP og kontraktsregister

Eksempler:

/examples/powerquery-bridge-contracts-erp.md
/examples/powerquery-invoice-ingestion.md

### 2.2 Datamodell (stjerne-skjemainspirert)

<img width="1131" height="726" alt="image" src="https://github.com/user-attachments/assets/50b9021f-6358-4eec-8b3b-163ebfd7784a" />

**Faktatabell:**
Invoices (ERP / Unit4)

**Dimensjoner:**

- Kontraktoversikt (fra Tendsign el.l.)
- Kostnadssted / ansvar – utledet fra enhetskoder
- Overskriv-liste – avvik dokumentert via Power Apps
- Beskrivelsesdimensjon for uklassifiserte kjøp
- To datodimensjoner – én for fakturadato, én for avtaleperiode

**Brotabell:**
Brukes for å forbigå mange-til-mange-relasjoner og sikre korrekt kontraktsmatching.

Full forklaring:
/docs/data-model-and-dax.md

--- 

## 3. Logikk for kontraktsmatching
I praksis bruker økonomi/innkjøp ikke kontrakts-ID når de konterer fakturaer.
Den eneste stabile fellesnøkkelen er som regel organisasjonsnummer.

Derfor brukes følgende for matching:

- organisasjonsnummer
- fakturadato
- gyldig datointervall på kontrakt
- suffix-basert nøkkel for å skille avtaler hos samme leverandør

Selv om dette ikke er en “perfekt” modellteknisk tilnærming, fungerer det svært godt i miljøer uten integrerte innkjøpssystemer.

### 3.1 Suffix-basert kontraktsnøkkel

Modellen lager en unik nøkkel per kontrakt, f.eks.:

OrgNr + Sekvens

Denne:
- skiller overlappende avtaler
- gjør det mulig å spore avtaler kronologisk
- brukes i fakturadata til å identifisere mest sannsynlig avtale

DAX i detalj:
/examples/Dax-Dictionary.md

--- 

## 4. Håndtering av flere samtidige avtaler & overskridelser

Når flere avtaler er gyldige for samme leverandør samtidig, klassifiserer løsningen dette ikke som et entydig avvik.

Modellen:

- viser en indikator for flere avtaler
- viser også separat indikator for overspend
- lar bruker forstå om overspend kan være begrunnet i flere parallelle avtaler

Tolkning:

- Kun overspend-ikon →
én avtale, verdi over kontrakt → bør følges opp

- Overspend + flere-avtaler-ikon →
mulig legitim overskridelse → flere avtaler aktive samtidig

Dette hindrer overrapportering av avvik.

--- 
