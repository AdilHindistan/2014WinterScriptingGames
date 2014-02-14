$HTMLTitle = "FolderSize and Number of Files"
$TblHeader =  "FolderSize on $env:ComputerName "

$outputObj = "" | Select Directory, Size, Count
#GET
Get-ChildItem | where {$_.PsIsContianer -eq $True}| foreach {
    Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -property length -sum -ErrorAction SilentlyContinue
}

    $outputObj.Directory = $_.FullName
    $outputObj.size = [Math]::Round($prop.Sum /1mb,2)
    $outputObj.Count= $prop.Count
    Write-Output $outputobj 
}

#WRITE
import-csv $pwd\FolderSize.csv