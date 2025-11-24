// Example: Loading a single Excel file from a SharePoint library 
// and preparing a cleaned contract table

let
    // Connect to the SharePoint site (replace with your own tenant and site)
    Source = SharePoint.Files(
        "https://yourtenant.sharepoint.com/sites/ProcurementData/", 
        [ApiVersion = 15]
    ),

    // Filter for the specific folder and file (adjust path and file name as needed)
    FilteredFile = Table.SelectRows(
        Source, 
        each 
            Text.Contains([Folder Path], "/Shared Documents/Data/Contracts/") 
            and [Name] = "Contracts.xlsx"
    ),

    // Load the Excel workbook content
    ExcelFile = Table.AddColumn(
        FilteredFile, 
        "ExcelData", 
        each Excel.Workbook([Content], null, true)
    ),

    // Expand the workbook to get sheets / tables
    ExpandedData = Table.ExpandTableColumn(
        ExcelFile, 
        "ExcelData", 
        {"Data", "Item", "Kind"}
    ),

    // Keep only the sheet named "Data"
    DataSheet = Table.SelectRows(
        ExpandedData, 
        each [Kind] = "Sheet" and [Item] = "Data"
    ),

    // Promote first row to headers, with a safety try/otherwise
    WithHeaders = Table.AddColumn(
        DataSheet, 
        "DataWithHeaders", 
        each 
            try Table.PromoteHeaders([Data], [PromoteAllScalars = true]) 
            otherwise null
    ),

    // Remove any null tables and keep only those with rows
    NonEmptyTables = Table.SelectRows(
        WithHeaders, 
        each [DataWithHeaders] <> null 
             and Table.RowCount([DataWithHeaders]) > 0
    ),

    // Combine all resulting tables into one
    CombinedTable = Table.Combine(NonEmptyTables[DataWithHeaders]),

    // Set column types to match the expected contract structure
    TypedTable = Table.TransformColumnTypes(
        CombinedTable,
        {
            {"Contract Name", type text},
            {"Reference Number", type text},
            {"Contract Owner", type text},
            {"Owner Phone", type text},
            {"Owner Email", type text},
            {"Stage", type text},
            {"Phase", type text},
            {"Contract Type", type text},
            {"Start Date", type date},
            {"End Date", type date},
            {"Status", type text},
            {"Vendor Name", type text},
            {"Vendor Organization Number", type text},
            {"Vendor Department", type text},
            {"Vendor Address", type text},
            {"Vendor Postal Code", type text},
            {"Vendor City", type text},
            {"Vendor Country", type text},
            {"Vendor Phone", type text},
            {"Vendor Fax", type text},
            {"Vendor Email", type text},
            {"Vendor Website", type text},
            {"Contact Person", type text},
            {"Contact Phone", type text},
            {"Contact Email", type text},
            {"Contract Value", type number},
            {"Signed Date", type date},
            {"Extended", type logical},
            {"Extension Months", Int64.Type},
            {"Extension Count", Int64.Type},
            {"Final End Date", type date},
            {"Reminder Months Before Extension", Int64.Type},
            {"Original End Date", type date},
            {"Created From Procurement", type text},
            {"Procurement Initiator", type text},
            {"Owner Department", type text},
            {"Client Department", type text},
            {"Description", type text},
            {"Notes", type text},
            {"Keywords", type text},
            {"Language", type text},
            {"Subscribers", Int64.Type},
            {"Call-off Method", type text},
            {"Ranking", Int64.Type},
            {"UNSPSC", type text},
            {"Contract Area", type text}
        }
    ),

    // Create a combined address column for fancy map functions later on
    WithFullAddress = Table.AddColumn(
        TypedTable, 
        "Full Address",
        each Text.Combine(
            {
                [Vendor Address],
                [Vendor Postal Code],
                [Vendor City],
                [Vendor Country]
            }, 
            ", "
        ),
        type text
    ),

    // And remove the original address columns after combining
    RemovedAddressColumns = Table.RemoveColumns(
        WithFullAddress,
        {"Vendor Address", "Vendor Postal Code", "Vendor City", "Vendor Country"}
    ),

    // Reorder key columns for better readability
    ReorderedColumns = Table.ReorderColumns(
        RemovedAddressColumns,
        {
            "Vendor Organization Number", "Contract Name", "Reference Number",
            "Contract Type", "Start Date", "End Date", "Vendor Name", "Full Address", "Contact Person",
            "Extended", "Extension Months", "Extension Count", "Final End Date",
            "Original End Date", "Description", "Notes", "Call-off Method", "UNSPSC", "Contract Area"
        }
    ),

    // IMPORTANT always add a unique index for each row
    IndexedTable = Table.AddIndexColumn(
        ReorderedColumns, 
        "Index", 
        0, 
        1, 
        Int64.Type
    ),

    // Example of renaming a column for internal use
    FinalTable = Table.RenameColumns(
        IndexedTable,
        {{"Status", "Status_Internal"}}
    )

in
    FinalTable
