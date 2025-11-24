# Power Apps Integration and Override Flow

## Purpose

The Power App is used to handle justified exceptions when purchases are made outside of existing agreements.

## Process Overview
1. A purchase appears as "not covered" or "out of contract frame" in the report.
2. The user opens the embedded Power App from the report.
3. The user provides:
   - Reason for the purchase
   - Classification / category
   - Any additional notes
4. The entry is stored in a separate list or data source.
5. On refresh, the report:
   - Matches purchases against this override list
   - Reclassifies relevant purchases from "red" (non-compliant) to "green" (accepted exception).

## Effect in the Report
- Visuals and KPIs are updated to distinguish between:
  - Truly non-compliant purchases
  - Documented, accepted exceptions
- This supports a more fair and realistic view of contract compliance.
