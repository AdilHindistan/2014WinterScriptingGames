#requires -version 3.0

[CMDLETBINDING()]
Param(
    [Parameter(Mandatory=$false,Position=1)] 
	[ValidateScript({Test-Path $_ -PathType 'Leaf'})] 
	[String]$UserList = "D:\Users\John\Documents\GitHub\PhillyPosh\WSG2014_01_Pairs\adil\names3.txt",
	
	[Parameter(Mandatory=$False,Position=2)]
	[ValidateScript({Test-Path "$_\pairs_output_*.csv"})]
	[String]$PreviousPairDirectory = "D:\Users\John\Documents\GitHub\PhillyPosh\WSG2014_01_Pairs\adil",
    
	[Parameter(Mandatory=$False,Position=3)] 
	[string[]]$primary#=@("Sunny","David","John","Adil")
)

#region Helper Functions
Function Get-Pair {
    param(
        [Parameter(Mandatory)]
        [System.Collections.ArrayList]$users,
        [string]$pickTwo,
        [string[]]$prime=@('AndY','haZEM','BeZEN','JULIE'),
        [hashtable]$previousMatches
    )

    
    
    ## This part of code handles odd case, where one person is matched to two pals
    if ($pickTwo) {  
    
        ## we will always remove the users we are pairing or paired from the pool of $users 
        ## so that they do not come up as a result of get-random    
        $users.Remove($pickTwo)
        
        ## PickTwo will have 2 pairs, so we will get two random people within the set constraints   
        for ($i=0; $i -lt 2 ; $i++ ) {
            
            ## To satisfy Primary constraint, we need to check both person (left and right of pair)
            ## to make sure not both are primary
            if ($pickTwo -in $prime) {                             
                Do {
                    $right = Get-Random -InputObject $users
                } while ($right -in $prime)
            } else {                                     
                $right = Get-Random -InputObject $users                
            }

            Write-Verbose "Match result: $pickTwo v $right"        
            [PSCustomObject]@{ "LeftPair"=$pickTwo ; "RightPair" = $right }                

            Write-Verbose "Removing $right from the pool of people"
            $users.Remove($right)
        }        

    }

    ## Below code will handle an even number pairing 
    While ($users.Count -gt 0) {
    
                    
        $left = $users[0]
        Write-Verbose "Set left to $left UserCount: $($users.count)"
        $users.RemoveAt(0)
        
        Do {

            ## Check against Prime Constraint
            if ($left -in $prime) {
                Do {                
                    $right = Get-Random -InputObject $users
                    Write-Verbose "right : $right"
                    
                    $rematch =$false

                    if ($right -in $prime) {
                        Write-Verbose "Rematch as both $left and $right are in prime list $prime."
                        $rematch = $true
                    }
                    

                } while ($Rematch)
            } else {
                    $right = Get-Random -InputObject $users
                    Write-Verbose "right : $right"
            }


            ## Check against previous matches contstraint
            $previouslyMatched = $previousMatches[$left]            
            $Rematch = $false
            if ($right -in $previouslyMatched) {
                
                Write-Verbose "$left matched $right before! Additional checks needed."

                if ($previouslyMatched.Count -gt 4) {
                    write-verbose "$left matched at least 4 other people before, OK to match them again"
                    
                    $Rematch = $false

                } else {
                    Write-Verbose "$left has not yet match 4 other people, we will pair with someone else"
                    $Rematch = $true
                    ## todo : edge case, what if there is a prime vs prime left?
                }            
            }
        } while ( $Rematch )

        Write-Verbose "Removing $right from the pool of people"
        $users.Remove($right)

        Write-Verbose "Match result: $left | $right"
        [PSCustomObject]@{ "LeftPair"=$left ; "RightPair" = $right }   
    
    }

}
#endregion

Function Get-PreviousPair {
    
    $hash=@{}
    Foreach ($file in (Get-ChildItem "$PreviousPairDirectory\pairs_output_*.csv")){
        Write-Verbose "Processing $($file.name)"
        import-csv $file  | foreach {
            #Creating a hashtable of users with the vaulue containing all the previous matchs for that user
			$Hash[$_.LeftPair] +=,$_.RightPair       
            $Hash[$_.RightPair] +=,$_.LeftPair 
        }
    }
    $hash
}


############  main script ########################
#Change this to CSV
[array]$names = Get-Content $UserList

## If we have run before, import those results
#if (test-path "$PreviousPairDirectory\pairs_output_*.csv") {
if ($PreviousPairDirectory) {
    ## assuming we are saving results to script dir
    $PreviousPair = Get-PreviousPair -verbose
    Write-Verbose "Previous Pairs"
    If ($VerbosePreference -eq "Continue") {$PreviousPair}
}



## No need to randomize at this stage, as we will do that in the function
## Write-Verbose "Randomizing members"
## $names = Get-Random -InputObject $names -Count $names.Count
#$names+='Adil'   ## use to test odd number



if ($names.Count % 2 -eq 0) {
    ## even number
    Write-Verbose "Members are even"
    if ($PreviousPair) {
        $paired = Get-Pair -users $names -previousMatches $PreviousPair  -Verbose
    } else {
        $paired = Get-Pair -users $names -Verbose
    }
    
} else {
    ## odd number
    
        Write-Warning "Odd number of people, please select a person to have two pals."
        Do  {
             
            ## to do: remove $names, might be too crowded          
            $doubleChooser=Read-Host "Please choose a person to have 2 pals $names"
            ## to do: have to do something about case-sensitivity
        } while ($names -cnotcontains $doubleChooser)
        
        if ($PreviousPair) { 
            $paired = Get-Pair -users $names -pickTwo $doubleChooser -previousMatches $PreviousPair -Verbose
        } else {
            $paired = Get-Pair -users $names -pickTwo $doubleChooser -Verbose
        }
}

## save to file
#$paired |export-csv -notypeinformation "$PreviousPairDirectory\pairs_output_$(get-date -format 'yyyyMMdd_HHmmss').csv"
$paired |ft -AutoSize

