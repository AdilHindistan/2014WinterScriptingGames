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
[System.Collections.ArrayList]$outputObj = @()

try {
    $outputObj += Get-WmiObject -Namespace root\default -class SG_InstalledProducts | Select DisplayName,DisplayVersion,InstallDate,Publisher,EstimatedSize,UninstallString,WindowsInstaller 
    $outputObj += Get-WmiObject -Namespace root\default -class SG_InstalledProducts32 | Select DisplayName,DisplayVersion,InstallDate,Publisher,EstimatedSize,UninstallString,WindowsInstaller
        

    if ($OutputFile) {
        &$log "Exporting Computer share information to $outputfile"
        Write-Output $outputObj | Export-Csv -Path $outputFile  -NoTypeInformation -Force
        
        #remove the WMI Class from the repository
        Remove-WmiObject -Namespace root\default -class SG_InstalledProducts 
        Remove-WmiObject -Namespace root\default -class SG_InstalledProducts32
        #Remove the MOF File used to generate the WMI Class.
        Remove-Item $env:TMP\SG_Mof.txt
        }
    else {
        Write-Output $outputObj 
        
        #remove the WMI Class from the repository
        Remove-WmiObject -Namespace root\default -class SG_InstalledProducts 
        Remove-WmiObject -Namespace root\default -class SG_InstalledProducts32
        #Remove the MOF File used to generate the WMI Class.
        Remove-Item $env:TMP\SG_Mof.txt
        }
}
<<<<<<< HEAD
catch {
        &$log $_
    }
=======


## Main script 

        if ($OutputFile) {
            &$log "Exporting running Services to $outputfile"
            Get-InstalledSoftware |export-csv -NoTypeInformation -Path $outputFile -Force
        } else {
            Get-InstalledSoftware
        }
>>>>>>> 1da03d1d881841e8fe3a55163d40acc4bbfb00a0
