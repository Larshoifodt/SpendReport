# DAX Dictionary

This document describes key DAX measures, calculated columns and field parameters in the model.

## AgreementFlag

| Field | Value |
|-------|-------|
| **Name** | AgreementFlag |
| **Type** | Calculated column |
| **Table** | Invoices |
| **Purpose** | Indicates whether a given invoice line is covered by an agreement or manually flagged. |
| **Logic** | Checks two lookup flags (contract match + override) and returns Yes/No. |
| **Notes** | Used as a base for spend banding per supplier/organization. |

**DAX:**
```DAX
AgreementFlag =
IF (
    Invoices[ContractLookupFlag] = "Yes"
        || Invoices[ManualOverrideFlag] = "Yes",
    "Yes",
    "No"
)
```

## ContractReferenceNumber

| Field | Value |
|-------|-------|
| **Name** | ContractReferenceNumber |
| **Type** | Calculated column |
| **Table** | Invoices |
| **Purpose** | Shows which contract reference (e.g. contract ID / P360 number) the invoice most likely relates to, if any. |
| **Logic** | Filters the Contracts table on a matching key and an invoice date within the contract period, then selects the latest valid contract and returns its reference number. |
| **Notes** | If no contract is found, returns "No match". Ambiguous cases (multiple valid contracts) are handled separately. |

**DAX:**
```DAX
ContractReferenceNumber =
VAR MatchTable =
    FILTER (
        Contracts,
        Contracts[Key_Contract] = Invoices[Key_Invoice]
            && Contracts[StartDate] <= Invoices[InvoiceDate]
            && Contracts[EndDate] >= Invoices[InvoiceDate]
    )
VAR LatestContract =
    MAXX (
        TOPN ( 1, MatchTable, Contracts[EndDate], DESC ),
        Contracts[ReferenceNumber]
    )
RETURN
IF (
    ISBLANK ( LatestContract ),
    "No match",
    LatestContract
)
```

## TotalAmountByOrganization

| Field | Value |
|-------|-------|
| **Name** | TotalAmountByOrganization |
| **Type** | Measure |
| **Table** | Invoices |
| **Purpose** | Calculates total spend per organization number, regardless of other filters in the table context. |
| **Logic** | Uses CALCULATE + ALLEXCEPT to sum Amount while keeping only OrganizationNumber as the grouping context. |
| **Notes** | Used as a base measure for spend banding per supplier / organization. |

**DAX:**
```DAX
TotalAmountByOrganization =
CALCULATE (
    SUM ( Invoices[Amount] ),
    ALLEXCEPT ( Invoices, Invoices[OrganizationNumber] )
)
```

## AmountBandByOrganization

| Field | Value |
|-------|-------|
| **Name** | AmountBandByOrganization |
| **Type** | Calculated column |
| **Table** | Invoices |
| **Purpose** | Categorizes total spend per organization into predefined amount bands for easier reporting and grouping. |
| **Logic** | Uses the SWITCH(TRUE()) pattern on TotalAmountByOrganization to assign a textual band label. |
| **Notes** | Thresholds can be adjusted according to procurement policy and local regulations. |

**DAX:**
```DAX
AmountBandByOrganization =
SWITCH (
    TRUE (),
    Invoices[TotalAmountByOrganization] < 80000, "A: < 80k",
    Invoices[TotalAmountByOrganization] >= 80000
        && Invoices[TotalAmountByOrganization] < 100000, "B: 80k–100k",
    Invoices[TotalAmountByOrganization] >= 100000
        && Invoices[TotalAmountByOrganization] < 500000, "C: 100k–500k",
    Invoices[TotalAmountByOrganization] >= 500000
        && Invoices[TotalAmountByOrganization] < 1400000, "D: 500k–1.4M",
    Invoices[TotalAmountByOrganization] >= 1400000
        && Invoices[TotalAmountByOrganization] < 8000000, "E: 1.4M–8M",
    Invoices[TotalAmountByOrganization] >= 8000000, "F: > 8M",
    "Unknown"
)
```

## FlowDimensionSelector

| Field | Value |
|-------|-------|
| **Name** | FlowDimensionSelector |
| **Type** | Field parameter |
| **Table** | (Model-level) |
| **Purpose** | Allows the user to switch the dimension used in supplier flow visuals (e.g. account vs business unit). |
| **Logic** | Uses a field parameter definition to toggle between different columns in the same visual. |
| **Notes** | Used on the “Supplier Flow” page to drive Deneb/Sankey and other flow-style visuals. |

**DAX:**
```DAX
FlowDimensionSelector =
{
    ( "Account", NAMEOF ( Invoices[AccountLabel] ), 1 ),
    ( "Business Unit", NAMEOF ( Invoices[BusinessUnitLabel] ), 2 )
}
```

## Deneb SVG Tooltip Measure

| Field | Value |
|-------|-------|
| **Name** | Deneb SVG Tooltip Measure |
| **Type** | Measure |
| **Table** | Invoices |
| **Purpose** | Generates an SVG bar chart used in a Deneb tooltip, showing the transaction history for a given supplier over the last 3 years. |
| **Logic** | Filters invoices for the selected organization, normalizes dates and amounts to X/Y coordinates, colors bars based on a legal threshold, adds grid lines and a dashed threshold line, and returns the result as an inline SVG image.|
| **Notes** | Transactions above the threshold are highlighted (e.g. yellow) to indicate they fall under specific legal rules; others are shown in a base color (e.g. green). |

**DAX:**
```DAX
YourBarChartName =
VAR StartDate =
    DATE ( YEAR ( TODAY () ) - 3, 1, 1 )
VAR EndDate =
    TODAY ()

// Current organization number from filter context
VAR OrganizationNumber =
    SELECTEDVALUE ( Invoices[OrganizationNumber] )

// Filter invoices for this organization and period
VAR FilteredTable =
    FILTER (
        Invoices,
        Invoices[OrganizationNumber] = OrganizationNumber
            && Invoices[InvoiceDate] >= StartDate
            && Invoices[InvoiceDate] <= EndDate
    )

// Threshold for highlighting (e.g. subject to specific regulations)
VAR ThresholdLow = 125000

// Y-axis min/max based on Amount
VAR YMinValue = 0
VAR YMaxValue = MAXX ( FilteredTable, Invoices[Amount] )
VAR NormalizedYMax =
    IF ( YMaxValue = YMinValue, YMinValue + 1, YMaxValue )

// Compute X/Y positions and color for each bar
VAR BarTable =
    ADDCOLUMNS (
        FilteredTable,
        "X", INT ( 300 * DIVIDE ( Invoices[InvoiceDate] - StartDate, EndDate - StartDate ) ),
        "Y", INT ( 100 * DIVIDE ( Invoices[Amount] - YMinValue, NormalizedYMax - YMinValue ) ),
        "Color",
            SWITCH (
                TRUE (),
                Invoices[Amount] < ThresholdLow, "#156565",   // base color
                Invoices[Amount] >= ThresholdLow, "#F5EC5F"  // highlight color
            )
    )

// Render bars
VAR Bars =
    CONCATENATEX (
        BarTable,
        "<rect x='" & [X]
            & "' y='" & 100 - [Y]
            & "' width='10' height='" & [Y]
            & "' fill='" & [Color] & "' />",
        " "
    )

// Static Y grid lines
VAR GridYLines =
    "<line x1='0' y1='100' x2='300' y2='100' stroke='grey' stroke-width='1' />
     <line x1='0' y1='50' x2='300' y2='50' stroke='grey' stroke-width='1' />
     <line x1='0' y1='0' x2='300' y2='0' stroke='grey' stroke-width='1' />"

// Static X grid lines with relative year labels
VAR GridXLines =
    "<line x1='0' y1='0' x2='0' y2='100' stroke='grey' stroke-width='1' />
     <line x1='100' y1='0' x2='100' y2='100' stroke='grey' stroke-width='1' />
     <line x1='200' y1='0' x2='200' y2='100' stroke='grey' stroke-width='1' />
     <line x1='300' y1='0' x2='300' y2='100' stroke='grey' stroke-width='1' />
     <text x='0' y='115' font-size='16' fill='grey'>-3</text>
     <text x='100' y='115' font-size='16' fill='grey'>-2</text>
     <text x='200' y='115' font-size='16' fill='grey'>-1</text>
     <text x='300' y='115' font-size='16' fill='grey'>0</text>"

// Threshold line (dashed) at ThresholdLow
VAR ThresholdLowY =
    INT ( 100 * DIVIDE ( ThresholdLow - YMinValue, NormalizedYMax - YMinValue ) )

VAR ThresholdLines =
    "<line x1='0' y1='" & 100 - ThresholdLowY
        & "' x2='300' y2='" & 100 - ThresholdLowY
        & "' stroke='grey' stroke-width='2' stroke-dasharray='5,5' />
     <text x='305' y='" & 100 - ThresholdLowY + 2
        & "' font-size='12' fill='grey'>125K</text>"

// Combine everything into SVG
RETURN
    "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' x='0px' y='0px' viewBox='0 0 300 120' style='background:#BBE4E3;'>"
        & GridYLines
        & GridXLines
        & Bars
        & ThresholdLines
        & "</svg>"
```
