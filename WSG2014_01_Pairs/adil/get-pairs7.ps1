#requires -version 3.0

<#
    .Synopsis
       Creates pairs of names from a supplied list

    .DESCRIPTION
       The Get-Pairs.ps1 script when run without any parameters will search the current directory for a list of names and pair them.
       The script assumes that the initial series of names will be provided as names.txt file in the current working directory.
       If the list of names are odd, it prompts the user to select the name that will be paired more than once.
       When executed with the -primary switch, the script will first match the primary names.
       It also checks that people are not repeatedly matched during subsequent runs of the script 


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
        [String]$UserList = "$pwd\names.csv",
        
        [Parameter(Position=2)]
        [ValidateScript({Test-Path "$_\pairs_output_*.csv"})]
        [String]$PreviousPairDirectory = "$pwd",
    
        [Parameter(Position=3)] 
        [ValidateCount(0,5)]        
        [string[]]$primary #=@('Josh','David','Julie') ## Need to validate these names are in $UserList
)

#region Helper-Functions
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
            }
        
        } While ($Rematch)        

        
        Write-Verbose "Get-PairForPrime: Pairing result: $left | $right"                
        [PSCustomObject]@{ "LeftPair"=$left ; "RightPair" = $right }  
        
        Write-Verbose "Get-PairForPrime: Removing $right from available name pool"
        [void]$pool.Remove($right)
        
        Write-Verbose "Get-PairForPrime: pool count $($pool.Count)" 

    }                   
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

        Write-Verbose "Get-PairForOdd: $left will pick $pick from available people"                        
        for ($i=0; $i -lt $pick ; $i++ ) {
            
            Do {
                
                $Rematch = $false    
                $right = Get-Random -InputObject $pool                
                if ($previousPairs) {
                    Write-Verbose "Get-PairForOdd: Checking if $left can be paired with $right"
                    $Rematch = Check-PreviousPair -left $left -right $right -previousPairs $previousPairs -verbose
                }
    

            } while ($Rematch)
            
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

                    Write-Warning "$left and $right are the only two left but constraints do not allow them to be paired. Exiting" 
                    Exit
                    ##$Rematch = $false   ## We might consider throwing away current pairs, and starting from scratch instead of leaving the last two unpaired                    
                }

            } while ( $Rematch )

            Write-Verbose "Get-PairForEven: Pairing result: $left | $right"
            [PSCustomObject]@{ "LeftPair"=$left ; "RightPair" = $right }   

            Write-Verbose "Get-PairForEven: Removing $right from the pool of people"
            [void]$pool.Remove($right)

        
    }

}

Function Send-PairEmail {
[CmdletBinding()]
Param 
   ([String]$To, 
    [String]$From ="sunny.chakraborty@aberdeen-asset.com",
    [String]$CC = "sunny_c7@yahoo.com",
    [String]$Subject,    
    [String]$Body,
    [String]$SmtpServer = "usmail"
    )

$Splat = @{
To = $To
From = $From
CC = $CC
Subject = $Subject
SmtpServer = $SmtpServer
Body =$Body
}

    Send-MailMessage @Splat
    
}

#endregion

## To do: Handle import from csv (name,email)
## [array]$names = ((Get-Content $path) -split ',').Trim()
## [String[]]$emails = Get-Content $UserList 

# MAIN
#
$names = @()
$inputData = import-csv $UserList 
$inputData | foreach {$names += $_.Names}

[System.Collections.ArrayList]$AvailablePool=$Names
$AllPairs=@()

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

    ##Handle the case where supplied primary is NOT in the supplied user list
    Foreach ($p in $primary) {
        if ($p -notin $Names) { 
            Write-Warning "Primary $p is not in the provided name list."            
            $reselectPrimary = $true
            break
        }
    }

    if (([math]::Floor($($names.Count/2)) -lt $Primary.count)) { 
        $reselectPrimary = $true
    }
    
    if ($reselectPrimary) {
        $PrimaryMax = 5
        $title = "Select up to $PrimaryMax people"
        do {
             [String[]]$Primary = $Names |Out-GridView -OutputMode Multiple -Title $title
            $title = "You cannot select more than half of the people as primary. Limit your selection to $PrimaryMax people or less than half"
        } until (([math]::Floor($($names.Count/2)) -ge $Primary.count) -and ($Primary.count -le $PrimaryMax))
    }
    

    Write-Verbose "Removing primes from available name pool as they cannot pair with each other"    
    
    Foreach ($member in $primary) {             
            Write-Verbose "Removing $member" 
            $AvailablePool.Remove($member) 
    }
    Write-Verbose "Available Pool: $($AvailablePool.Count)"

    Write-Verbose "Get Pairs for Primaries"
    If ($PreviousPairDirectory) {
        
        Write-Verbose "PreviousPairDirectory exists, need to check for previous pairs"
        $PrimePair = Get-PairForPrime -pool $AvailablePool -prime $primary -previousPairs $PreviousPair -verbose
    
    } else {
        
        Write-Verbose "No previous pairs"
        $PrimePair = Get-PairForPrime -pool $AvailablePool -prime $primary -verbose
    }
    
    
    $AllPairs+=$PrimePair
}
#endregion handle_primes



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


    if (($doubleChooser -in $primary) -or ($doubleChooser -in $PrimePair.RightPair)) {
    
        ## This person was already paired during Primary Pairing before but this person has to be paired with an additional person
        ## We still need to make sure the new pair satisfy pairing constraints

        $OddPair = Get-PairForOdd -pool $AvailablePool -doubleChooser $doubleChooser -previousPairs $PreviousPair -pick 1 -verbose
        
    } else {
        
        ## This person is not a primary, which means it needs to be paired with two other people
        $OddPair = Get-PairForOdd -pool $AvailablePool -doubleChooser $doubleChooser -previousPairs $PreviousPair -pick 2 -verbose
                
    }    

    $AllPairs += $oddpair | % {$_}
}
#endregion handle_odd_number

#region hand_even_number if any people left
if ($AvailablePool.count -ge 2) {
    if ($PreviousPairDirectory) {
        $EvenPair = Get-PairForEven -pool $AvailablePool -previousPairs $PreviousPair  -Verbose
    } else {
        $EvenPair = Get-PairforEven -pool $AvailablePool -Verbose
    }
    
    $AllPairs +=$EvenPair | % {$_}
}

#region output
$Outputfile = "$PreviousPairDirectory\pairs_output_$(get-date -format 'yyyyMMdd_HHmmss').csv"

"Results are written to $Outputfile"
$AllPairs |export-csv -NoTypeInformation -Path $Outputfile

#Send Email to Pairs

#Pick the latest AllPairs Result
$pairedResult = (gci -Path "$pwd\pairs_output_*.csv" | sort LastWriteTime | select -First 1).FullName | Import-Csv

#Create a new Object of Matches and their email addrss to Email
$new = "" | Select Name,Match,Email

    foreach ($item in $pairedResult) {
        $new.Name = $item.LeftPair
        $new.Match = $item.RightPair
        $new.Email = ($inputData | where {$_.names -Like $item.LeftPair} | Select EmailAddress).EmailAddress
        $new | export-csv -NoTypeInformation ReportForEmail.csv -Append
        }
    foreach ($item in $pairedResult) {
        $new.Name = $item.RightPair
        $new.Match = $item.LeftPair
        $new.Email = ($inputData | where {$_.names -Like $item.LeftPair} | Select EmailAddress).EmailAddress
        $new | export-csv -NoTypeInformation "$pwd\ReportForEmail.csv" -Append
        }
$x = Import-Csv "$pwd\ReportForEmail.csv" 
foreach ($item in $x){
$Body = @"
    Hi $($item.Name)
    Welcome to the automated Pair matching System.
    You are paired with $($item.Match)

    Thank You.
"@
    
    $obj = @{
    To = $($item.Email)
    Body = $Body
    Subject= "Your pairing details".ToString()
}

"Sending emails to $($item.Name)"
Send-PairEmail @obj
}

#endregion output
