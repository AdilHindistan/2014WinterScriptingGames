#[string[]]$output = @()
#Pull and randomize names
[string[]]$names = get-content "D:\Users\John\Desktop\Winter Scripting games\Event1\Names.txt"
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
			$DoubleTeamLeader = "Enter in team member : "
			While (-not ($names -contains $DoubleTeamLeader)) {
				Write-Warning "User $DoubleTeamLeader not found in list, please try again"
				$DoubleTeamLeader = Read-Host "Enter in team member : "
			}
		}
	}
}
Else {
	$DoubleTeamLeader = ""
}
	
for ($i=0; $i -lt $names.length; $i+=2) {
	$TeamEntry = [pscustomobject]$TeamEntryProperties
	$TeamEntry.leader = $names[$i]
	$TeamEntry.Subordinate = $names[$i+1]
	#"$($names[$i]),$($names[$i+1])"
	$TeamList += $TeamEntry
}

If ($DoubleTeamLeader) {
	$CurrentSub = ($TeamList | Where-Object {$_.Leader -eq $DoubleTeamLeader}).Subordinate   
	$OddGroup = $names | 
					Get-Random -count $names.Count |
					Where-Object {($_ -ne $DoubleTeamLeader) -and ($_ -ne $CurrentSub)} |
					Select-Object -First 1
	$TeamList[-1].Subordinate = $OddGroup
	#"$OddGroup"
}






