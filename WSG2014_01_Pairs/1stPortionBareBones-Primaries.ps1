<#Pull and randomize names
This is a csv with a name, email, and Primary colomun which is left blank if they are not a primary and filled in 
with anything if they are 
#>
$Names = Import-Csv -Path "D:\Users\John\Desktop\Winter Scripting games\Event1\Names.csv" -Header Name,Email,Primary
$names = $names | 
			Get-Random -count $names.Count

#Create Table to hold team list
$TeamList = @()
#Properties for team entery custom object
$TeamEntryProperties = @{
	"leader" = ""
	"Subordinate" = ""
}

#Odd handler
if ($names.Count % 2) {
	$OddAnswer = Read-Host "Odd number of people, continue? Y for yes, N for no"
	If ($OddAnswer -ne "Y") {
		Write-Output "Script execution canceled"
		exit 0
	}
	Else {
		$DoubleTeamLeader = ""
		$RandomAnswer = Read-Host "Assign a random user 2 team members? Y for yes, N for no"
		If ($RandomAnswer -eq "y") {
			$DoubleTeamLeader = $names | 
									Get-Random -count 1
		}
		Else {
			$DoubleTeamLeader = Read-Host "Enter in team member : "
			While (-not ($Names.Name -contains $DoubleTeamLeader)) {
				Write-Warning "User $DoubleTeamLeader not found in list, please try again"
				$DoubleTeamLeader = Read-Host "Enter in team member : "
			}
		}
	}
	#Move the double team leader to the top of list so we don't have a situation where they are the last odd entry as well
	$FirstEntry = $names | Where-Object name -eq $DoubleTeamLeader
	[System.Collections.ArrayList]$names = $names | Where-Object name -ne $DoubleTeamLeader
	$Names.Insert(0,$FirstEntry)
}
Else {
	$DoubleTeamLeader = ""
}

#Because I'm worried about ending up in a situation where I matched everyone and only have primaries left
#I'm taking care of them first
$Primaries = ($names | Where-object Primary).Name
[System.Collections.ArrayList]$NonPrimaries = ($names | Where-object {-not $_.Primary}).Name
If ($Primaries.Count -gt $NonPrimaries.Count) {
	Write-Warning "too many primaries, please re-run with less primaries or more non primaries"
	exit 1
}
								
Foreach ($Primary in $Primaries) {
	$TeamEntry = [pscustomobject]$TeamEntryProperties
	$TeamEntry.leader = $Primary
	$TeamEntry.Subordinate = $NonPrimaries[0]
	$TeamList += $TeamEntry
	$NonPrimaries.RemoveAt(0)
}

for ($i=0; $i -lt $NonPrimaries.count; $i+=2) {
	$TeamEntry = [pscustomobject]$TeamEntryProperties
	$TeamEntry.leader = $NonPrimaries[$i]
	$TeamEntry.Subordinate = $NonPrimaries[$i+1]
	$TeamList += $TeamEntry
}

If ($DoubleTeamLeader) {
	#Since we populate the Leader first in the pevious loop, we need to swap those since we specify the Double Team leader
	$TeamList[-1].Subordinate = $TeamList[-1].Leader
	#Look for the Double team leaders current sub
	$CurrentSub = ($TeamList | Where-Object {$_.Leader -eq $DoubleTeamLeader}).Subordinate   
	#Pull a random user who isn't the double team lead and their current subordinate
	$OddSub = ($names | 
					Get-Random -count $names.Count |
					Where-Object {($_ -ne $DoubleTeamLeader) -and ($_ -ne $CurrentSub)} |
					Select-Object -First 1).Name
	$TeamList[-1].Subordinate = $OddSub
}






