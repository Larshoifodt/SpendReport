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
