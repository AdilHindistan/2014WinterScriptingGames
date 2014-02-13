#Used to verfy True/False entries
$AffNeg = @{
       "True" = "TRUE"
       "False" = "FALSE"
       "" = "FALSE"
}

Write-Verbose "INFO : Pulling in the current calendar list"
Try {
       $ServerList = Import-Csv "D:\Users\John\Documents\GitHub\PhillyPosh\WSG2014_04_Monitoring-Support\requirements\servers.csv" -ErrorAction Stop
}
Catch {
       Write-Warning "Cannot access CSV location"
	   Exit 1
}


Write-Verbose "ACTION : Verifying server list entries"
ForEach ($entry in $ServerList) {
	$BadEntry = $FALSE
    #Verify that server name is a proper DNS name
    If ($entry.server -notmatch "^(?!-)[a-zA-Z0-9-]{1,63}(?<!-)$") {$BadEntry ="Blank server name found"; break}
	#Verify that IP is a proper IP address
    If ($entry.IP -notmatch "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$") {$BadEntry ="Problem entry Server IP : $($entry.IP)"; break}
    <#For the following we are going to assume that 
		any remaning values are true/false
		any blanks are FALSE
		They can be any case
	#>
	#grab all remaining properties
	$TrueFalseProps = $entry | 
						Get-Member -MemberType NoteProperty | 
						Where-Object {($_.Name -ne "Server") -and ($_.Name -ne "IP")} |
						ForEach-Object {$_.name}
	#Verify that they are either true/false or blank
	$TrueFalseProps | ForEach-Object {
		If (-not ($AffNeg.containsKey($entry.$_))) {$BadEntry ="Problem entry for $($entry.server) - $_ : $($entry.$_)"; break}
	}
}
 
If ($BadEntry) {
       Write-Warning "Bad entries found"
	   $BadEntry
}
Else {
       Write-Verbose "CSV file contains no errors"
}
 
