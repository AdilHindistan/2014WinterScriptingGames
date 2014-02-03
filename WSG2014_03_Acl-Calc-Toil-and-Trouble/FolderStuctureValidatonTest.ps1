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


$RootShare = "D:\Users\John\Desktop\Winter Scripting games\Event3\Share"
$FoldersInRootShare = Get-ChildItem $RootShare -Directory

$RootFilestest = Get-ChildItem -Path $RootShare -Recurse -File

$RootFiles = TraverseFolders -folder $RootShare -remainingDepth 3


$BadFolders = @()
$MissingFolders = @()
$RequiredFoldersTemplate = New-Object System.Collections.ArrayList
$RequiredFoldersTemplate.add("$($SubFolder.Name) Shared") | Out-Null
$RequiredFoldersTemplate.add("$($SubFolder.Name) Private") | Out-Null
$RequiredFoldersTemplate.add("$($SubFolder.Name) Lead") | Out-Null

Foreach ($folder in $FoldersInRootShare) {
	if (-not (Get-ChildItem $folder.FullName -Directory -filter "$folder Open")) {
		$MissingFolders += "$($folder.FullName) Open"
	}
	$InvidualDeptFolders = Get-ChildItem $folder.FullName -Directory -Exclude "$folder Open"
	Foreach ($DeptSubFolder in $InvidualDeptFolders) {
		$TeamFolders = Get-ChildItem $DeptSubFolder.FullName
		$RequiredFolders = $RequiredFoldersTemplate.clone()
		foreach ($TeamSubFolder in $TeamFolders) {
				if ($RequiredFolders -notcontains $TeamSubFolder.Name) {
					$BadFolders += $TeamSubFolder
				}
			Else {$RequiredFolders.Remove($TeamSubFolder.Name)}
		}
		If ($RequiredFolders.count -gt 1) {
		$RequiredFolders | 
			Foreach-object {$MissingFolders += $_}
		}	
	}
}
		