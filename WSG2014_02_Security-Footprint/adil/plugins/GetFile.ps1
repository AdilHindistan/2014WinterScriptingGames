[CMDLETBINDING()]
Param(
        [Parameter(Mandatory)]
        [String]$OutputPath,
        
        [Parameter(Mandatory)]
        [string]$LogFile
     )

$ScriptName = $MyInvocation.MyCommand.Name
$outputFile = Join-Path $outputpath ($ScriptName -replace '.ps1','.csv')

$log = {
    param([string]$msg)
        
    Add-Content -path $script:LogFile  -value "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
    Write-Verbose "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
}

$outputObj= "" | Select File, SizeinKB, LastModified, Hash
try {
        if ($OutputFile) {
            &$log "Exporting all files, file size, filehash to $outputfile"
            
            Get-ChildItem -Path C:\ -Recurse -File | foreach {
            $prop = Get-ChildItem $_.FullName -ErrorAction SilentlyContinue 
    
            $outputObj.File= $_.FullName
            $outputObj.SizeinKB = [Math]::Round($prop.Length /1kb,2)
            $outputObj.LastModified= $_.LastWriteTime
            $outputObj.Hash = Get-Hash $_.FullName
            Write-Output $outputobj | Export-Csv -NoTypeInformation $pwd\FileInspction.csv -Append
            }

        } else {
            Get-ChildItem -Path C:\ -Recurse -File | foreach {
            $prop = Get-ChildItem $_.FullName -ErrorAction SilentlyContinue 
    
            $outputObj.File= $_.FullName
            $outputObj.SizeinKB = [Math]::Round($prop.Length /1kb,2)
            $outputObj.LastModified= $_.LastWriteTime
            $outputObj.Hash = Get-Hash $_.FullName
            Write-Output $outputobj 
            }
        
            }
    }
catch {
        &$log $_
        }

