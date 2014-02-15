#Used to verfy True/False entries
$VerfiyTable = @{
       "True" = "TRUE"
       "False" = "FALSE"
       "" = ""
}

#Used to hold any bad entires found with a description of why they were bad
$BadEntryList = @()

Write-Verbose "INFO : Pulling in the current calendar list"
Try {$ServerList = Import-Csv "D:\Users\John\Documents\GitHub\PhillyPosh\WSG2014_04_Monitoring-Support\test\servers_badentries.csv" -ErrorAction Stop}
Catch {
       Write-Warning "Cannot access CSV location"
	   Exit 1
}

#Create list of IP's and Servers to test for dupes
#Not sure if there a cost time wise to using the Automatic foreach in a loop, just to be safe we are going to do it once
$FullIPList = $ServerList.IP
$FullServerlist = $ServerList.server

Write-Verbose "ACTION : Verifying server list entries"
ForEach ($entry in $ServerList) {
	$BadEntryReason = ""
    #Verify that no duplicates server names or IPs exist
	If (($FullServerlist -match $entry.Server).count -gt 1) {$BadEntryReason += "Duplicate server name in list`n"}
	If (($FullIPList -match $entry.IP).count -gt 1) {$BadEntryReason += "Duplicate IP in list`n"}
	#Verify that server name is a proper DNS name
    If ($entry.server -notmatch "^(?!-)[a-zA-Z0-9-]{1,63}(?<!-)$") {$BadEntryReason += "Server name is not a proper DNS name`n"}
	#Verify that IP is a proper IP address
    If ($entry.IP -notmatch "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$") {$BadEntryReason += "IP address is malformed`n"}
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
		If (-not ($VerfiyTable.containsKey($entry.$_))) {$BadEntryReason += "Setting $_ is not True, False, Or blank`n"}
	}
	#If one or more bad entries are found add the reason to the entry and the bad entry list
	If ($BadEntryReason) {$BadEntryList += ($entry | Add-Member -MemberType NoteProperty -Name "BadEntryReason" -Value $BadEntryReason -PassThru)}
}
 
If ($BadEntryList) {
       Write-Warning "Bad Entries found, removing them from the list"
	   $Serverlist = $Serverlist | Where-Object {$_.Server -notin $BadEntryList.Server}
}
Else {Write-Verbose "CSV file contains no errors"}


 
