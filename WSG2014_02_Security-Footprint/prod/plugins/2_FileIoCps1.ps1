$HTMLTitle = "File IOC"
$TblHeader =  "File IOC on $env:ComputerName "

$outputObj= "" | Select File, Size, LastModified, Hash

Get-ChildItem -Path C:\ -Recurse -File | foreach {
    $prop = Get-ChildItem $_.FullName -ErrorAction SilentlyContinue 
    
    $outputObj.File= $_.FullName
    $outputObj.size = [Math]::Round($prop.Length /1kb,2)
    $outputObj.LastModified= $_.LastWriteTime
    $outputObj.Hash = Get-Hash $_.FullName
    
    Write-Output $outputobj | Export-Csv -NoTypeInformation $pwd\FileInspction.csv -Append
}

#WRITE
import-csv $pwd\FileInspction.csv 