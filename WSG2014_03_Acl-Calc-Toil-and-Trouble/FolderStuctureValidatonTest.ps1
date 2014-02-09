#Taken from http://stackoverflow.com/questions/12412500/powershell-only-recurse-subfolder-x-number-of-level
function TraverseFolders($folder, $remainingDepth) {
  #Get Any non directory files in the folder
  Get-ChildItem $folder -File
  #Proceed to the next folder
  Get-ChildItem $folder -Directory | 
 	ForEach-Object {
    	if ($remainingDepth -gt 1) {
      		TraverseFolders $_.FullName ($remainingDepth - 1)
    	}
  	}
}


#$RootShare = "D:\Users\John\Desktop\Winter Scripting games\Event3\Share"
$RootShare = "$PSScriptRoot\share"

$FoldersInRootShare = Get-ChildItem $RootShare -Directory

#Pull all files found on the root of the share, in the department folder, and in the team folders
# and report on them
$RootFiles = TraverseFolders -folder $RootShare -remainingDepth 3

#List of folders that aren't in the defined folder structure
$BadFolders = @()
#List of folders defined in the folder structure that are missing
$MissingFolders = @()
#Template for the 3 folders found in every team folder
$RequiredFoldersTemplate = New-Object System.Collections.ArrayList
$RequiredFoldersTemplate.add("$($SubFolder.Name) Shared") | Out-Null
$RequiredFoldersTemplate.add("$($SubFolder.Name) Private") | Out-Null
$RequiredFoldersTemplate.add("$($SubFolder.Name) Lead") | Out-Null

#Look ofr missing folders and folders that don't match the standard
Foreach ($folder in $FoldersInRootShare) {
	#Look for the Open folder in the current department directory and report if missing
	if (-not (Get-ChildItem $folder.FullName -Directory -filter "$($folder.Name) Open")) {
		$MissingFolders += "$($folder.FullName) Open"
	}
	#Pull a list of all the team folders that aren't the open folder
	$InvidualDeptFolders = Get-ChildItem $folder.FullName -Directory -Exclude "$($folder.Name) Open"
	Foreach ($DeptSubFolder in $InvidualDeptFolders) {
		#Get all the team subfolders
		$TeamFolders = Get-ChildItem $DeptSubFolder.FullName
		$RequiredFolders = $RequiredFoldersTemplate.clone()
		#Look through the folders and report on folders that don't match the standard
		#Remove the folders that match the standarf from the template array
		foreach ($TeamSubFolder in $TeamFolders) {
				if ($RequiredFolders -notcontains $TeamSubFolder.Name) {
					$BadFolders += $TeamSubFolder
				}
			Else {$RequiredFolders.Remove($TeamSubFolder.Name)}
		}
		#If any required folders are not found then add them to the missing folder list
		If ($RequiredFolders.count -gt 1) {
		$RequiredFolders | 
			Foreach-object {$MissingFolders += $_}
		}	
	}
}

#Root folder template
$BadPerms = @()

#PermissionCheck
Foreach ($folder in $FoldersInRootShare) {
	[Array]$PermSet = (Get-Acl $folder.FullName).Access
	$BadPerms = $PermSet | Where-Object {($_.IdentityReference -ne "Everyone") }
}
	