[CMDLETBINDING()]
Param(
        [Parameter(Mandatory)]
        [String]$OutputPath,
        
        [Parameter(Mandatory)]
        [string]$LogFile
     )

$ScriptName = $MyInvocation.MyCommand.Name

if ($OutputPath) { 
    $outputFile = Join-Path $outputpath ($ScriptName -replace '.ps1','.csv') 
}

$log = {
    param([string]$msg)

    if ($LogFile) {        
        Add-Content -path $LogFile  -value "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
    }
    Write-Verbose "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
}

try {
        $outputObj = "" | Select Directory, Size, Count
        Get-ChildItem -Path C:\ -Directory | foreach {
            $prop = Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -property length -sum -ErrorAction SilentlyContinue
            $outputObj.Directory = $_.FullName
            $outputObj.size = [Math]::Round($prop.Sum /1mb,2)
            $outputObj.Count= $prop.Count
            }
        if ($OutputFile) {
            &$log "Exporting Folder Sizes to $outputfile"
            Write-Output $outputobj | Export-Csv -Path $outputFile  -NoTypeInformation -Append
            } 
        else {
            Write-Output $outputobj 
            }
        
    }
catch {
        &$log $_
        }

