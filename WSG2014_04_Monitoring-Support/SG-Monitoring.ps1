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


#region Helper Functions

Function ConvertFrom-CSVToXMLMonitoringFile {
<#
    .SYNOPSIS
    Convert CSV Input file path to XML File
    
    .DESCRIPTION
    Takes in a CSV File path containing Server Monitoring Data, and convert it to an xml configuration file for each server

#>
[CMDLETBinding()]
    param(        
        [PSObject]$Servers
        )

    Begin {
            $msgSource = $MyInvocation.MyCommand.Name               

            &$log "Loading template XML into memory - $PSScriptRoot\drsconfig.xml"
            $xmlpath = "$PSScriptRoot\drsconfig.xml"

            $xmldata = New-Object System.Xml.XmlDocument
            $xmldata.Load($xmlpath)

            if (-not (Test-Path C:\MonitoringFiles)) {
                try {                
                        New-Item -Path C:\MonitoringFiles -ItemType Directory |Out-Null
                        &$log "Local Storage folder does not exist. Creating C:\MonitoringFiles"
                    }
                catch {
                        &$log "Failed to create local storage. Script will exit. $_"
                        exit 1   
                }
            }

        }
    Process {
            foreach ($item in $Servers){
                    $xmldata.DRSmonitoring.Server.Name = $item.Server
                    $xmldata.DRSmonitoring.Server.IPAddress = $item.IP
                    $xmldata.DRSmonitoring.Monitoring.MonitorCPU =$item.CPU
                    $xmldata.DRSmonitoring.Monitoring.MonitorRAM =$item.RAM
                    $xmldata.DRSmonitoring.Monitoring.MonitorDisk=$item.Disk
                    $xmldata.DRSmonitoring.Monitoring.MonitorNetwork=$item.Network

                    
                    try {
                            $xmldata.save("C:\MonitoringFiles\$($item.Server)-DRSMonitoring.xml")
                            &$log "Saved monitoring config file C:\MonitoringFiles\$($item.Server)-DRSMonitoring.xml"
                        }
                    catch {
                            Write-Error "Failed trying to save config file to c:\MonitoringFiles. Script will exit. $_"
                            exit 1                              
                    }
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

Function Copy-ConfigFileToServer {
<#
    .SYNOPSIS
    Copies Monitoring Config file to servers

    .DESCRIPTION
    Copies monitoring config xml file from local storage to each server to be monitored
    
    .NOTES
    Creates a folder on server to store config file if it does not exist. When trying to access the remote server, it will try name first
    but if that fails, it will try the IP address as well to account for WINS/DNS issues.
#>    
    [CMDLETBINDING()]
    param(
            # full path to the input csv file
            [PSObject]$Servers
        )
    
    $msgSource = $MyInvocation.MyCommand.Name
    $localStorage  = 'C:\MonitoringFiles'
    
    Foreach ($server in $Servers) {
        

        if (Test-Connection $server.server -count 1 -Quiet) {
            
            &$log "$($server.server) is accessible by name"
            $remote = $server.server

        } else {
            
            ## try ip before we give up
            if (Test-Connection $server.ip -count 1 -Quiet) {

                &$log "$($server.server) is NOT accessible by name but is accessible by IP"
                $remote = $server.ip
            
            } else {                
            
                Write-Error  "$($server.server) is not accessible by name or IP. Exiting Script!"                
                exit 1
            
            }
            
        }

        &$log "Checking if DRSMonitoring folder exists on remote server"
        if ( -not ( Test-Path \\$remote\c$\DRSMonitoring) ) {                               
            
            try {
                    &$log  "Creating c:\DRSmonitoring folder on server $($server.server)"
                    New-Item -Path \\$remote\c$\DRSMonitoring -ItemType Directory -ErrorAction Stop |Out-Null
                }
            catch {
                    Write-Error "Failed to create DRSMonitoring folder on remote server $($server.server). Exiting script!"
                    exit 1   
            }
                
        }

        try { 
              Copy-Item -Path C:\MonitoringFiles\$($server.server)-*.xml -Destination \\$remote\c$\DRSMonitoring -ErrorAction Stop |out-null
              &$log "Successfully copied the monitoring file to $($server.server)"
        }
        catch {
              Write-Error "Failed to copy monitoring file to $($server.server). Exiting Script!"
              exit 1
       }    
    }    
}

#endregion

###  MAIN SCRIPT ###

#1. Create XML File

## $csvFile = Import-Csv $InputFile

#region print verbose messages from anywhere with time and calling function/script name
$msgSource = $MyInvocation.MyCommand.Name
$log = {

    param([string]$msg)              
    Write-Verbose "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${msgsource}: $msg"    

}
#endregion

if ($InputFile) {
    $servers = import-csv $InputFile
    
    &$log 'Calling function to create Monitoring Config XML file from supplied CSV for each server'
    ConvertFrom-CSVToXMLMonitoringFile -Servers $servers
    
    &$log 'Calling function to copy local config XML files to remote servers'
    Copy-ConfigFileToServer -Servers $servers
}

exit

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