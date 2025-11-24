# Power Apps Integration and Override Logic
<img width="1364" height="636" alt="image" src="https://github.com/user-attachments/assets/ee73aa72-ac18-4f9c-a2b2-d0c779e3bd40" />

The Power App enables users to document justified exceptions when purchases fall outside framework agreements.

This workflow ensures that non-compliant spend is not over-reported, and that legitimate reasons are captured and reflected in the data model.

---

## 1. Purpose

Users can register a justified exception (e.g., documented reason, classification, start/stop date).
When the Power App writes this information to the override list (Kollektiv hukommelse), the report will, upon refresh:

- Convert the transaction from red → green
- Treat it as a documented exception
- Ensure that agreement coverage metrics remain realistic and fair

This avoids punishing legitimate purchases that fall outside contract scope for valid reasons.

---
## 2. Preventing Duplicate Overrides (Key Integrity)

The matching key between the ERP dataset and the override list is (for most organizations) OrganizationNumber.

Because this key is many-to-one (one supplier → one override entry), multiple overrides for the same organization number would:
- break referential integrity
- cause model relationship conflicts
- and potentially crash visuals relying on unambiguous lookups

To prevent this, the Power App includes logic that checks whether an entry already exists before writing.

If an override already exists, a Power Apps popup warning appears, preventing accidental duplication. 
Dette kan fint spores tilbake i refresh-log i fabric - men er en fin ting å unngå. 


## 2.1 Popup Logic (Power Apps)
Below is the exact OnSelect logic from the submit button.
It checks for an existing entry, updates it if present, or creates a new one if not.

Datacard 9-10 is obviously arbetrary - and just reflects 

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

As shown in norwegian below: "PS! This org.number already exists, and can be overwritten" 

![ezgif com-video-to-gif-converter (1)](https://github.com/user-attachments/assets/908b7e80-c37b-4e90-bd61-69f4472420d0)


## 5. Access Requirements

All report users who interact with the embedded Power App must:

1. Have access to the Power Apps environment where the app is created
2. Have at least read/write access to the SharePoint or Dataverse list storing override data
3. Have access to the Power BI dataset (otherwise the embedded app will fail to load)

Without aligned permissions, the Power App appears but does not save changes.
Process Flow
---
## 6. Effect in the Report
When an override exists:

- The purchase changes from non-compliant → documented exception
- KPIs adjust accordingly
- Red/green classification updates
- Multiple visuals (including Sankey, Uncovered Purchases, and Agreement Coverage) are updated

This makes the override flow a key part of presenting a fair, contextual and organization-aware view of procurement compliance.

---
1. A purchase is identified as outside an agreement  
2. User opens the embedded Power App  
3. User provides justification:  
   - Reason  
   - Category  
   - Notes  
4. The app stores the override entry in a SharePoint list / Dataverse  
5. Power BI refresh picks up overrides and updates logic:  
   - Red → Green if approved  
   - Contract matching logic remains intact  
---

## 3. How Overrides Affect the Report

Overrides update:
- AgreementFlag logic  
- Compliance visuals  
- KPIs for covered vs. uncovered spend  
- Exception lists  
- Sankey/Flow views  

Users instantly understand:
- True non-compliance  
- Documented and accepted deviations  
- Patterns that require procurement follow-up  

---

## 4. Related Documentation

- Agreement logic and DAX: `/examples/Dax-Dictionary.md`  
- Data model structure: `/examples/data-model-and-dax.md`  
- Deneb SVG tooltip visuals: `/examples/deneb-measures.md`  
