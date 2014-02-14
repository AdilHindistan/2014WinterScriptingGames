param(
$computer
)
$csvfile=".\servers.csv"
$csv = Import-Csv $csvfile

#region Helper Functions

Function Create-DRSMonitoringFile {

#Include TestPath and input validation
param($csvfile=".\servers.csv")

Begin {
    $csv = Import-Csv $csvfile
    $xmlpath = 'C:\github\PhillyPosh\WSG2014_04_Monitoring-Support\drsconfig.xml'
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
}

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
}

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
}

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
} #End of Function

#endregion

#MAIN

#1. Create XML File
Create-DRSMonitoringFile

#2. Copy XML File
foreach ($server in $csv) {
    #Test c:\DRSMonitoring exist, else create it.
    Create-Path $computer $server.server
    #copy XML to c:\drsmonitoring
    if( Test-path "$pwd\$server.server-DRSMonitoring.xml") {
        copy "$pwd\$server.server-DRSMonitoring.xml" \\$server.server\c$\DRSMonitoring\$server.server-DRSMonitoring.xml
        }
}
#3. Set Registry Value
$obj = "" | Select ServerName,RegistyExistButIncorrect,RegistryExistAndCorrect,RegistryDoesNotExist

foreach ($server in $csv) {
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