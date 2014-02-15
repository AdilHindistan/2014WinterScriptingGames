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
            # An object which has at least server name and ip address
            [PSObject]$Servers                                   
        )
    
    $msgSource = $MyInvocation.MyCommand.Name
    $localStorage  = 'C:\MonitoringFiles'
    
    Foreach ($server in $Servers) {
        $MonitoringFileInstalled=$false
        

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
              if (test-path \\$remote\c$\DRSMonitoring\$($server.server)-DRSMonitoring.xml) {
                
                &$log "Monitoring config file already exists on the target. Overriding"
                $MonitoringFileInstalled = $true
              }
              Copy-Item -Path $localStorage\$($server.server)-DRSMonitoring.xml -Destination \\$remote\c$\DRSMonitoring -ErrorAction Stop -Force |out-null
              &$log "Successfully copied the monitoring file to $($server.server)"
        }
        catch {
              Write-Error "Failed to copy monitoring file to $($server.server). Exiting Script!"
              exit 1
       } 

      [PSCustomObject]@{                                        
                        ComputerName = $($server.server);
                        MonitoringFileInstalled = $MonitoringFileInstalled
                        
     }   
    }    
}


function Set-RegistryKey {
<#
    .SYNOPSIS
    Creates registry key and reports on results
    
    .DESCRIPTION
    Creates Registry keys and reports on the status of given reg key/value. Defaults are set as mentioned in the DR. Scripto requirements for brevity.

    .INPUT 
    An array of Computer Names

    .EXAMPLE 
    When run with the defaults Set-RegistryKey -ComputerName  adil-790-1,adil-w7x32vm2,adil-w7x32vm1,adil-w7x64vm1
    
        ComputerName   : ADIL-790-1
        KeyExisted     : True
        KeyCorrect     : True
        KeyCreated     : False
        PSComputerName : adil-790-1
        RunspaceId     : 28ff10a2-7ee4-4cff-9f22-8db2aa9ad02e

        ComputerName   : ADIL-W7X32VM2
        KeyExisted     : True
        KeyCorrect     : True
        KeyCreated     : False
        PSComputerName : adil-w7x32vm2
        RunspaceId     : ab808f58-9e42-400c-981c-755efd97b623

        ComputerName   : ADIL-W7X32VM1
        KeyExisted     : True
        KeyCorrect     : True
        KeyCreated     : False
        PSComputerName : adil-w7x32vm1
        RunspaceId     : f532e511-7432-4991-9785-d99021ad05d4

        ComputerName   : ADIL-W7X64VM1
        KeyExisted     : True
        KeyCorrect     : True
        KeyCreated     : False
        PSComputerName : adil-w7x64vm1
        RunspaceId     : fbeef086-1e14-4cb5-b84b-2b02614d7188

    .OUTPUT
    PSCustomObject 
#>
    [CmdletBinding()]
    param ( 
            [Parameter(HelpMessage='One or more computer name')]
            [ValidateNotNullOrEmpty()]
            [string[]]$ComputerName,

            [Parameter(HelpMessage='Registry Path in the form of HKLM:\SOFTWARE')]
            [string]$path='HKLM:\SOFTWARE\DRSMONITORING',

            [Parameter(HelpMessage='Registry key')]
            [string]$key='Monitoring',

            [string]$value='1',

            [string]$type="DWORD"
    )
    
        $msgSource = $MyInvocation.MyCommand.Name
        
        $ScriptBlock = {
            param($path,$key,$value,$type)

            $KeyExisted = $KeyCreated = $KeyCorrect = $false

                        if (test-path $path) 
                        { 
                            $KeyExisted = $true
                            
                            $value=(Get-ItemProperty -path $path).$key
                            if ($value -eq 1) {                                
                                $KeyCorrect = $true
                            }


                        } else {
                      
                            Write-Verbose "Registry key does not exist. Creating!"
                            $KeyCreated = $true
                            New-Item -path $path -force | out-null
                        }
                        
                      try 
                      {                 
                            Set-ItemProperty -path $path -name $key -Type $type -Value $Value -force            
                      }
                      catch 
                      {
                            write-error "An error occured.$Error[$error.count-1].exception" 
                            exit 1
                      }

                    [PSCustomObject]@{                                        
                                        ComputerName = $env:COMPUTERNAME;
                                        KeyExisted   = $KeyExisted;
                                        KeyCorrect   = $KeyCorrect;
                                        KeyCreated   = $KeyCreated;
                    }

        }
    &$log "Branching out to servers to check registry keys and create/correct them if necessary"
    Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ArgumentList ($path, $key, $value, $type)
}

#endregion

###  MAIN SCRIPT ###

#region print verbose messages from anywhere with time and calling function/script name
$msgSource = $MyInvocation.MyCommand.Name
$log = {

    param([string]$msg)              
    Write-Verbose "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${msgsource}: $msg"    

}
#endregion

#region process csv monitoring input file 
if ($InputFile) {
    $Fragments=@()
    $servers = import-csv $InputFile
    
    &$log 'Calling function to create Monitoring Config XML file from supplied CSV for each server'
    ConvertFrom-CSVToXMLMonitoringFile -Servers $servers
    
    &$log 'Calling function to copy local config XML files to remote servers'
    $CopyResults = Copy-ConfigFileToServer -Servers $servers
    $Fragments += $CopyResults |ConvertTo-Html -Property ComputerName,MonitoringFileInstalled -as Table -PreContent "<H2>Config File</H2>" -Fragment |out-string

    &$log 'Setting Registry Key for monitoring on each server'
    $RegResult = Set-RegistryKey -ComputerName ($servers.server)
    $Fragments += $RegResult |ConvertTo-Html -Property ComputerName,KeyExisted,KeyCorrect,KeyCreated -as Table -PreContent "<H2>Registry</H2>" -Fragment |out-string


    $head=@'
    <style>
        body { background-color:#dddddd;
               font-family:Tahoma;
               font-size:12pt; }
        td, th { border:1px solid black; 
                 border-collapse:collapse; }
        th { color:white;
             background-color:black; }
        table, tr, td, th { padding: 2px; margin: 0px }
        table { margin-left:50px; }
        </style>
'@


    $saveHTMLfile = "MonitoringSetupReport_$(get-date -Format "yyyyMMdd.HHmm").html"  
    
    &$log "Saving Monitoring Setup Report to $PSScriptRoot\$saveHTMLfile"
    ConvertTo-Html -Head $head -PostContent $Fragments -Title "Monitoring Setup Report as of $(get-date -Format 'yyyyMMdd.HHmm')" -Body "<H1>Monitoring Setup Report<h1>" |out-file $PSScriptRoot\$saveHTMLfile -Encoding utf8
}
#endregion





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