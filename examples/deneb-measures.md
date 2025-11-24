# Deneb / SVG Measures

<img width="800" height="492" alt="image" src="https://github.com/user-attachments/assets/a0fa649f-e368-46bd-b34a-a60f3b0aa05a" />

## Transaction History Tooltip

**Purpose**  
Shows a small historical bar chart for the selected supplier/organization in a tooltip, with:
- the last 3 years of transactions,
- yellow bars for amounts above legal procurment threshold,
- green bars for amounts below,
- a dashed line at the threshold.

Used to quickly see whether the current transaction is part of a larger pattern of high-value purchases.
You might ask; what about the accumulative value of transactions? - This is covered in the actual PBI sheet, 
as the tooltip is there for a quick glimpse on transaction trends only. 

**Logic**  
- Filters the invoice fact table on the current organization and the last 3 years.  
- Normalizes the Y-axis based on min/max amount.  
- Calculates X/Y positions for each bar in a fixed 300x100 SVG grid.  
- Colors bars based on a threshold (e.g. 100k / 125k).  
- Adds static gridlines and a dashed line at the threshold value.  
- Returns a full `data:image/svg+xml` string that can be rendered by Deneb.

```DAX
NameYourMeassure =
VAR StartDate = DATE ( YEAR ( TODAY() ) - 3, 1, 1 )
VAR EndDate = TODAY ()
VAR OrganizationNumber =
    SELECTEDVALUE ( Invoices[OrganizationNumber] )

VAR FilteredTable =
    FILTER (
        Invoices,
        Invoices[OrganizationNumber] = OrganizationNumber
            && Invoices[InvoiceDate] >= StartDate
            && Invoices[InvoiceDate] <= EndDate
    )

VAR Threshold = 125000

VAR YMinValue = 0
VAR YMaxValue = MAXX ( FilteredTable, Invoices[Amount] )
VAR NormalizedYMax =
    IF ( YMaxValue = YMinValue, YMinValue + 1, YMaxValue )

VAR BarTable =
    ADDCOLUMNS (
        FilteredTable,
        "X", INT ( 300 * DIVIDE ( Invoices[InvoiceDate] - StartDate, EndDate - StartDate ) ),
        "Y", INT ( 100 * DIVIDE ( Invoices[Amount] - YMinValue, NormalizedYMax - YMinValue ) ),
        "Color",
            SWITCH (
                TRUE (),
                Invoices[Amount] < Threshold, "#156565",   // green
                Invoices[Amount] >= Threshold, "#F5EC5F"   // yellow
            )
    )

VAR Bars =
    CONCATENATEX (
        BarTable,
        "<rect x='" & [X] & "' y='" & 100 - [Y] &
        "' width='10' height='" & [Y] & "' fill='" & [Color] & "' />",
        " "
    )

VAR GridYLines =
"<line x1='0' y1='100' x2='300' y2='100' stroke='grey' stroke-width='1' />
<line x1='0' y1='50' x2='300' y2='50' stroke='grey' stroke-width='1' />
<line x1='0' y1='0' x2='300' y2='0' stroke='grey' stroke-width='1' />"

VAR GridXLines =
"<line x1='0' y1='0' x2='0' y2='100' stroke='grey' stroke-width='1' />
<line x1='100' y1='0' x2='100' y2='100' stroke='grey' stroke-width='1' />
<line x1='200' y1='0' x2='200' y2='100' stroke='grey' stroke-width='1' />
<line x1='300' y1='0' x2='300' y2='100' stroke='grey' stroke-width='1' />
<text x='0' y='115' font-size='16' fill='grey'>-3</text>
<text x='100' y='115' font-size='16' fill='grey'>-2</text>
<text x='200' y='115' font-size='16' fill='grey'>-1</text>
<text x='300' y='115' font-size='16' fill='grey'>0</text>"

VAR ThresholdY =
    INT ( 100 * DIVIDE ( Threshold - YMinValue, NormalizedYMax - YMinValue ) )

VAR ThresholdLine =
"<line x1='0' y1='" & 100 - ThresholdY &
"' x2='300' y2='" & 100 - ThresholdY &
"' stroke='grey' stroke-width='2' stroke-dasharray='5,5' />
<text x='305' y='" & 100 - ThresholdY + 2 &
"' font-size='12' fill='grey'>Threshold</text>"

RETURN
"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' x='0px' y='0px' viewBox='0 0 300 120' style='background:#BBE4E3;'>" &
    GridYLines &
    GridXLines &
    Bars &
    ThresholdLine &
"</svg>"
