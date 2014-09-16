$VerbosePreference = 'Continue'

$Path = Split-Path -Path $PSCommandPath -Parent
Add-Type -Path "$Path\Sudoku.cs"

$Field = New-Object Sudoku.Field
$Field.Init(((0,9,0,0,0,0,6,2,8),
             (0,8,6,0,9,0,5,7,3),
             (3,2,7,6,8,5,1,9,4),
             (8,5,0,0,1,0,0,3,0),
             (0,4,3,7,2,8,9,0,0),
             (0,0,0,0,0,0,0,8,0),
             (2,1,8,5,6,3,7,4,9),
             (4,0,0,8,7,0,3,0,2),
             (0,3,9,0,4,0,8,0,0)))

$sb = New-Object System.Text.StringBuilder
foreach ($Row in $Field.Rows) {
    foreach ($Cell in $Row) {
        [void]$sb.Append('|')
        if ($Cell.Value -ne $null) {
            [void]$sb.Append($Cell.Value)
        }
        else {
            [void]$sb.Append(' ')
        }
    }
    $sb.ToString()
    $sb.Length = 0
}