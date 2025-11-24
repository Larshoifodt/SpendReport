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
## 5. Relationship Principles

- Fact → dimensions: single direction  
- Many-to-many resolved with bridge tables  
- No bidirectional filtering except where safe  
- Calculated columns used only where necessary  
- Measures preferred for aggregation logic

---

## 6. Visual-Supporting DAX

Special measures support:
- Sankey (flow) diagrams  
- Tooltip pages  
- Threshold detection (e.g. >125k legal threshold)  
- Mini-bar-chart SVGs  

See:  
➡ `/examples/deneb-measures.md`












## Contract matching logic (Invoices ↔ Contracts)
In many organizations, invoices and contract data are stored in completely separate systems, 
and suppliers or finance personnel do not reference contract IDs when registering or approving invoices. 
This means that organization number (or supplier identifier) is often the only reliable linkage between the ERP and the contract registry.

Because of this, the model uses a fallback matching strategy based on:
- Organization number
- Invoice date
- Contract validity period (StartDate–EndDate)

This approach may look “non-ideal” from a pure data modeling perspective, 
but in reality it is a highly practical and effective workaround for teams 
that do not have a fully integrated procurement–invoice system (which often requires expensive enterprise software).

How the matching works
Each invoice row attempts to retrieve the most likely active contract:

MatchedContractKey =
VAR MatchTable =
    TOPN (
        1,
        FILTER (
            Contracts,
            Contracts[OrganizationNumber] = Invoices[OrganizationNumber]
                && Contracts[StartDate] <= Invoices[InvoiceDate]
                && Contracts[EndDate] >= Invoices[InvoiceDate]
        ),
        Contracts[EndDate],
        DESC
    )
RETURN
IF (
    ISEMPTY ( MatchTable ),
    "No match",
    MAXX ( MatchTable, Contracts[Key_Contract] )
)

This guarantees that:
- If one valid contract matches → we attach its key
- If none match → we mark it as “No match”
- If several match → we flag this as an ambiguous match (example below)

Handling multiple valid contracts
In cases where more than one contract is valid for the same supplier in the same period, 
the model intentionally does not guess. Instead, it flags the invoice row:

HasMultipleContractMatches =
VAR MatchCount =
    CALCULATE (
        DISTINCTCOUNT ( Contracts[ContractId] ),
        FILTER (
            Contracts,
            Contracts[OrganizationNumber] = Invoices[OrganizationNumber]
                && Contracts[StartDate] <= Invoices[InvoiceDate]
                && Contracts[EndDate] >= Invoices[InvoiceDate]
        )
    )

RETURN
IF ( MatchCount > 1, 1, 0 )

In the report, this displays as a small icon or badge so users instantly understand:
- There is a valid contract
- But the system cannot determine which one without additional context
- Overspend or deviation might have a simple explanation (multiple contracts active)

Why this approach is valuable

Even though the logic relies on organization number and date intervals rather than strict contract IDs, 
it is extremely effective in environments where:

Finance staff do not use contract IDs when coding invoices
- Punch-out systems or ERP integrations do not return contract references
- Contract and invoice systems are not fully integrated
- The organization does not have (or cannot justify) an expensive end-to-end procurement suite

In these scenarios, this matching strategy provides:
- A reliable way to identify likely contract coverage
- Good traceability back to individual agreements
- A meaningful method for analyzing compliance and deviations
- A practical workaround that delivers value long before full integration is possible

## Data Model
- Star-schema-inspired model with:
  - Fact table(s) for invoices / purchases
  - Dimension tables for contracts, organization numbers, accounts, cost centers, business units, and projects
- Relationship design includes:
  - Handling of many-to-many relationships through bridge or helper tables
  - Clear directionality to avoid ambiguous filter paths

## Key Calculated Columns
- Columns for:
  - Contract validity flags (within period / outside period)
  - Agreement coverage classification (covered / not covered / over limit)
  - Mapping between purchases and contracts (e.g., based on organization number or other keys)

## Key Measures
- Contract consumption (used vs. contract value)
- Agreement coverage percentage by spend
- Number of purchases and amount outside agreement
- Flags and counts for:
  - Red (non-compliant) vs. green (overridden/accepted) purchases
- Measures for supporting Sankey and Deneb visuals
