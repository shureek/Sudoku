$Path = Split-Path -Path $PSCommandPath -Parent
Add-Type -Path "$Path\Sudoku.cs"

function New-Set {
    [CmdletBinding()]
    param(
        [int[]]$N
    )

    begin {
        $Set = New-Object System.Collections.Generic.SortedSet[int]
    }
    process {
        $Set.UnionWith($N)
    }
    end {
        Write-Output $Set -NoEnumerate
    }
}

function New-Tuple {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $Collection
    )

    $TypeName = "Tuple[$(,'int' * $Collection.Count -join ',')]"
    $Args = [int[]]$Collection
    New-Object $TypeName $Args
}

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
        [Sudoku.Field]$Field
    )
    
    begin {
        $SinglePlaces = New-Object 'System.Collections.Generic.Dictionary[int,int]'
        $Doubles = New-Object 'System.Collections.Generic.Dictionary[Tuple[int,int],int]'
    }
    process {
        $Removed = 0
        $Field.Rows, $Field.Columns, $Field.Squares | %{ $_ } | %{
            $Area = $_
            $AreaValues = $Area.GetValues()
            $CellIndex = -1
            foreach ($Cell in $Area) {
                $CellIndex++
                if ($Cell.Variants.Count -gt 1) {
                    $wasStr = "$($Cell.Variants)"
                    $was = $Cell.Variants.Count
                    foreach ($val in $AreaValues) {
                        if ($Cell.Variants.Remove($val)) {
                            $Removed++
                        }
                    }
                    $nowStr = "$($Cell.Variants)"
                    Write-Verbose "Cell $wasStr => $nowStr"

                    #Counting doubles
                    if ($Cell.Variants.Count -eq 2) {
                        $tuple = New-Tuple $Cell.Variants
                        [int]$Count = 0
                        if (-not $Doubles.TryGetValue($tuple, [ref]$Count)) {
                            $Count = 0
                        }
                        $Doubles[$tuple] = $Count + 1
                    }

                    #Determining single value places
                    foreach ($val in $Cell.Variants) {
                        [int]$Place = 0
                        if ($SinglePlaces.TryGetValue($val, [ref]$Place)) {
                            if ($Place -ge 0) {
                                $SinglePlaces[$val] = -1
                            }
                        }
                        else {
                            $SinglePlaces[$val] = $CellIndex
                        }
                    }
                }
            }

            #If there are numbers in one single places, then remove other numbers from that place
            foreach ($val in $SinglePlaces.Keys) {
                $Place = $SinglePlaces[$val]
                if ($Place -ge 0) {
                    $Cell = $Area[$Place]
                    $wasStr = "$($Cell.Variants)"
                    $Removed += $Cell.Variants.Count - 1
                    $Cell.Value = $val
                    Write-Verbose "Cell $wasStr => $($Cell.Variants) (single place)"
                }
            }

            #If there are doubles in two places, then remove these numbers from other places
            foreach ($tuple in $Doubles.Keys) {
                $Count = $Doubles[$tuple]
                if ($Count -eq 2) {
                    Write-Verbose "Double found ($($tuple.Item1),$($tuple.Item2)), removing from other cells"
                    foreach ($Cell in $Area) {
                        if ($Cell.Variants.Count -eq 2) {
                            if ($tuple -eq (New-Tuple $Cell.Variants)) {
                                #This is our tuple, skip it
                                continue
                            }
                        }
                        if ($Cell.Variants.Remove($tuple.Item1)) {
                            $Removed++
                        }
                        if ($Cell.Variants.Remove($tuple.Item2)) {
                            $Removed++
                        }
                    }
                }
            }

            $Doubles.Clear()
            $SinglePlaces.Clear()
        }
        $Removed
    }
}

[int[][]]$Medium = (1,0,0,4,0,0,0,5,0),
                   (7,4,8,0,1,0,0,3,0),
                   (5,3,0,0,7,9,0,0,4),
                   (4,5,0,0,0,0,0,0,7),
                   (0,0,0,0,0,0,0,0,0),
                   (0,0,0,8,5,0,0,0,0),
                   (0,0,5,0,9,7,6,0,0),
                   (6,0,4,0,0,8,9,0,0),
                   (0,7,9,5,6,0,0,0,1)

[int[][]]$Hard = (0,0,4,0,0,8,9,0,0),
                 (0,0,9,0,1,0,0,7,0),
                 (0,0,8,0,0,4,0,0,2),
                 (0,7,0,6,0,0,0,9,4),
                 (4,0,0,0,0,0,0,0,6),
                 (5,9,0,0,0,1,0,2,0),
                 (9,0,0,8,0,0,2,0,0),
                 (0,8,0,0,9,0,7,0,0),
                 (0,0,7,2,0,0,3,0,0)

$Expert = @'
|    7     8      |
|            6 5  |
|    9     2     4|
|  5 4   9     6 8|
|                 |
|2 1     4   7 9  |
|7     5     8    |
|  4 1            |
|      3     2    |
'@

$Field = New-Object Sudoku.Field
$Field.Init($Expert)

Write-Verbose "Start" -Verbose
Format-Field $Field

$step = -1
do
{
    $step++
    Write-Verbose "Step $step" -Verbose
    $Removed = Remove-WrongVariants $Field
    Write-Verbose "$Removed removed" -Verbose
    Format-Field $Field -Full
} while ($Removed -gt 0)