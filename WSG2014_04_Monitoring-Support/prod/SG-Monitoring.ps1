<#
.Synopsis
   Deploy and Report on Monitoring Solution

.DESCRIPTION
   Sets up Monitoring configuration and produces compliance reports

.EXAMPLE
   
.PARAMETER
   InputFile

.OUTPUTS
   Output from this cmdlet (if any)
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
                            #exit 1                              
                    }
             }
        }
} #End of Function Create-DRSMonitoringFile

Function Copy-ConfigFileToServer {
<#
    .SYNOPSIS
    Copies monitoring config xml file from local storage to each server to be monitored
    
    .DESCRIPTION
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

#region Validate CSV file
Function Validate-CSVFile {
<#
    .SYNOPSIS
    Validates CSV entries for
		Duplicate Server names
		Duplicate IPS
		Bad Server names that don’t match DNS name standards
		Malformed IP address
		Settings that aren’t True, False, or Blank
	If found returns a list of bad entries with all the reasons why they were bad
#>

    [CMDLETBINDING()]
    Param (
            [Parameter(Mandatory)]
            [PSObject]$CSV
          )

	#Used to verfy True/False entries
	$VerfiyTable = @{
	       "True" = "TRUE"
	       "False" = "FALSE"
	       "" = ""
	}

	#Used to hold any bad entires found with a description of why they were bad
	$BadEntryList = @()

	#Create list of IP's and Servers to test for dupes
	#Not sure if there a cost time wise to using the Automatic foreach in a loop, just to be safe we are going to do it once
	$FullIPList = $CSV.IP
	$FullServerlist = $CSV.server

	Write-Verbose "ACTION : Verifying server list entries"
	ForEach ($entry in $CSV) {
		$BadEntryReason = ""
	    #Verify that no duplicates server names or IPs exist
		If (($FullServerlist -match $entry.Server).count -gt 1) {$BadEntryReason += "Duplicate server name in list`n"}
		If (($FullIPList -match $entry.IP).count -gt 1) {$BadEntryReason += "Duplicate IP in list`n"}
		#Verify that server name is a proper DNS name
	    If ($entry.server -notmatch "^(?!-)[a-zA-Z0-9-]{1,63}(?<!-)$") {$BadEntryReason += "Server name is not a proper DNS name`n"}
		#Verify that IP is a proper IP address
	    If ($entry.IP -notmatch "^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$") {$BadEntryReason += "IP address is malformed`n"}
		#grab all remaining properties
		$TrueFalseProps = $entry | 
							Get-Member -MemberType NoteProperty | 
							Where-Object {($_.Name -ne "Server") -and ($_.Name -ne "IP")} |
							ForEach-Object {$_.name}
		#Verify that they are either true/false or blank
		$TrueFalseProps | ForEach-Object {
			If (-not ($VerfiyTable.containsKey($entry.$_))) {$BadEntryReason += "Setting $_ is not True, False, Or blank`n"}
		}
		#If one or more bad entries are found add the reason to the entry and the bad entry list
		If ($BadEntryReason) {$BadEntryList += ($entry | Add-Member -MemberType NoteProperty -Name "BadEntryReason" -Value $BadEntryReason -PassThru)}
	}
	 
	If ($BadEntryList) {
	       Write-Verbose "INFO : Bad Entries found, returning"
		   $BadEntryList
	}
	Else {Write-Verbose "INFO : CSV file contains no errors"}
}
#EndRegion 

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
	
	$BadEntries = Validate-CSVFile -CSV $servers
	If ($BadEntries) {
		$servers = $servers | Where-Object {$_.Server -notin $BadEntryList.Server}
	}
    
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
    
	If ($BadEntries) {
		$BadEntries | Foreach-object {$_.BadEntryReason = $_.BadEntryReason -replace "`n","<BR>"}
		$Fragments += $BadEntries | ConvertTo-Html -as Table -PreContent "<H2>Bad CSV Entries</H2>" -Fragment |out-string
	}
	
    &$log "Saving Monitoring Setup Report to $PSScriptRoot\$saveHTMLfile"
    ConvertTo-Html -Head $head -PostContent $Fragments -Title "Monitoring Setup Report as of $(get-date -Format 'yyyyMMdd.HHmm')" -Body "<H1>Monitoring Setup Report<h1>" |out-file $PSScriptRoot\$saveHTMLfile -Encoding utf8
}
#endregion
