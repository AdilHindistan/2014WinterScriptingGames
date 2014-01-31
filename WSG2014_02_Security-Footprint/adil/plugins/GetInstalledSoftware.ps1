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
                        DisplayName=$p.displayName; 
                        DisplayVersion=$p.displayVersion;
                        InstallDate = $p.InstallDate;  
                        UninstallString=$uninstallString; 
                        ProductKey=$productKey   }
            }
        }
    }

    return $uninstall
}


## Main script 
$ScriptName = $MyInvocation.MyCommand.Name
$outputFile = Join-Path $PSScriptRoot ($ScriptName -replace '.ps1','_out.csv')
$configFile = Join-Path $PSScriptRoot ($ScriptName -replace '.ps1','_config.txt')

Get-UninstallInfo |export-csv -NoTypeInformation -Path $outputFile