# Report Structure – Pages and Navigation

## Home (Agreement Coverage)
- Displays overall agreement coverage by spend
- Historical agreement coverage over time
- Parameter to switch between business unit, project, and purchaser
- Shared filters (8) applied consistently on this side of the model

## Agreements
- Upcoming contract expiries
- Spend per organization number with an active agreement
- Comparison of actual spend vs. contract value (potential out-of-frame purchases)
- Gantt-style visual: number of agreements per organization number

## Flow
- Overview of where all purchases are made
- Selecting a purchase opens a Sankey view
- Sankey traces the purchase across multiple account levels and budget units
- Separate section for purchases not covered by agreements, enriched with descriptions from an external source

## Uncovered Purchases & Exceptions
- List of purchases not covered by any agreement
- Description fields populated from an additional data source
- Integration point for the Power App, used to document and classify exceptions

## Maintenance
- Highlights new business units that do not yet have an assigned purchaser or responsible owner
- Supports ongoing data quality and maintenance tasks

## Tooltips (Deneb / Vega)
- Two dedicated tooltip pages implemented using Deneb
- Provide detailed contextual information on hover, without cluttering the main report pages
