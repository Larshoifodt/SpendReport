# Report Structure – Pages and Navigation

This document gives an overview of the structure, navigation, and functional flow of the SpendReport solution.  
For detailed technical examples (Power Query, DAX, Deneb SVG, bridge logic), see the `/examples` folder.

## 1. Development Flow (Queries → Data Model → DAX → Visuals)
The report follows a clean and maintainable development sequence:

### **1.1 Power Query (M) – Data Ingestion**
All raw transformations take place in Power Query.  
Data is sourced from Teams/SharePoint, enabling secure storage and consistent monthly refreshes.

Key activities:
- Cleaning contract exports and invoice data  
- Standardizing naming conventions  
- Preparing keys for matching (e.g., OrganizationNumber)  
- Handling schema drift and inconsistent exports  
- Building bridge tables for many-to-many relationships  

**Examples:**  
- `/examples/powerquery-bridge-contracts-erp.md`  
- `/examples/powerquery-invoice-ingestion.md`

---

### **1.2 Data Model**
The model is based on a star-schema-inspired structure:

- `Invoices` as the primary fact table  
- `Contracts`, `Organization`, `Accounts`, `Business Units`, `Projects` as dimension tables  
- Bridge tables to resolve many-to-many scenarios  

Key principles:
- Clear filter directionality  
- Helper tables for more stable relationships  
- Suffix-based contract keys to support chronological matching  

**Details:**  
See `/examples/data-model-and-dax.md`.

---

### **1.3 DAX Layer**
The DAX layer includes:
- Agreement matching logic  
- Compliance rules  
- Contract consumption  
- Spend bands  
- Field parameters  
- Deneb/SVG measures for tooltips and interactive visuals  

**DAX Dictionary:**  
See `/examples/Dax-Dictionary.md`.

---

### **1.4 Visuals**
The visuals are designed to support decision-making:
- Framework agreement coverage  
- Spend vs. contract value  
- Upcoming expiries  
- Flow/Sankey diagrams for tracing spend across accounts and units  
- Tooltip pages powered by Deneb (interactive SVGs)

**Deneb examples:**  
See `/examples/deneb-measures.md`.

---
## 2. Report Pages and Navigation
### **Agreements**
- Upcoming expiry monitoring  
- Spend by supplier (organization number)  
- Contract value comparison  
- Gantt-style view of agreements per supplier  

---

### **Flow**
- Complete spend flow breakdown  
- Selecting a transaction opens a Sankey view  
- Multiple account-level relationships traced  
- IDs and descriptions enriched from external sources  

---

### **Uncovered Purchases & Exceptions**
- All purchases not covered by agreements  
- Enrichment via PowerApps override system  
- Renders documented exceptions as “green” instead of “red”

---

### **Maintenance**
- Highlights new business units missing purchaser assignments  
- Supports ongoing governance and data quality work  

---

## 3. Tooltips (Deneb)
Two tooltip pages using Deneb/Vega handle:
- Transaction history mini-charts  
- Legal threshold detection  
- Compact insights without cluttering the main pages  

See `/examples/deneb-measures.md` for full SVG measure logic.

