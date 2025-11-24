# Power Apps Integration and Override Logic
<img width="1364" height="636" alt="image" src="https://github.com/user-attachments/assets/ee73aa72-ac18-4f9c-a2b2-d0c779e3bd40" />

The Power App enables users to document justified exceptions when purchases fall outside framework agreements.

This workflow ensures that non-compliant spend is not over-reported, and that legitimate reasons are captured and reflected in the data model.

---

## 1. Purpose
When a purchase is classified as not covered by an agreement, users can open the embedded Power App directly from the report and register a justification. The app collects:

- Reason/category
- Notes or descriptive context
- Start/end date for the exception
- Responsible purchaser
- Timestamp of registration

The entry is written to an override list (SharePoint / Teams list or Dataverse).
During the next data refresh, Power BI:

- matches the override back to the supplier (based on OrganizationNumber)
- reclassifies the purchase from red → green
- updates KPIs, compliance visuals, exception lists and flow diagrams

This creates a transparent and fair representation of procurement compliance.

---
## 2. Preventing Duplicate Overrides (Key Integrity)

The override list uses OrganizationNumber as the key that links overrides to suppliers in the data model.
In most public-sector or ERP setups, this is the only consistent identifier across systems.

Because the key is many-to-one (one supplier → one override record), creating multiple overrides for the same supplier would:

- break referential integrity
- produce ambiguous lookups
- cause relationship errors in the model
- and risk breaking visuals that expect a single match

To prevent this, the Power App includes a validation step before writing.

If an entry for the supplier already exists, the app:
- Updates the existing record
- Does not create a duplicate

Users are also shown a popup warning to understand why they are prevented from submitting.

## 2.1 Popup Logic (Power Apps)
Below is the exact OnSelect logic from the submit button.
It checks for an existing entry, updates it if present, or creates a new one if not.

The actual names of the input controls (datacard 9-16) are arbitrary and depend on your form.

**FX / Power APP**
```
If(
    !IsBlank(
        LookUp(
            'YourOverridingList';
            Organisasjonsnr = DataCardValue9.Text
        )
    );
    Patch(
        'YourOverridingList';
        LookUp('YourOverridingList'; Organisasjonsnr = DataCardValue9.Text);
        {
            Name: DataCardValue10.Text;
            Org.number: DataCardValue9.Text;
            Message: DataCardValue11.Text;
            'Start date': DataCardValue12.SelectedDate;
            'Stopp date': DataCardValue13.SelectedDate;
            Perch: { Value: DataCardValue14.Selected.Value };
            'Registrated date': Today();
            Couse: { Value: DataCardValue16.Selected.Value }
        }
    );
    Patch(
        'YourOverridingList';
        Defaults('YourOverridingList');
        {
            Name: DataCardValue10.Text;
            Org.number: DataCardValue9.Text;
            Message: DataCardValue11.Text;
            'Start date': DataCardValue12.SelectedDate;
            'Stopp date': DataCardValue13.SelectedDate;
            Perch: { Value: DataCardValue14.Selected.Value };
           'Registrated date': Today();
            Couse: { Value: DataCardValue16.Selected.Value }
        }
    )
)
```

## 2.1 Embedded Popup
To ensure clean data entry, the Power App also displays a notification popup when:
- an override already exists
- a user attempts to create a second entry for the same supplier
- or when mandatory fields are missing

This ensures that analysts and approvers always have a clear, singular override record per supplier.

As shown in norwegian below: "Note! This org.number already exists, and can be overwritten" 

![ezgif com-video-to-gif-converter (1)](https://github.com/user-attachments/assets/908b7e80-c37b-4e90-bd61-69f4472420d0)


## 5. Access Requirements

All users who interact with the embedded Power App must have the same access as the app creator, including:

- Power Apps environment (read/write)
- SharePoint/Teams list where overrides are stored
- Power BI dataset access

If permissions differ, the app might load visually but will not save changes.

## 6. Optional: Manual Override Page in Teams

If the override list is stored in a Teams-based SharePoint list, it is recommended to:

- expose the list as a tab in Teams
- grant appropriate edit permissions

This provides a manual fallback option if:

- a user makes an incorrect entry
- an override must be edited outside the Power App
- troubleshooting or cleanup is required

This also supports auditability and transparency.

## 7. Effect in the Report

Overrides impact:

- AgreementFlag logic
- Compliance KPIs
- Deviation vs. accepted exception logic
- Sankey/flow diagrams
- Uncovered purchases table
- Contract consumption and coverage pages

As a result, users can easily distinguish between:

- True non-compliance (red)
- Approved/documented exceptions (green)
- Ambiguous cases (multiple contract matches + warning icon)

## 8. Related DocumentationWhen an override exists:
- DAX reference: /examples/Dax-Dictionary.md
- Data model design: /docs/data-model-and-dax.md
- Deneb visuals: /examples/deneb-measures.md
