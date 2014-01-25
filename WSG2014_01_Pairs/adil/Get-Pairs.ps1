
#requires -version 3.0

<#
    .Synopsis
       Creates pairs of names from a supplied list

    .DESCRIPTION
       The Get-Pairs.ps1 script when run when run without aany parameters will search the current directory for a list of names and pair them to form secret pals. 
       If the list contains an odd number it prompts the user to select the name that will have more than one secret pal.

       When run with the -primary parameter, the names in an alternate list are considered primary and the script will first math these with the rest of the names before pairing any remaining people. 
       It also checks to to ensure that people are not repeatedly matched during subsequent runs of the script 


    .PARAMETER UserList
        specifies the path to the text file that contains the list of names

    .PARAMETER Primary
        specifies the names of primary members of the team    

    .PARAMETER PreviousPairDirectory
        specifies the directory that previous pairings will be stored. These will be used match against subsequent pairings to avoid repeats

    .EXAMPLE
        Get-Pairs.ps1 -UserList C:\scratch\names.txt
        This example will generate pairs from names in the list names.txt

    .EXAMPLE
   
        .\Get-Pairs.ps1 -UserList C:\scratch\names.txt -primary Matt

        This example will generate pairs from names in the list names.txt, while taking Matt as a primary.
#>

[CMDLETBINDING()]
Param(
        [Parameter(Position=1)] 
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})] 
        [String]$UserList = "$pwd\names.txt"                
    
)

Function Get-PairForOdd {
    <#
        .SYNOPSIS
        Handles the case where one person will be paired to two others

        .DESCRIPTION
        
        .NOTES
        In the case of odd number of people, someone ($doubleChooser) needs to be paired with two others. However, there is a case where the selected person may also be a primary. 
        Because script first gets a pair for each primary, this means the selected person ($doubleChooser) has already been paired once, and only needs to be paired one more person
        This is the reason we have $pick parameter 

    #>
    param (
        [System.Collections.ArrayList]$pool,        
        [string]$doubleChooser
        
    )

        ## we will always remove the users we are pairing or paired from the pool of $pool 
        ## so that they do not come up as a result of get-random    
        $left = $doubleChooser       

        Write-Verbose "Get-PairForOdd: $left will pick 2 from available people"                        
        for ($i=0; $i -lt 2 ; $i++ ) {
                
            $right = Get-Random -InputObject $pool                                                
            
            Write-Verbose "Get-PairForOdd: Pairing result: $left | $right"        
            [PSCustomObject]@{ "LeftPair"=$left ; "RightPair" = $right }                

            Write-Verbose "Get-PairForOdd: Removing $right from the pool of people"
            [void]$pool.Remove($right)

        }        
}

Function Get-PairForEven {
<#
    .SYNOPSIS
    Create Pairs within set constraints

    .DESCRIPTION
    Gets a pool of people to choose from and create pairs taking into account whether they were paired before and satisfy that criteria
    
    .NOTES
    At this point, main script should have taken care of primaries, so no need to check if the paired people are primaries  
#>
    param(
        [Parameter(Mandatory)]
        [System.Collections.ArrayList]$pool,        

        [hashtable]$previousPairs
    )


    ## Below code will handle an even number pairing 
    While ($pool.Count -gt 0) {       
        
        
            ## idea is that we will pop $pool from left (index=0) one by one
            Write-Verbose "Get-PairForEven: Pool size: $($pool.count)"
            $left = $pool[0]            
            [void]$pool.RemoveAt(0)
        
            $right = Get-Random -InputObject $pool    

            Write-Verbose "Get-PairForEven: Pairing result: $left | $right"
            [PSCustomObject]@{ "LeftPair"=$left ; "RightPair" = $right }   

            Write-Verbose "Get-PairForEven: Removing $right from the pool of people"
            [void]$pool.Remove($right)

    }

}

############  Main Script ########################

## assuming name_email.txt kind of input
$Names=Get-Content $UserList
## <<<<<<< HEAD
## $gamesName = "WSG2014_Event1_Pairs"

## $transcriptPath = "$pwd\$gamesName.txt"
## Start-Transcript -Path $transcriptPath
## =======
## >>>>>>> 272ec6082f0b3bbd86a8a24d3158b0408aed3131

[System.Collections.ArrayList]$AvailablePool=$Names
$AllPairs=@()

Write-Verbose "Available pool: $($AvailablePool.count)"

#region handle_odd_number
if ($names.Count % 2 -ne 0) {
    ## odd number
    
    Write-Warning "Odd number of people, please select a person to have two pals. $($names.count)"
    Do  {             
        
        # $doubleChooser=Read-Host "Please choose a person to have 2 pals`n $names"
         $doubleChooser = $names |Out-GridView -OutputMode Single -Title "Odd number of people, please select a person to have two pals."
        
    } while (!$doubleChooser)

    
    Write-Verbose "Removing $doubleChooser from available name pool"
    $AvailablePool.Remove($doubleChooser)
               
    $OddPair = Get-PairForOdd -pool $AvailablePool -doubleChooser $doubleChooser -verbose

    $AllPairs += $oddpair | % {$_}
}
#endregion handle_odd_number

#region hand_even_number if any people left
if ($AvailablePool.count -ge 2) {
    
    $EvenPair = Get-PairforEven -pool $AvailablePool -Verbose        
    $AllPairs +=$EvenPair | % {$_}
}

#region output
$Outputfile = "$PreviousPairDirectory\Pairs1_Output_$(get-date -format 'yyyyMMdd_HHmmss').csv"

$AllPairs |export-csv -NoTypeInformation -Path $Outputfile
$AllPairs |Format-Table -AutoSize

"Results are written to $Outputfile"
## Stop-Transcript 
#endregion output