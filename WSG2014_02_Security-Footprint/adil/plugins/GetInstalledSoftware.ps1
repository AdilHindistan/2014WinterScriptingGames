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


function Get-InstalledSoftware {
$mof = @'
#PRAGMA AUTORECOVER
 
[dynamic, provider("RegProv"),
ProviderClsid("{fe9af5c0-d3b6-11ce-a5b6-00aa00680c3f}"),ClassContext("local|HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall")]
class SG_InstalledProducts {
[key] string KeyName;
[read, propertycontext("DisplayName")] string DisplayName;
[read, propertycontext("DisplayVersion")] string DisplayVersion;
[read, propertycontext("InstallDate")] string InstallDate;
[read, propertycontext("Publisher")] string Publisher;
[read, propertycontext("EstimatedSize")] string EstimatedSize;
[read, propertycontext("UninstallString")] string UninstallString;
[read, propertycontext("WindowsInstaller")] string WindowsInstaller;
};
 
[dynamic, provider("RegProv"),
ProviderClsid("{fe9af5c0-d3b6-11ce-a5b6-00aa00680c3f}"),ClassContext("local|HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432node\\Microsoft\\Windows\\CurrentVersion\\Uninstall")]
class SG_InstalledProducts32 {
[key] string KeyName;
[read, propertycontext("DisplayName")] string DisplayName;
[read, propertycontext("DisplayVersion")] string DisplayVersion;
[read, propertycontext("InstallDate")] string InstallDate;
[read, propertycontext("Publisher")] string Publisher;
[read, propertycontext("EstimatedSize")] string EstimatedSize;
[read, propertycontext("UninstallString")] string UninstallString;
[read, propertycontext("WindowsInstaller")] string WindowsInstaller;
};
'@

    $mof | Out-file -encoding ascii $env:TMP\SG_Mof.txt
    mofcomp.exe $env:TMP\SG_Mof.txt

    Get-WmiObject -Namespace root\default -class SG_InstalledProducts | Select DisplayName,DisplayVersion,InstallDate,Publisher,EstimatedSize,UninstallString,WindowsInstaller | Export-csv -notypeInformation $pwd\$pwd\InstalledProducts-MOF.csv -Append
    Get-WmiObject -Namespace root\default -class SG_InstalledProducts32 | Select DisplayName,DisplayVersion,InstallDate,Publisher,EstimatedSize,UninstallString,WindowsInstaller | Export-csv -notypeInformation $pwd\$pwd\InstalledProducts-MOF.csv -Append

    #remove the WMI Class from the repository
    Remove-WmiObject -Namespace root\default -class SG_InstalledProducts 
    Remove-WmiObject -Namespace root\default -class SG_InstalledProducts32

    #Remove the MOF File used to generate the WMI Class.
    Remove-Item $env:TMP\SG_Mof.txt

    #WRITE
    $InstalledSoftware = Import-Csv $pwd\InstalledProducts-MOF.csv
    return $InstalledSoftware 
}


## Main script 
&$log "Exporting results to $outputfile"
Get-InstalledSoftware |export-csv -NoTypeInformation -Path $outputFile -Force