#requires -version 3.0

[CMDLETBINDING()]
Param(
    $path = "${pwd}\names.txt"
)

#region Pair
Function Get-Pair {
    param(
        [Parameter(Mandatory)]
        [System.Collections.ArrayList]$users,

        [string]$pickTwo
    )

    if ($pickTwo) {  
      
        $users.Remove($pickTwo)
        for ($i=0; $i -lt 2 ; $i++ ) {
            
            $temp = Get-Random -InputObject $users        
            [PSCustomObject]@{ "LeftPair"=$pickTwo ; "RightPair" = $temp }                
            $users.Remove($temp)
        }        
    }

    For ($i=0; $i -lt $users.Count; $i+=2) {
    
        Write-Verbose "$($users[$i]) : $($users[$i+1])"
        [PSCustomObject]@{ "LeftPair"=$users[$i] ; "RightPair" = $users[$i+1] }   
    
    }

}
#endregion


############  main script ########################

[array]$names = ((Get-Content $path) -split ',').Trim()

Write-Verbose "Randomizing members"
$names = Get-Random -InputObject $names -Count $names.Count
# $names+='Adil'   ## use to test odd number



if ($names.Count % 2 -eq 0) {
    ## even number
    Write-Verbose "Members are even"
    $paired = Get-Pair -users $names -Verbose
    
} else {
    ## odd number
    
        Write-Warning "Odd number of people, please select a person to have two pals."
        Do  {
             
            ## to do: remove $names, might be too crowded          
            $doubleChooser=Read-Host "Please choose a person to have 2 pals $names"
            ## to do: have to do something about case-sensitivity
        } while ($names -cnotcontains $doubleChooser)
        
        $paired = Get-Pair -users $names -pickTwo $doubleChooser -Verbose
}


$paired |export-csv "${pwd}\pairs_output_$(get-date -format 'yyyyMMdd_HHmmss').csv"

