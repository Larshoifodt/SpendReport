# M-CODE: Loading and cleaning invoice export files from SharePoint

#### Example of how to export invoice data to a PBI data model. 
This query operates on files stored in Teams/SharePoint and works seamlessly whether the data is populated automatically through APIs or uploaded manually. 
For manual workflows, replacing the content within the same file (rather than creating new files) is recommended to avoid refresh inconsistencies and schema drift.

let
    // Connect to the SharePoint site (replace with your own tenant and site)
    Source = SharePoint.Files(
        "https://yourtenant.sharepoint.com/sites/FinanceData/",
        [ApiVersion = 15]
    ),

    // Filter only files from the relevant folder and with the expected name pattern
    FilteredFiles = Table.SelectRows(
        Source,
        each
            Text.Contains([Folder Path], "/Shared Documents/Data/ERP/") and
            Text.StartsWith([Name], "InvoiceExport") and
            Text.EndsWith([Name], ".xlsx")
    ),

    // Load each file as an Excel workbook
    ExcelData = Table.AddColumn(
        FilteredFiles,
        "ExcelData",
        each Excel.Workbook([Content], null, true)
    ),

    // Expand workbook content to get sheets
    ExpandedSheets = Table.ExpandTableColumn(
        ExcelData,
        "ExcelData",
        {"Data", "Item", "Kind"}
    ),

    // Keep only sheets that start with "InvoiceExport" 
    InvoiceSheets = Table.SelectRows(
        ExpandedSheets,
        each [Kind] = "Sheet" and Text.StartsWith([Item], "InvoiceExport")
    ),

    // By the way - if the source is updated manually - it will be more efficiant to keep the file and replace the data. 

    // Promote first row to headers with a try/otherwise safety net
    WithHeaders = Table.AddColumn(
        InvoiceSheets,
        "DataWithHeaders",
        each
            try
                Table.PromoteHeaders([Data], [PromoteAllScalars = true])
            otherwise
                null
    ),

    // Remove empty tables
    NonEmptyTables = Table.SelectRows(
        WithHeaders,
        each [DataWithHeaders] <> null
            and Table.RowCount([DataWithHeaders]) > 0
    ),

    // Combine everything into one big table
    CombinedTable = Table.Combine(NonEmptyTables[DataWithHeaders]),

    // Dynamically keep all columns except a known internal column (optional pattern)
    AvailableColumns = Table.ColumnNames(CombinedTable),
    KeptColumns = List.RemoveItems(AvailableColumns, {"InternalFieldToExclude"}),
    CleanTable = Table.SelectColumns(CombinedTable, KeptColumns),

    // Fix data types and handle mixed/dirty values
    TypedTable = Table.TransformColumns(
        CleanTable,
        {
            {"OrganizationNumber", each try Text.From(_) otherwise "Unknown", type text},
            {"ResponsibilityCenter", each try Text.From(_) otherwise "Unknown", type text},
            {"ResponsibilityCenterName", each try Text.From(_) otherwise "Unknown", type text},
            {"VoucherNumber", each try Int64.From(_) otherwise null, Int64.Type},
            {
                "PostingDate",
                each
                    try
                        if Value.Is(_, type date) then _
                        else if Value.Is(_, type text) then Date.FromText(_)
                        else if Value.Is(_, type number) then
                            Date.From(Date.AddDays(#date(1899, 12, 30), Number.RoundDown(_)))
                        else
                            null
                    otherwise
                        null,
                type date
            },
            {"Period", each try Int64.From(_) otherwise null, Int64.Type},
            {"AccountClass", each try Int64.From(_) otherwise null, Int64.Type},
            {"AccountClassName", each try Text.From(_) otherwise "Unknown", type text},
            {"AccountGroup", each try Int64.From(_) otherwise null, Int64.Type},
            {"AccountGroupName", each try Text.From(_) otherwise "Unknown", type text},
            {"AccountSubCode", each try Int64.From(_) otherwise null, Int64.Type},
            {"AccountSubCodeName", each try Text.From(_) otherwise "Unknown", type text},
            {"Account", each try Int64.From(_) otherwise null, Int64.Type},
            {"AccountName", each try Text.From(_) otherwise "Unknown", type text},
            {"BusinessUnit", each try Int64.From(_) otherwise null, Int64.Type},
            {"BusinessUnitName", each try Text.From(_) otherwise "Unknown", type text},
            {"Purpose", each try Int64.From(_) otherwise null, Int64.Type},
            {"PurposeName", each try Text.From(_) otherwise "Unknown", type text},
            {"Project", each try Int64.From(_) otherwise null, Int64.Type},
            {"ProjectName", each try Text.From(_) otherwise "Unknown", type text},
            {"Text", each try Text.From(_) otherwise "Unknown", type text},
            {"Amount", each try Number.From(_) otherwise null, type number}
        }
    ),

    // Example of business rule filters – adapt to your own logic
    // Filter out a specific internal account (e.g. clearing account)
    FilteredAccount = Table.SelectRows(
        TypedTable,
        each [Account] <> 1234
    ),

    // Additional filters (e.g. business unit, account class, responsibility center)
    FilteredBusinessRules = Table.SelectRows(
        FilteredAccount,
        each
            [BusinessUnit] <> 1234
                and [AccountClass] >= 2
                and [AccountClass] <= 3
                and [ResponsibilityCenter] <> "0"
    ),

    // Rename some columns to cleaner names
    RenamedColumns = Table.RenameColumns(
        FilteredBusinessRules,
        {
            {"Purpose", "PurposeCode"},
            {"PurposeName", "Purpose Description"},
            {"Amount", "AmountValue"}
        }
    ),

    // Set amount as currency
    AmountAsCurrency = Table.TransformColumnTypes(
        RenamedColumns,
        {{"AmountValue", Currency.Type}}
    ),

    // Add an amount category based on thresholds
    WithAmountCategory = Table.AddColumn(
        AmountAsCurrency,
        "AmountCategory",
        each
            if [AmountValue] < 80000 then
                "A: < 80k"
            else if [AmountValue] >= 80000 and [AmountValue] < 100000 then
                "B: 80k–100k"
            else if [AmountValue] >= 100000 and [AmountValue] < 500000 then
                "C: 100k–500k"
            else if [AmountValue] >= 500000 and [AmountValue] < 1400000 then
                "D: 500k–1.4M"
            else if [AmountValue] >= 1400000 and [AmountValue] < 8000000 then
                "E: 1.4M–8M"
            else
                "F: > 8M",
        type text
    ),

    // Make the "name" columns a bit nicer (display labels)
    DisplayNames = Table.RenameColumns(
        WithAmountCategory,
        {
            {"ResponsibilityCenterName", "Responsibility Center Name"},
            {"AccountClassName", "Account Class Name"},
            {"AccountGroupName", "Account Group Name"},
            {"AccountSubCodeName", "Account Subcode Name"},
            {"AccountName", "Account Name"},
            {"BusinessUnitName", "Business Unit Name"},
            {"ProjectName", "Project Name"}
        }
    ),

    // Reorder columns for readability
    ReorderedColumns = Table.ReorderColumns(
        DisplayNames,
        {
            "OrganizationNumber",
            "ResponsibilityCenter",
            "Responsibility Center Name",
            "VoucherNumber",
            "PostingDate",
            "Period",
            "AccountClass",
            "Account Class Name",
            "AccountGroup",
            "Account Group Name",
            "AccountSubCode",
            "Account Subcode Name",
            "Account",
            "Account Name",
            "BusinessUnit",
            "Business Unit Name",
            "PurposeCode",
            "Purpose Description",
            "Project",
            "Project Name",
            "Text",
            "AmountValue",
            "AmountCategory"
        }
    ),

    // Add a unique index for each row
    Indexed = Table.AddIndexColumn(
        ReorderedColumns,
        "Index",
        0,
        1,
        Int64.Type
    ),

    // Add combined labels for use in visuals (account, BU, etc.)
    WithAccountLabel = Table.AddColumn(
        Indexed,
        "AccountLabel",
        each Text.Combine({Text.From([Account]), [Account Name]}, " "),
        type text
    ),

    WithBusinessUnitLabel = Table.AddColumn(
        WithAccountLabel,
        "BusinessUnitLabel",
        each Text.Combine({Text.From([BusinessUnit]), [Business Unit Name]}, " "),
        type text
    ),

    WithAccountSubCodeLabel = Table.AddColumn(
        WithBusinessUnitLabel,
        "AccountSubCodeLabel",
        each Text.Combine({Text.From([AccountSubCode]), [Account Subcode Name]}, " "),
        type text
    ),

    WithAccountGroupLabel = Table.AddColumn(
        WithAccountSubCodeLabel,
        "AccountGroupLabel",
        each Text.Combine({Text.From([AccountGroup]), [Account Group Name]}, " "),
        type text
    )

in
    WithAccountGroupLabel
