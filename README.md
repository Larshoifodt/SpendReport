# SpendReport
This Power BI report provides a comprehensive overview of how the organization’s purchasing and invoicing activities align with existing framework agreements. The solution is based on monthly downloads of contract data and invoice summaries, offering a solid foundation for ensuring compliance with procurement regulations. 
1. Overview
2. Features
3. Power Apps Integration
4. Data Sources and Logic

The data model includes DAX logic to match invoices and contracts based on supplier and date ranges, with explicit handling of cases where multiple contracts exist for the same supplier in the same period. See docs/data-model-and-dax.md for details.

![ezgif com-video-to-gif-converter](https://github.com/user-attachments/assets/477370d0-2062-40b2-aeb4-138e4c764069)

   
# Bridge Table Between Contract Register and ERP
In many organizations, contracts (framework agreements) are stored in one system, 
while invoices and actual spend are handled in a separate ERP system. Without a 
dedicated integration layer, it can be difficult to analyze contract coverage and 
agreement compliance across both sources.

This Power Query pattern builds a simple bridge table based on a common key 
(e.g. organization number), by:

1. Loading all contract files from a SharePoint folder
2. Extracting the relevant column (OrganizationNumber) from each file
3. Cleaning, de-duplicating and validating the values
4. Using the resulting table as a bridge between:
   - the contract register (e.g. contract system exports), and
   - the ERP / invoicing data model

See `docs/examples/powerquery-bridge-contracts-erp.m` for a generalized example 
of how this bridge table is implemented in M.
   
5. Report Structure (Queries -> DAX -> Visuals)

The report is built following a clear and structured development flow to ensure data accuracy, transparency, and maintainability:

5.1 Queries
All raw data transformations are performed in Power Query.
The source files are stored in a dedicated Teams workspace, ensuring version control, secure access, and consistency across monthly updates.
Typical steps include:

- Standardizing column names
- Cleaning and shaping contract and invoice data
- Handling relationship preparation for many-to-many scenarios
- Merging or appending datasets as needed

5.2 Data Model & DAX
After the data is transformed, it is loaded into a star-schema-like model with relationship adjustments to avoid ambiguity.
A functional workaround is implemented to handle many-to-many relationships while keeping measures accurate and responsive.
Key DAX elements include:

- Measures for contract consumption
- Controls for period validity
- Logic for agreement compliance
- Matching rules between contracts, accounts, and invoices

5.3 Visuals
The final layer presents insights through clear and interactive visualizations.
The visuals are designed to support decision-making by focusing on:

- Contract validity vs. actual purchasing
- Spend versus contractual limits
- Account and cost center usage
- Exception and deviation identification

This structure ensures that the report remains easy to maintain, scalable for future needs, and transparent for stakeholders.

7. User Guide
8. Results and Impact



