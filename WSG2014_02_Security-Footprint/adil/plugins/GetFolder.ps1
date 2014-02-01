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

$outputObj = "" | Select Directory, Size, Count
try {
        if ($OutputFile) {
            &$log "Exporting Folder Sizes to $outputfile"
            Get-ChildItem -Path C:\ -Directory | foreach {
            $prop = Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -property length -sum -ErrorAction SilentlyContinue
    
            $outputObj.Directory = $_.FullName
            $outputObj.size = [Math]::Round($prop.Sum /1mb,2)
            $outputObj.Count= $prop.Count
            Write-Output $outputobj | Export-Csv -NoTypeInformation $pwd\FolderSize.csv -Append
            } 
        } else {
            Get-ChildItem -Path C:\ -Directory | foreach {
            $prop = Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -property length -sum -ErrorAction SilentlyContinue
    
            $outputObj.Directory = $_.FullName
            $outputObj.size = [Math]::Round($prop.Sum /1mb,2)
            $outputObj.Count= $prop.Count
            Write-Output $outputobj 
            }
        }
    }
catch {
        &$log $_
        }

