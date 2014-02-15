<#
.Synopsis
   Deploy and Report on Monitoring Solution

.DESCRIPTION
   Sets up Monitoring configuration and produces compliance reports

.EXAMPLE
 .\SG-monitoring.ps1 -inputfile .\servers.csv -verbose

.PARAMETER InputFile

.OUTPUTS
  Outputs report of presence of c:\DRSMonitoring as a HTML

#>
[CmdletBinding(SupportsShouldProcess)]
Param
(
    # Full path to the csv config file    
    [Parameter(HelpMessage="Enter full path to the config csv file")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({(test-path $_) -and ((get-item $_).extension -eq '.csv')})]    
    [string]$InputFile
)

#region Helper Functions

Function ConvertFrom-CSVToXMLMonitoringFile {
<#
    .SYNOPSIS
    Takes a CSV File path containing Server Monitoring Data, and convert it to an xml configuration file for each server
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
                        #exit 1   
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

Function Copy-ConfigFileToServer {
<#
    .SYNOPSIS
    Creates a folder on server to store config file if it does not exist. When trying to access the remote server, it will try NETBIOS name first
    but and if that fails, it will try the IP address to connect to the server.    
#>    
    [CMDLETBINDING()]
    param(
           [PSObject]$Servers                                   
        )
    
    $msgSource = $MyInvocation.MyCommand.Name
    $localStorage  = 'C:\MonitoringFiles'
    $Hash=@{}
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

       $Hash[$($server.server)]=$MonitoringFileInstalled
    }    

    $Hash

} #End of Function Copy-ConfigFileToServer

Function Set-RegistryKey {
<#
    .SYNOPSIS
    Creates Registry keys and reports on the status of given reg key/value. Defaults are set as mentioned in the DR. Scripto requirements for brevity.

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
} #End of Function Set-RegistryKey

#endregion

###  MAIN SCRIPT ###

$msgSource = $MyInvocation.MyCommand.Name
$log = {
    param([string]$msg)              
    Write-Verbose "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${msgsource}: $msg"    
}

#region process csv monitoring input file 
if ($InputFile) {
    $Fragments=@()
    $servers = import-csv $InputFile
    
    &$log 'Calling function to create Monitoring Config XML file from supplied CSV for each server'
    ConvertFrom-CSVToXMLMonitoringFile -Servers $servers
    
    &$log 'Calling function to copy local config XML files to remote servers'
    $CopyResult = Copy-ConfigFileToServer -Servers $servers
    
    &$log 'Calling function to copy local config XML files to remote servers'
    $PhillyPoshObject = $RegResult |select-object ComputerName,KeyExisted,KeyCorrect,KeyCreated,@{l="MonitoringFileInstalled";e={$CopyResult[$($_.ComputerName)]}}
    
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
    $PhillyPoshObject |ConvertTo-Html -Head $head -as Table -Title "Monitoring Setup Report" -Body "Monitoring Setup Report as of $(get-date -Format 'yyyyMMdd.HHmm')"|out-file $PSScriptRoot\$saveHTMLfile -Encoding utf8
    $PhillyPoshObject
}
#endregion
