# Data Model and DAX Logic

This document explains the core analytical logic behind the SpendReport solution, including relationship design, contract matching, and important measures.  
For detailed DAX examples, see `/examples/Dax-Dictionary.md`.

## 1. Model Overview

The model is built around a star-schema layout:

<img width="1131" height="726" alt="image" src="https://github.com/user-attachments/assets/50b9021f-6358-4eec-8b3b-163ebfd7784a" />


- **Fact table:** `Invoices` (Unit4)
- **Dimensions:** The model contains several supporting dimension tables (Tendsign), including the Contracts dimension, a Responsibility/Cost Center dimension constructed from Business Unit codes, an Override (exception) dimension maintained through Power Apps, a Descriptions dimension used to enrich uncovered purchases, and dual Date dimensions— one aligned with invoice posting dates and another aligned with contract validity periods.
- **Bridge tables:** used to resolve many-to-many relationships and support stable contract matching

Data is sourced from SharePoint folders using Power Query, which also handles schema drift and data consistency.

---

## 2. Contract Matching Logic (ERP ↔ Contract Register)

In many organizations, contract systems and ERP systems are not integrated.  
Suppliers and accounting staff do not reference contract IDs when coding invoices.  
Therefore, **OrganizationNumber** becomes the most reliable matching key.

Matching uses:
- Organization number  
- Invoice date  
- Contract date validity window  
- Suffix-based keys for chronological differentiation  

This appears “non-ideal” from a pure modeling standpoint, but is a **very effective workaround** for organizations without integrated procurement systems.

Full logic explanation:  
See `/examples/Dax-Dictionary.md#contractreferencenumber`.

### 2.1 Suffix-Based Contract Key Logic

Because several contracts for the same supplier may overlap, the model introduces a suffix-based contract key.

This makes it possible to:
- Uniquely identify each contract instance
- Chronologically rank overlapping contracts
- Trace which contract most likely applies to a given purchase
- Avoid ambiguous matches when date ranges overlap

The suffix key is created in the **Contracts** dimension and used again in **Invoices** to determine the most likely matching agreement.

Full implementation is documented here:
/examples/Dax-Dictionary.md#contractreferencenumber

---
## 3. Handling Multiple Contract Matches

If multiple contracts are valid for the same supplier in the same time period, the model does not simply treat this as a clear deviation. Instead, it:
- Flags the invoice row with a separate “multiple contracts” indicator, in addition to any “overspend” warning
- Avoids making a blind guess about which contract the invoice belongs to
- Signals to the user that the apparent overspend may be explained by several parallel agreements

In practice this means:
- One overspend icon only → there is a single contract and spend is above the agreed value, and the case should be reviewed.
- Overspend icon + “multiple contracts” icon → the spend is above one contract’s value, but there are several active contracts for the supplier in that period, so the overspend may be legitimate.

This approach may look a bit old-fashioned compared to fully integrated systems, but in environments without a complete end-to-end procurement platform it is a pragmatic and reliable way to avoid over-reporting deviations while still highlighting the cases that truly need attention.

This approach may look a bit old-fashioned compared to fully integrated systems, but in environments without a complete end-to-end procurement platform it is a pragmatic and reliable way to avoid over-reporting deviations while still highlighting the cases that truly need attention.

<img width="311" height="84" alt="image" src="https://github.com/user-attachments/assets/757f7960-953d-44fa-bf61-98d36e1bd796" />
VS.
<img width="312" height="93" alt="image" src="https://github.com/user-attachments/assets/b4070bb3-3b6b-4c76-9b85-000f38c24252" />

---
## 4. Key DAX Elements

- Agreement classification  
- Contract consumption  
- Spend totals by organization  
- Amount banding  
- Exceptions and overrides  
- Field parameters for dynamic visuals  
- Deneb / SVG measures for tooltips  

Main DAX elements are documented here:  
➡ `/examples/Dax-Dictionary.md`

---

## 5. Programmed Visuals

- Sankey (flow) diagram - free version downloaded from "Visiocharts" 
- Mini BarChart SVG Tooltip ( See:  ➡ `/examples/deneb-measures.md` for code)
--- 
## Key Measures
1. Agreement coverage percentage by spend
2. Number/Value/% of purchases and amount outside agreement
3. Contract consumption (used vs. contract value)
- Flags and counts for:
  - Red (non-compliant) vs. green (overridden/accepted/contract match) purchases
- Measures for supporting Sankey and Deneb visuals
