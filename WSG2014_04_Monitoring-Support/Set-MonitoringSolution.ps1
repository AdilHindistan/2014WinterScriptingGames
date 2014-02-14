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

