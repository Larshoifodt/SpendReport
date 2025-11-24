# Data Model and DAX – Overview

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
