﻿#requires -version 3.0

[CMDLETBINDING()]
Param(
        [Parameter(Mandatory=$false,Position=1)] 
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})] 
        [String]$UserList = "$pwd\names3.txt",
        
        [Parameter(Mandatory=$False,Position=2)]
        [ValidateScript({Test-Path "$_\pairs_output_*.csv"})]
        [String]$PreviousPairDirectory = "$pwd",
    
        [Parameter(Mandatory=$False,Position=3)] 
        [ValidateCount(0,5)]        
        [string[]]$primary =@('Sunny','David','Julie') ## Need to validate these names are in $UserList
)

        
Function Import-PreviousPair {
<#
    .SYNOPSIS
    Imports the previous pairs to check against

    .DESCRIPTION
    Reads previous outputs of the script to import back previously paired people lists and store them to comply with pairing constraints.

    .NOTES
    Create a hash table where each person is a key, for which value is an array of previously paired people
    
    .EXAMPLE
     PS> $hash
        Name                           Value                                                                            
        ----                           -----                                                                            
        Bezen                          {Robert}                                                                         
        Tom                            {David}                                                                          
        Greg                           {Hazem, Mason} 
        ...                            {.....,...,...}

        In the example above, first two person has paired with one other person, while Greg has paired with two, Hazem and Mason
        According to rules Greg should not be able to pair with either until he has matched with at least 4 others
    
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

Function Check-PreviousPair {
<#
    .SYNOPSIS
    Check if pair satisfy constraints for previous pairs

    .DESCRIPTION
    It checks whether the passed pair satisfy "no two people should pair unless paired with at least 4 other" constraint or not

    
#>
    param (
            [Parameter(mandatory)]
            [string]$left,
            
            [Parameter(mandatory)]
            [string]$right,
            
            [Parameter(mandatory)]
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

Function Get-PairForPrime {
    <#
        .SYNOPSIS
        Get a pair for each primary

        .DESCRIPTION
        Gets a random person as pair of a designated primaries satisfying the "no two primaries should pair" constraint.
        
    #>

    param (
        [Parameter(Mandatory)]
        [System.Collections.ArrayList]$pool,
        
        [string[]]$prime,
        [hashtable]$previousPairs
    )

    Write-Verbose "Get-PairForPrime: pool count $($pool.Count)"                
    Foreach ($left in $prime) {
        Do {
            $Rematch = $false
            $right = Get-Random -InputObject $pool
            
            ## We will also make sure pair satisfy 'previous pair constraints' if there are any            
            if ($previousPairs) {

                Write-Verbose "Get-PairForPrime: Checking if $left can be paired with $right"                
                $Rematch = Check-PreviousPair -left $left -right $right -previousPairs $previousPairs -verbose

               ## Removing $right at this point would give some benefits:
               ## Get-Random may just get a person again and again that does not satisfy previous-pair-constraints 
               # Write-Verbose "Get-PairForPrime: Removing $right from available name pool"
               # $pool.Remove($right)

                Write-Verbose "Get-PairForPrime: pool count $($pool.Count)" 
            }
        
        } While ($Rematch)

        ## Removing it at this point 
        Write-Verbose "Get-PairForPrime: Removing $right from available name pool"
        $pool.Remove($right)
        
        Write-Verbose "Get-PairForPrime: Pairing result: $left | $right"        
        
        [PSCustomObject]@{ "LeftPair"=$left ; "RightPair" = $right }  

    }
    Write-Verbose "Get-PairForPrime: pool count $($pool.Count)"                
}

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
        
        [string]$doubleChooser,
        
        [ValidateRange(1,2)]
        [int]$pick,

        [hashtable]$previousPairs
    )

        ## we will always remove the users we are pairing or paired from the pool of $pool 
        ## so that they do not come up as a result of get-random    
        $left = $doubleChooser
        
        Write-Verbose "Get-PairForOdd: Removing $left from the pool of available people"        
        $pool.Remove($left)

        Write-Verbose "Get-PairForOdd: $left will pick $pick from available people"                        
        for ($i=0; $i -lt $pick ; $i++ ) {
            
            Do {
                
                $Rematch = $false    
                $right = Get-Random -InputObject $pool                
                if ($previousPairs) {
                    Write-Verbose "Get-PairForOdd: Checking if $left can be paired with $right"
                    $Rematch = Check-PreviousPair -left $left -right $right -previousPairs $previousPairs -verbose
                }
    
                Write-Verbose "Get-PairForOdd: Removing $right from the pool of people"
                $pool.Remove($right)


            } while ($Rematch)

            Write-Verbose "Get-PairForOdd: Pairing result: $left | $right"        
            [PSCustomObject]@{ "LeftPair"=$left ; "RightPair" = $right }                

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
            $pool.RemoveAt(0)
        
            Write-Verbose "Get-PairForEven: Left: $left"
            Do {
                
                $Rematch = $false
                $right = Get-Random -InputObject $pool
                Write-Verbose "Get-PairForEven: Right : $right"

                if ($previousPairs) {
                    Write-Verbose "Get-PairForEven: Checking if $left can be paired with $right"
                    $Rematch = Check-PreviousPair -left $left -right $right -previousPairs $previousPairs  -verbose
                }

                ## Prevent endless loop as the remaining person is not allowed to be paired as per constraints
                if (($pool.Count -eq 1) -and $Rematch) {

                    Write-Warning "$left and $right are the only two left but constraints do not allow them to be paired" 
                    $Rematch = $false   ## We might consider throwing away current pairs, and starting from scratch instead of leaving the last two unpaired
                }

            } while ( $Rematch )

            Write-Verbose "Get-PairForEven: Removing $right from the pool of people"
            $pool.Remove($right)

            Write-Verbose "Get-PairForEven: Pairing result: $left | $right"
            [PSCustomObject]@{ "LeftPair"=$left ; "RightPair" = $right }   
        
    }

}

############  Main Script ########################

## To do: Handle import from csv (name,email)
## [array]$names = ((Get-Content $path) -split ',').Trim()
[String[]]$emails = Get-Content $UserList 
## assuming
Get-Content $UserList | % { $Email=@{}}{ $Email[($_ -split ',')[0]]=($_ -split ',')[1]}
$Names=@($Email.Keys)
#<<<<<<< HEAD
$gamesName = "WSG2014_Event1_Pairs"
$transcriptPath = "$pwd\$gamesName.txt"
#Start-Transcript -Path $transcriptPath
#=======
#>>>>>>> 272ec6082f0b3bbd86a8a24d3158b0408aed3131

[System.Collections.ArrayList]$AvailablePool=$Names

## If we have run the script to pair people before, import those results
if ($PreviousPairDirectory) {

    ## assuming we are saving results to script dir
    $PreviousPair = Import-PreviousPair -PreviousPairDirectory $PreviousPairDirectory -verbose
    
    If (($VerbosePreference -eq "Continue") -and ($PreviousPair)) {
        Write-Verbose "Previous Pairs"
        $PreviousPair
    }
}


Write-Verbose "Available pool: $($AvailablePool.count)"

#region handle_primes

if ($primary) {

    Foreach ($p in $primary) {
        if ($p -notin $Names) { 
            Write-Warning "Primary $p is not in the provided name list. Exiting"
            Exit
        }
    }

    Write-Verbose "Removing primes from available name pool as they cannot pair with each other"    
    Foreach ($member in $primary) {             
            Write-Verbose "Removing $member" 
            $AvailablePool.Remove($member) 
    }
    Write-Verbose "Available Pool: $($AvailablePool.Count)"

    Write-Verbose "Get Pairs for Primes"
    If ($PreviousPairDirectory) {
        
        Write-Verbose "Pair output exists, need to check for previous pairs"
        $PrimePair = Get-PairForPrime -pool $AvailablePool -prime $primary -previousPairs $PreviousPair -verbose
    
    } else {
        
        Write-Verbose "No previous pairs"
        $PrimePair = Get-PairForPrime -pool $AvailablePool -prime $primary -verbose
    }

    Write-Verbose "We will now remove members of PrimePair from available name pool in the main script"
    Write-Verbose "Available Pool: $($AvailablePool.Count)"
    foreach ($member in $PrimePair.RightPair) {
        Write-Verbose "Removing $member from available name pool"
        $AvailablePool.Remove($member)
    }
    Write-Verbose "Available pool: $($AvailablePool.count)"
    
    $AllPairs=$PrimePair
}
#endregion handle_primes



#region handle_odd_number
if ($names.Count % 2 -ne 0) {
    ## odd number
    
    Write-Warning "Odd number of people, please select a person to have two pals. $($names.count)"
    Do  {             
        
        # $doubleChooser=Read-Host "Please choose a person to have 2 pals`n $names"
        #$doubleChooser = $names |Out-GridView -OutputMode Single -Title "Odd number of people, please select a person to have two pals." 
        #OGV for Primary Chooser
           
    } while (!$doubleChooser)

    
    Write-Verbose "Removing $doubleChooser from available name pool"
    $AvailablePool.Remove($doubleChooser)


    if (($doubleChooser -in $primary) -or ($doubleChooser -in $PrimePair.RightPair)) {
    
        ## This person was already paired during Primary Pairing before but this person has to be paired with an additional person
        ## We still need to make sure the new pair satisfy pairing constraints

        $OddPair = Get-PairForOdd -pool $AvailablePool -doubleChooser $doubleChooser -previousPairs $PreviousPair -pick 1 -verbose
        
    } else {
        
        ## This person is not a primary, which means it needs to be paired with two other people
        $OddPair = Get-PairForOdd -pool $AvailablePool -doubleChooser $doubleChooser -previousPairs $PreviousPair -pick 2 -verbose
                
    }
    
    ## We can now remove oddpair members from the available name pool
    Foreach ($member in $OddPair.RightPair) {

            Write-Verbose "Removing $member from available name pool"
            $AvailablePool.Remove($member)
        
    }

    $AllPairs += $oddpair | % {$_}
}
#endregion handle_odd_number


## even number   
if ($PreviousPairDirectory) {
    $EvenPair = Get-PairForEven -pool $AvailablePool -previousPairs $PreviousPair  -Verbose
} else {
    $EvenPair = Get-PairforEven -pool $AvailablePool -Verbose
}

$AllPairs +=$EvenPair | % {$_}

#region output
$Outputfile = "$PreviousPairDirectory\pairs_output_$(get-date -format 'yyyyMMdd_HHmmss').csv"

$AllPairs |export-csv -NoTypeInformation -Path $Outputfile
$AllPairs |Format-Table -AutoSize

"Results are written to $Outputfile"
Stop-Transcript 
#endregion output