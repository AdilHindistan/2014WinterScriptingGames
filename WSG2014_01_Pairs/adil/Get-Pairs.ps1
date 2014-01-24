#requires -version 3.0

[CMDLETBINDING()]
Param(
    $path = "${pwd}\names.txt",
    [string[]]$primary#=@("Sunny","David","John","Adil")
)


Function Check-PreviousMatch {
<#
    .SYNOPSIS
    Check if pair satisfy constraints for previous matches
#>
    param (
            [string]$left,
            [string]$right,
            [hashtable]$previousMatches
    )

     ## Check against previous matches contstraint
    $previouslyMatched = $previousMatches[$left]                
    if ($right -in $previouslyMatched) {
                
        Write-Verbose "Check-IsPreviousMatch: $left matched $right before! Additional checks needed."

        if ($previouslyMatched.Count -gt 4) {
            write-verbose "Check-IsPreviousMatch: $left matched at least 4 other people before, OK to match them again"                    
            $false

        } else {
            Write-Verbose "Check-IsPreviousMatch: $left has not yet match 4 other people, we will pair with someone else"
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
        [hashtable]$previousMatches
    )

    Write-Verbose "Get-Pair: pool size: $($pool.count)"        
    #region handle_odd
    ## This part of code handles odd case, where one person is matched to two pals
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
                $Rematch = Check-PreviousMatch -left $left -right $right -previousMatches $previousMatches

            } while ($Rematch)

            Write-Verbose "Get-Pair: Match result: $left | $right"        
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

                ## Check against previous match constaints 
                Write-Verbose "Get-Pair: Checking if $left can be paired with $right"
                $Rematch = Check-PreviousMatch -left $left -right $right -previousMatches $previousMatches

            } while ( $Rematch )

            Write-Verbose "Get-Pair: Removing $right from the pool of people"
            $pool.Remove($right)

            Write-Verbose "Get-Pair: Match result: $left | $right"
            [PSCustomObject]@{ "LeftPair"=$left ; "RightPair" = $right }   
        
    }
    #endregion handle_even
}


Function Get-PreviousPair {
    
    $hash=@{}
    Foreach ($file in (Get-ChildItem "$pwd\pairs_output_*.csv")){
        Write-Verbose "Processing $($file.name)"
        import-csv $file  | foreach {
            $Hash[$_.LeftPair] +=,$_.RightPair       
            $Hash[$_.RightPair] +=,$_.LeftPair 
        }
    }
    $hash
}


############  main script ########################
#Change this to CSV
[array]$names = ((Get-Content $path) -split ',').Trim()

## If we have run before, import those results
if (test-path "$pwd\pairs_output_*.csv") {

    ## assuming we are saving results to script dir
    $PreviousPair = Get-PreviousPair -verbose
    Write-Verbose "Previous Pairs"
    $PreviousPair
}



## No need to randomize at this stage, as we will do that in the function
## Write-Verbose "Randomizing members"
## $names = Get-Random -InputObject $names -Count $names.Count
# $names+='Adil'   ## use to test odd number



if ($names.Count % 2 -eq 0) {
    ## even number
    
    if ($PreviousPair) {
        $paired = Get-Pair -pool $names -previousMatches $PreviousPair  -Verbose
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
        $paired = Get-Pair -pool $names -pickTwo $doubleChooser -previousMatches $PreviousPair -Verbose
    } else {
        $paired = Get-Pair -pool $names -pickTwo $doubleChooser -Verbose
    }
}

## save to file
$paired |export-csv -notypeinformation "${pwd}\pairs_output_$(get-date -format 'yyyyMMdd_HHmmss').csv"
$paired |ft -AutoSize

