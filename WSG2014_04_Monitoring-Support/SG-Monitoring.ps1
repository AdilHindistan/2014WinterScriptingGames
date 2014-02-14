<#
.Synopsis
   Deploy and Report on Monitoring Solution

.DESCRIPTION
   Sets up Monitoring configuration and produces compliance reports

.EXAMPLE
   
.PARAMETER
InputFile

.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
[CmdletBinding(SupportsShouldProcess)]
Param
(
    # Full path to the csv config file
    [Parameter(HelpMessage="Enter full path to the config csv file")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({(test-path $_) -and ((get-item $_).extension -eq '.csv')})]    
    [string]$InputFile=".\servers.csv"
    
)
$csv = Import-Csv $InputFile

#region Helper Functions

Function Create-DRSMonitoringFile {

param($csvfile)

Begin {
    $csv = Import-Csv $csvfile
    $xmlpath = "$pwd\drsconfig.xml"
    $xmldata = New-Object XML
    $xmldata.Load($xmlpath)
    }
Process {
    foreach ($item in $csv){
        $xmldata.DRSmonitoring.Server.Name = $item.Server
        $xmldata.DRSmonitoring.Server.IPAddress = $item.IP
        $xmldata.DRSmonitoring.Monitoring.MonitorCPU =$item.CPU
        $xmldata.DRSmonitoring.Monitoring.MonitorRAM =$item.RAM
        $xmldata.DRSmonitoring.Monitoring.MonitorDisk=$item.Disk
        $xmldata.DRSmonitoring.Monitoring.MonitorNetwork=$item.Network
        $xmldata.save("$pwd\$($item.Server)-DRSMonitoring.xml")
        }
    }
} #End of Function Create-DRSMonitoringFile

Function Get-RegistryHive {
param(
$computer,
$hive = 'SOFTWARE\DRSMonitoring'
)
    $objReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
    if($objReg.openSubKey($hive,$true)) {
        $objRegKey = $objReg.openSubKey($hive,$true)
        $monitoringValue = $objRegkey.Getvalue('Monitoring')
        Write-output $monitoringValue 
        }
    else {
        Write-output "DRSMonitoringKEy does not exist"
    }
} #End of Function Get-RegistryHive

Function Set-RegistryHive {
param(
$computer,
$hive = 'SOFTWARE\DRSMonitoring',
$regvalue = 1
)
    try {
        $objReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
        $objRegKey = $objReg.openSubKey($hive,$true)
        $monitoringValue = $objRegkey.Setvalue('Monitoring',$regvalue,'String')
        }
    catch [Exception] {
        "REGISTRY ADD: $computer $_.Exception.Message"
        }
} #End of Function Set-RegistryHive

Function Create-Path {
param(
$computer,
$hive = 'SOFTWARE\DRSMonitoring',
$regvalue = 1
)

process {    
    $temppath = "\\$computer\c$\DRSMonitoring"
       
    #Check if TEMP Exists.
    if(!(Test-Path -Path $temppath)) {
   
        try {
            #Else Create Temp Folder
            $process = ([wmiclass]"\\$computer\root\cimv2:win32_Process")
            $command = 'cmd /c mkdir C:\DRSMonitoring'
            $process.create($command)
            }
    catch [Exception] {
        "DRS Monitoring FILE CREATION ERROR: $computer $_.Exception.Message"
        }
    } #end of IF
    } #end of Process Block
} #End of Function Create-Path

Function Copy-DRSFile{
param(
    [Parameter(Mandatory=$true)]
    [string]$ComputerName,
    [string]$ConfigFile
    )
    
    try{ 
        #copy XML to c:\drsmonitoring
        if(Test-path "$pwd\$server.server-DRSMonitoring.xml") {
            copy "$pwd\$server.server-DRSMonitoring.xml" \\$server.server\c$\DRSMonitoring\$server.server-DRSMonitoring.xml
            }
        } 
    catch { 
            Write-Verbose "Failed copying file to $computer" 
            }
}
#endregion

#MAIN

#1. Create XML File
Create-DRSMonitoringFile -csvfile $InputFile

$obj = "" | Select ServerName,RegistyExistButIncorrect,RegistryExistAndCorrect,RegistryDoesNotExist

foreach ($server in $csv) {
    #2. Copy File in Parallel
    Create-Path -Computer $server.server
        Copy-FileInParallel
    
    $regValue = Get-RegistryHive -computer $server.server
    
    switch ($regValue) {
    "$null" {
            Write-Verbose "DRSMonitoring key does not exist on $server.server"
            Set-RegistryHive
            $obj.ServerName = $server.Server
            $obj.RegistryDoesNotExist = "TRUE"
            $obj | Export-CSV -notypeinformation $pwd\RegKeyNumerics.csv -append
            }
    "1" {
         Write-Verbose "DRSMonitoring key does not exist on $server.server"
         $obj.ServerName = $server.Server
         $obj.RegistryExistAndCorrect = "TRUE"
         $obj | Export-CSV -notypeinformation $pwd\RegKeyNumerics.csv -append
         }
    default {
            Write-Verbose "DRSMonitoring key exists, but is incorrect on $server.server"
            Set-RegistryHive
            $obj.ServerName = $server.Server
            $obj.RegistyExistButIncorrect = "TRUE"
            $obj | Export-CSV -notypeinformation $pwd\RegKeyNumerics.csv -append
            }

        } # End of Switch

    } # End of Foreach

<#
TODO:
Log all actions into an object.
Log create CMD into an object
Log DRSMonitoringKey Creation into an object
HTML Output report
Compare-Object $pwd\server01-drsconfig.xml \\$server01\c$\server01-drsconfig.xml
#>