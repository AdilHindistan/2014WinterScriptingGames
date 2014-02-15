<#
.Synopsis
   Deploy and Report on Monitoring Solution

.DESCRIPTION
   Sets up Monitoring configuration and produces compliance reports

.EXAMPLE
   
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
    [string]$InputFile
    
)



#region Function

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
            [PSObject]$Path
          )

	#Used to verfy True/False entries
	$VerfiyTable = @{
	       "True" = "TRUE"
	       "False" = "FALSE"
	       "" = ""
	}

	$ServerList = Import-Csv -Path $Path

	#Used to hold any bad entires found with a description of why they were bad
	$BadEntryList = @()

	#Create list of IP's and Servers to test for dupes
	#Not sure if there a cost time wise to using the Automatic foreach in a loop, just to be safe we are going to do it once
	$FullIPList = $ServerList.IP
	$FullServerlist = $ServerList.server

	Write-Verbose "ACTION : Verifying server list entries"
	ForEach ($entry in $ServerList) {
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



#region Create XML Config
Function New-XMLFile {
<#
    .SYNOPSIS
    Creates an XML (config) object from given CSV
#>
    [CMDLETBINDING()]
    Param (
            [Parameter(Mandatory)]
            [PSObject]$csv
          )

    ## For Sunny C. to fill
    
    ## Create XML object
    ## Save object to XML file under C:\MonitoringFiles

    ## Return the XML
    return $configXML
}
#endregion Create XML



workflow Copy-FileInParallel {
  <#           
      .DESCRIPTION
      Runs parallel feature of new PowerShell 3 to mass copy the file   
       Script gets the list of machines and copies a file to all of them in parallel. 

      .PARAMETER ComputerName
      An array of hostnames
  #>
  [cmdletbinding()]  
  param(

    [Parameter(Mandatory=$true)]
    [string[]]$ComputerName,

    [string]$ConfigFile

  )
  
          foreach -parallel ($computer in $ComputerName) {
            try   { 
                    Copy-Item -path $ConfigFile -destination "\\$computer\c$\drsmonitoring\" -Force; 
                    Write-Verbose "OK $computer"   
                  } 
            catch { 
                    Write-Verbose "Failed $computer" 
                  }

        }
  
}

#endregion Functions


#region Main_Script

$ScriptName =$MyInvocation.MyCommand.Name
$LocalConfigStore = "C:\MonitoringFiles"

$log = {
    param([string]$msg)       
    Write-Verbose "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
}

if ($InputFile) {

    &$log 'A CSV config file was supplied, importing: $InputFile'
    $csvFile = Import-Csv $InputFile
	
	$BadEntries = Validate-CSVFile -CSV $csvFile
	If ($BadEntries) {
		$csvFile = $csvFile | Where-Object {$_.Server -notin $BadEntryList.Server}
	}
	
    if (!test-path $LocalConfigStore) {
        
        &$log 'Creating $LocalConfigStore'
        $null = New-Item -ItemType File -Path $LocalConfigStore        

    }

    &$log 'Converting CSV input into XML'
    $configXML = New-XMLFile -csv $csvFile


    &$log "Copying Config file will overwrite if there is already one there"
    Copy-FileInParallel -ComputerName $csvfile.server -ConfigFile $configXML
}
#end region

