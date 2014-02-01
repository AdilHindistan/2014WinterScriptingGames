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

&$log "Exporting Environment variables to $outputfile"
(Get-ItemProperty 'HKLM:\system\CurrentControlSet\control\Session Manager\Environment') |Export-Csv -Path $outputFile  -NoTypeInformation -Force
