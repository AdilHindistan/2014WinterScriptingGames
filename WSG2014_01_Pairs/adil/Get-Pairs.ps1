<#
.Synopsis
   Creates pairs of names from a supplied list

.DESCRIPTION
   The Get-Pairs.ps1 script when run when run without aany parameters will search the current directory for a list of names and pair them to form secret pals. 
   If the list contains an odd number it prompts the user to select the name that will have more than one secret pal.

   When run with the -primary parameter, the names in an alternate list are considered primary and the script will first math these with the rest of the names before pairing any remaining people. 
   It also checks to to ensure that people are not repeatedly matched during subsequent runs of the script 


.PARAMETER UserList
    specifies the path to the text file that contains the list of name

.PARAMETER Primary

.PARAMETER PreviousPairDirectory

.EXAMPLE
    Get-Pairs.ps1 -UserList C:\scratch\names.txt
    This example will generate pairs from names in the list names.txt

.EXAMPLE
   
    .\Get-Pairs.ps1 -UserList C:\scratch\names.txt -primary c:\scratch\primarylist.txt
    This example will generate pairs from names in the list names.txt, while taking Matt as a primary.
#>

#requires -version 3.0

[CMDLETBINDING()]
Param(
        [Parameter(Position=1)] 
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})] 
        [String]$UserList = "$pwd\names3.txt",
        
        [Parameter(Position=2)]
        [ValidateScript({Test-Path "$_\pairs_output_*.csv"})]
        [String]$PreviousPairDirectory = "$pwd",
    
        [Parameter(Position=3)] 
        [ValidateCount(0,5)]
        [string[]]$primary#=@("Sunny","David","John","Adil")
)


Function Check-PreviousPair {
<#
    .SYNOPSIS
    Check if pair satisfy constraints for previous pairs
#>
    param (
            [string]$left,
            [string]$right,
            [hashtable]$previousPairs
    )

     ## Check against previous pair  constraint
    $previouslyPaired = $previousPairs[$left]                
    if ($right -in $previouslyPaired) {
                
        Write-Verbose "Check-PreviousPair: $left paired with $right before! Additional checks needed."

        if ($previouslyPaired.Count -gt 4) {
            write-verbose "Check-PreviousPair: $left has paired with at least 4 other people before, OK to pair them again"                    
            $false

        } else {
            Write-Verbose "Check-PreviousPair: $left has not yet been paired with 4 other people, so needs to be paired with someone else"
            $true
            ## todo : edge case, what if there is a prime vs prime left?
        }            
    }
}

Function Get-Pair {
<#
    .SYNOPSIS
    Create Pairs within set constraints
#>
    param(
        [Parameter(Mandatory)]
        [System.Collections.ArrayList]$pool,
        [string]$pickTwo,
        [string[]]$prime=@('AndY','haZEM','BeZEN','JULIE'),
        [hashtable]$previousPairs
    )

    Write-Verbose "Get-Pair: pool size: $($pool.count)"        
    #region handle_odd
    ## This part of code handles odd case, where one person is paired to two pals
    ## Todo: I think this part can be collapsed into the handle_even, as the same set of checks needs to be done here too
    if ($pickTwo) {  
    
        ## we will always remove the users we are pairing or paired from the pool of $pool 
        ## so that they do not come up as a result of get-random    
        $left = $pickTwo
        
        Write-Verbose "Get-Pair: Removing $left from the pool of people"        
        $pool.Remove($left)
        
        ## PickTwo will have 2 pairs, so we will get two random people within the set constraints   
        for ($i=0; $i -lt 2 ; $i++ ) {
            
            ## To satisfy Primary constraint, we need to check both person (left and right of pair)
            ## to make sure not both are primary
            Do {
                if ($left -in $prime) {                             
                    Do {
                        $right = Get-Random -InputObject $pool
                    } while ($right -in $prime)
                } else {                                     
                    $right = Get-Random -InputObject $pool                
                }

                Write-Verbose "Get-Pair: Checking if $left can be paired with $right"
                $Rematch = Check-PreviousPair -left $left -right $right -previousPairs $previousPairs

            } while ($Rematch)

            Write-Verbose "Get-Pair: Pairing result: $left | $right"        
            [PSCustomObject]@{ "LeftPair"=$left ; "RightPair" = $right }                

            Write-Verbose "Get-Pair: Removing $right from the pool of people"
            $pool.Remove($right)
        }        

    }
    #endregion 

    #region handle_even
    ## Below code will handle an even number pairing 
    While ($pool.Count -gt 0) {       
        
        
            ## idea is that we will pop $pool from left (index=0) one by one
            Write-Verbose "Pool size: $($pool.count)"
            $left = $pool[0]            
            $pool.RemoveAt(0)
        
            Write-Verbose "Get-Pair: Left: $left"
            Do {

                ## Check against Prime Constraint
                if ($left -in $prime) {
                    Do {                
                        $right = Get-Random -InputObject $pool
                        Write-Verbose "Get-Pair: Right : $right"
                    
                        $rematch =$false

                        if ($right -in $prime) {
                            Write-Verbose "Get-Pair: Rematch as both $left and $right are in prime list $prime."
                            $rematch = $true
                        }
                    

                    } while ($Rematch)
                } else {
                        $right = Get-Random -InputObject $pool
                        Write-Verbose "Get-Pair: Right : $right"
                }

                ## Check against previous pair constraints 
                Write-Verbose "Get-Pair: Checking if $left can be paired with $right"
                $Rematch = Check-PreviousPair -left $left -right $right -previousPairs $previousPairs

                ## Prevent endless loop as the remaining person is not allowed to be paired as per constraints
                if (($pool.Count -eq 1) -and $Rematch) {

                    Write-Warning "$left and $right are the only two left but constraints do not allow them to be paired"
                    $Rematch = $false   ## We might consider throwing away current pairs, and starting from scratch instead of leaving the last two unpaired
                }
            } while ( $Rematch )

            Write-Verbose "Get-Pair: Removing $right from the pool of people"
            $pool.Remove($right)

            Write-Verbose "Get-Pair: Pairing result: $left | $right"
            [PSCustomObject]@{ "LeftPair"=$left ; "RightPair" = $right }   
        
    }
    #endregion handle_even
}


Function Get-PreviousPair {
<#
    .SYNOPSIS
    Create a hash table where each person is a key, for which value is an array of previously paired people
    
    .EXAMPLE
     PS> $hash
        Name                           Value                                                                            
        ----                           -----                                                                            
        Bezen                          {Robert}                                                                         
        Tom                            {David}                                                                          
        Greg                           {Hazem, Mason} 
    
    .OUTPUT
    [Hashtable]

#>
    param([string]$PreviousPairDirectory)

    $hash=@{}
    Foreach ($file in (Get-ChildItem "$PreviousPairDirectory\pairs_output_*.csv")){
        Write-Verbose "Processing $($file.name)"
        import-csv $file  | foreach {
         # Creating a hashtable of users with the value containing all the previous pairs for that user
            $Hash[$_.LeftPair] +=,$_.RightPair       
            $Hash[$_.RightPair] +=,$_.LeftPair 
        }
    }
    $hash
}


############  main script ########################
# Change this to CSV
## [array]$names = ((Get-Content $path) -split ',').Trim()
[array]$names = Get-Content $UserList


## If we have run before, import those results
if ($PreviousPairDirectory) {

    ## assuming we are saving results to script dir
    $PreviousPair = Get-PreviousPair -PreviousPairDirectory $PreviousPairDirectory -verbose
    Write-Verbose "Previous Pairs"
    If ($VerbosePreference -eq "Continue") {$PreviousPair}
}



## No need to randomize at this stage, as we will do that in the function
## Write-Verbose "Randomizing members"
## $names = Get-Random -InputObject $names -Count $names.Count
$names+='Adil'   ## use to test odd number



if ($names.Count % 2 -eq 0) {
    ## even number
    
    if ($PreviousPair) {
        $paired = Get-Pair -pool $names -previousPairs $PreviousPair  -Verbose
    } else {
        $paired = Get-Pair -pool $names -Verbose
    }
    
} else {
    ## odd number
    
    Write-Warning "Odd number of people, please select a person to have two pals."
    Do  {
             
        ## to do: remove $names, might be too crowded          
        $doubleChooser=Read-Host "Please choose a person to have 2 pals`n $names"
        ## to do: have to do something about case-sensitivity
    } while ($names -cnotcontains $doubleChooser)

        
    if ($PreviousPair) { 
        $paired = Get-Pair -pool $names -pickTwo $doubleChooser -previousPairs $PreviousPair -Verbose
    } else {
        $paired = Get-Pair -pool $names -pickTwo $doubleChooser -Verbose
    }
}

## save to file
$paired |export-csv -NoTypeInformation "$PreviousPairDirectory\pairs_output_$(get-date -format 'yyyyMMdd_HHmmss').csv"
$paired |ft -AutoSize
