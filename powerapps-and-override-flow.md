# Power Apps Integration and Override Flow

The Power App enables users to document justified exceptions when purchases fall outside framework agreements.

This workflow ensures that non-compliant spend is not over-reported, and that legitimate reasons are captured and reflected in the data model.
![ezgif com-video-to-gif-converter (1)](https://github.com/user-attachments/assets/908b7e80-c37b-4e90-bd61-69f4472420d0)

---

## 1. Purpose

The override system allows purchasers, controllers, and end users to:
- Document why a specific purchase is outside contract  
- Add classification, category, and notes  
- Flag legitimate exceptions so they appear compliant in the report  

---

## 2. Process Flow

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
