$VerbosePreference = 'Continue'

$Path = Split-Path -Path $PSCommandPath -Parent
Add-Type -Path "$Path\Sudoku.cs"

function Format-Field {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Sudoku.Field]$Field,
        [Switch]$Full
    )

    begin {
        $sb = New-Object System.Text.StringBuilder
    }
    process {
        if ($Full) {
            # Determine column widths
            [int[]]$Widths = @(1) * $Field.Size
            #[int[]]$Widths = New-Object int[] $Field.Size
            foreach ($col in 0..($Field.Size-1)) {
                foreach ($row in 0..($Field.Size-1)) {
                    $VarCount = $Field[$row,$col].Variants.Count
                    if ($VarCount -gt $Widths[$col]) {
                        $Widths[$col] = $VarCount
                    }
                }
            }

            foreach ($row in 0..($Field.Size-1)) {
                if ($row -gt 0) {
                    [void]$sb.AppendLine()
                }
                foreach ($col in 0..($Field.Size-1)) {
                    if ($col -gt 0) {
                        [void]$sb.Append('|')
                    }
                    $Variants = $Field[$row,$col].Variants
                    foreach ($val in $Variants) {
                        [void]$sb.Append($val)
                    }
                    if ($Widths[$col] -gt $Variants.Count) {
                        [void]$sb.Append(' ', $Widths[$col] - $Variants.Count)
                    }
                }
            }
        }
        else {
            foreach ($row in 0..($Field.Size-1)) {
                if ($row -gt 0) {
                    [void]$sb.AppendLine()
                }
                foreach ($col in 0..($Field.Size-1)) {
                    if ($col -gt 0) {
                        [void]$sb.Append('|')
                    }
                    $Cell = $Field[$row,$col]
                    if ($Cell.Value -ne $null) {
                        [void]$sb.Append($Cell.Value)
                    }
                    else {
                        [void]$sb.Append(' ')
                    }
                }
            }
        }
        Write-Output $sb.ToString()
        $sb.Length = 0
    }
}

function Remove-WrongVariants {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Sudoku.Area]$Area
    )

    $AreaValues = $Area.GetValues()
    Write-Verbose "Area values: $($AreaValues)"
    foreach ($Cell in $Area) {
        if ($Cell.Variants.Count -gt 1) {
            Write-Verbose "Cell variants was: $($Cell.Variants)"
            $was = $Cell.Variants.Count
            foreach ($val in $AreaValues) {
                Write-Verbose "Removing $val"
                [void]$Cell.Variants.Remove($val)
            }
            $now = $Cell.Variants.Count
            Write-Verbose "Cell variants now: $($Cell.Variants)"
        }
    }
}

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

Write-Verbose "Start"
Format-Field $Field -Full

Write-Verbose "Removing wrong variants"
#Trace-Command -Expression {
$Field.Rows, $Field.Columns, $Field.Squares | %{
    Write-Verbose "Processing area collection"
    $_
} | %{
    Write-Verbose "Processing $($_.Type) $($_.GetValues())"
    Write-Output $_ -NoEnumerate
} | Remove-WrongVariants -Verbose
#} -Name ParameterBinding -PSHost

Format-Field $Field -Full