# Spend Report – Framework Agreement Compliance & Spend Analysis (Power BI)

The Spend Report Project is a Power BI solution that connects contract data (framework agreements) with ERP invoice data to show:

- how much of the organization’s spend is actually covered by agreements  
- where purchases fall outside contractual scope  
- when contract values and periods are exceeded  
- which exceptions are **legitimate** and documented, and which need follow-up  

The solution is built for environments without a fully integrated procurement suite — where organizations often rely on separate systems, such as an ERP for financial processing and a contract-management platform (KAV/CLM) for agreement lifecycle tracking. While these systems can be integrated, doing so typically requires high-priced enterprise modules and infrastructure that most universities and public-sector institutions do not have access to. By combining SharePoint/Teams, Power BI, Power Query, DAX, and Power Apps, this solution bridges that gap in a practical and affordable way.

---

## 1. What the Report Delivers

**Business perspective**

- Agreement coverage by spend and number of purchases  
- Monitoring of upcoming contract expiries  
- Identification of purchases outside agreements (red) vs. accepted exceptions (green)  
- Visibility into contract consumption vs. contract value (potential overrun)  
- Traceability of spend across accounts, cost centers, projects and business units  

**Technical perspective**

- Robust matching logic between ERP and contract exports using OrganizationNumber + date ranges  
- Many-to-many relationship handling via bridge tables  
- Suffix-based contract keys to track overlapping agreements over time  
- Embedded Power App for documenting and overriding justified exceptions  
- Custom SVG tooltips (Deneb) for compact transaction history visuals  

For a deeper overview of pages and navigation, see:  
`/docs/report-structure.md`

---

## 2. Architecture Overview

The solution follows a clear flow:

**Teams / SharePoint → Power Query → Data Model → DAX → Visuals & Power Apps**

### 2.1 Data Ingestion (Power Query / M)

All raw transformations happen in Power Query.  
Data is stored in Teams/SharePoint, which means it works both when:

- data is pushed automatically via APIs, **or**  
- files are dropped manually on a monthly basis  

Key automatic tasks in the queries:

- Load contract exports and invoice exports from SharePoint folders  
- Standardize schema and naming  
- Handle schema drift and “messy” Excel exports  
- Build a **bridge table** between contract register and ERP, typically on `OrganizationNumber`  

Examples:

- Bridge contracts ↔ ERP:  
  `/examples/powerquery-bridge-contracts-erp.md`  
- Invoice ingestion pattern:  
  `/examples/powerquery-invoice-ingestion.md`

---

### 2.2 Data Model (Star-Schema Inspired)

<img width="1131" height="726" alt="image" src="https://github.com/user-attachments/assets/50b9021f-6358-4eec-8b3b-163ebfd7784a" />

- **Fact table:**  
  `Invoices` (ERP / Unit4 export)

- **Dimensions:**  
  - `Contracts` – framework agreements (from Tendsign or equivalent)  
  - Responsibility / Cost Center dimension – derived from Business Unit codes  
  - Override list – documented exceptions maintained via Power Apps  
  - Descriptions – to enrich uncovered purchases  
  - Dual Date dimensions – one aligned to invoice posting date, one to contract validity period  

- **Bridge tables:**  
  Used to resolve many-to-many relationships and ensure stable contract matching between ERP and contract data.

Full description:  
`/docs/data-model-and-dax.md`

---

## 3. Contract Matching Logic

In most real-world setups, **finance staff and suppliers do not use contract IDs on invoices**.  
Instead, the only shared, stable key is usually **OrganizationNumber**.

Because of this, the matching logic is based on:

- OrganizationNumber  
- Invoice date  
- Contract validity period (`StartDate`–`EndDate`)  
- A suffix-based contract key to differentiate multiple agreements for the same supplier  

This may look “non-ideal” from a purist data modeling point of view, but in organizations without integrated procurement systems it is a **practical, effective workaround**.

### 3.1 Suffix-Based Contract Key

To track multiple agreements for the same supplier, the model uses a composite key:

- Built in the `Contracts` dimension (e.g. `OrganizationNumber` + sequence ID)  
- Re-used in `Invoices` to store the most likely contract match  
- Enables traceability back to the exact agreement used for matching  

Key DAX definitions:

- `Key_Contract`  
- `MatchedContractKey`  
- `ContractReferenceNumber`  

See:  
`/examples/Dax-Dictionary.md#key-contract`  
`/examples/Dax-Dictionary.md#matchedcontractkey`  
`/examples/Dax-Dictionary.md#contractreferencenumber`

---

## 4. Handling Multiple Contracts & Overspend

Sometimes, **several contracts** are valid for the same supplier in the same period.  
The model purposely **does not guess** in these cases.

Instead, it:

- Flags the invoice with a **“multiple contracts”** indicator  
- Keeps any **“overspend”** warning separate  
- Signals that the apparent deviation may have a legitimate explanation (parallel agreements)

In practice:

- **Only overspend icon →**  
  Single contract, spend above agreed value → should be reviewed.

- **Overspend icon + multiple-contract icon →**  
  Spend above one contract’s value, but several active contracts for that supplier in the same period → overspend may be legitimate.

This avoids over-reporting deviations while still highlighting the cases that actually require attention.

---

## 5. Power Apps Integration – Override Logic

<img width="1364" height="636" alt="image" src="https://github.com/user-attachments/assets/ee73aa72-ac18-4f9c-a2b2-d0c779e3bd40" />

The report includes an embedded Power App that lets users **document justified exceptions** when a purchase is outside any framework agreement.

### 5.1 What the App Does

When a purchase is marked as “not covered”:

1. The user opens the embedded Power App from the report.  
2. They register:
   - reason / category  
   - notes  
   - start and stop date  
   - responsible purchaser  
3. The app writes an entry to an override list (SharePoint / Teams list or Dataverse).  
4. On the next refresh, Power BI:
   - matches the override back to the supplier (via OrganizationNumber)  
   - reclassifies the purchase from **red → green**  
   - updates KPIs and visuals  

This ensures that **legitimate, documented exceptions** do not show up as pure non-compliance.

### 5.2 Preventing Duplicate Overrides

The override list is keyed by `OrganizationNumber` (one supplier → one override record).

To protect key integrity, the Power App:

- checks if an override already exists for that supplier  
- updates the existing record if found  
- otherwise creates a new one  

If a user tries to create a second entry for the same supplier, a popup warns them and prevents accidental duplication.

Power Apps logic and screenshots:  
`/docs/powerapps-override-logic.md`

---

## 6. Custom Visuals (Deneb & Flow)

### 6.1 Deneb SVG Tooltip – Transaction History

The report uses a Deneb/Vega visual to render an **inline SVG mini bar chart** in a tooltip:

![gifspendgithub-ezgif com-video-to-gif-converter](https://github.com/user-attachments/assets/0a447db7-d1e4-4c3a-b75b-d911d9897379)

- Shows the last 3 years of transactions for the selected supplier  
- Bars above a legal procurement threshold (e.g. 100k/125k) are highlighted  
- A dashed reference line indicates the threshold  
- Helps users see whether a transaction is part of a broader high-value pattern  

DAX measure implementation:  
`/examples/deneb-measures.md`

### 6.2 Flow / Sankey Visual

- Uses a free Sankey/flow visual (from “Visiocharts”)  
- Traces each purchase across accounts, cost centers, projects and business units  
- Helps explain *where* and *how* spend flows through the chart of accounts

---

## 7. Report Pages (Functional Overview)

For day-to-day users, the key report pages are:

- **Agreements**  
  - Upcoming contract expiries  
  - Spend per supplier / organization number  
  - Contract value vs. actual spend  
  - Gantt-style contract overview  

- **Flow**  
  - End-to-end spend flow  
  - Transaction-level drill-through to Sankey  
  - Multiple account levels and business units  

- **Uncovered Purchases & Exceptions**  
  - All purchases not covered by agreements  
  - Exception handling via the Power App (red → green)  
  - Documentation of legitimate deviations  

- **Maintenance**  
  - New business units without assigned purchasers  
  - Data quality and governance support  

Full structure:  
`/docs/report-structure.md`

---

## 8. Repository Structure

A typical structure for this project:

```text
.
├─ README.md
├─ /docs
│  ├─ data-model-and-dax.md
│  ├─ powerapps-override-logic.md
│  └─ report-structure.md
└─ /examples
   ├─ Dax-Dictionary.md
   ├─ deneb-measures.md
   ├─ powerquery-bridge-contracts-erp.md
   └─ powerquery-invoice-ingestion.md

---
## 9. Scope, Assumptions and Limitations

- Designed for organizations without full procurement–ERP integration
- Uses OrganizationNumber as the primary cross-system key (can be adapted if another key is better)
- Assumes contracts and invoices are available as exports to Teams/SharePoint
- Requires aligned permissions for:
    - Power BI dataset
    - SharePoint/Teams lists
    - Power Apps environment

Despite these constraints, the solution offers:
- Reliable contract coverage analysis
- Practical compliance monitoring
- A realistic view of deviations vs. accepted exceptions
- A foundation that can later be extended with APIs or more tightly integrated systems
