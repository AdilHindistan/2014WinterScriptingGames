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


function Get-UninstallInfo {
    $uninstallRegKeys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    $UninstallKeys = Get-ChildItem $uninstallRegKeys
   
   $uninstall = foreach ($key in $UninstallKeys) {    
           
        $keyProperties = Get-ItemProperty $key.pspath
        foreach ($p in $keyProperties) {  

            $uninstallString = $p.uninstallstring             
            $tempString = $uninstallString -replace '.*?\{(.*?)\}.*','$1' 
        
            if ( -not ($tempString -eq $uninstallString) ) {
                $productKey = $tempString
            } 

            if ($displayName) {
                [PSCustomObject]@{ 
                        DisplayName=$p.DisplayName; 
                        DisplayVersion=$p.DisplayVersion;
                        InstallDate = $p.InstallDate;  
                        UninstallString=$uninstallString; 
                        ProductKey=$productKey   }
            }
        }
    }

    return $uninstall
}


## Main script 
&$log "Exporting results to $outputfile"
Get-UninstallInfo |export-csv -NoTypeInformation -Path $outputFile -Force