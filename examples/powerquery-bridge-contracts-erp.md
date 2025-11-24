# M-CODE: Building a bridge table 

### Example on how to link a contract data with an ERP/invoicing system in Power BI

**M-code / Query Power BI**


let
    // Get all files from the SharePoint site (replace with your own tenant and site)
    Source = SharePoint.Files(
        "https://yourtenant.sharepoint.com/sites/ProcurementData/",
        [ApiVersion = 15]
    ),

    // Keep only files from the relevant folder (adjust folder path as needed)
    ContractsFolder = Table.SelectRows(
        Source,
        each Text.Contains([Folder Path], "/Shared Documents/Data/Contracts/")
    ),

    // Keep only Excel files
    ExcelFiles = Table.SelectRows(
        ContractsFolder,
        each Text.EndsWith([Name], ".xlsx") or Text.EndsWith([Name], ".xls")
    ),

    // Optionally exclude hidden files
    VisibleFiles = Table.SelectRows(
        ExcelFiles,
        each [Attributes]?[Hidden]? <> true
    ),

    // Load the "Data" sheet from each workbook
    WithData = Table.AddColumn(
        VisibleFiles,
        "Data",
        each
            let
                wb = Excel.Workbook([Content], true),
                dataSheet =
                    try
                        Table.SelectRows(wb, each [Kind] = "Sheet" and [Name] = "Data"){0}[Data]
                    otherwise
                        null
            in
                dataSheet
    ),

    // Remove files where no valid sheet was found
    NonNullData = Table.SelectRows(
        WithData,
        each [Data] <> null
    ),

    // Expand the Data column – here we only keep the column needed for the bridge in this case OrganizationNumber
    Expanded = Table.ExpandTableColumn(
        NonNullData,
        "Data",
        {"OrganizationNumber"},
        {"OrganizationNumber"}
    ),

    // Ensure correct type
    Typed = Table.TransformColumnTypes(
        Expanded,
        {{"OrganizationNumber", type text}}
    ),

    // Remove duplicate organization numbers
    DistinctOrgs = Table.Distinct(Typed),

    // IMPORTANT Remove completely blank rows
    NonBlankRows = Table.SelectRows(
        DistinctOrgs,
        each not List.IsEmpty(
            List.RemoveMatchingItems(Record.FieldValues(_), {"", null})
        )
    ),

    // Remove rows with errors in the key column
    CleanBridge = Table.RemoveRowsWithErrors(
        NonBlankRows,
        {"OrganizationNumber"}
    )

in
    CleanBridge


