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
    Creates an XML config file from given CSV
#>
[CMDLETBINDING()]
Param(
    [Parameter(Mandatory)]
    [PSObject]$csv
)

## For Sunny C. to fill

}
#endregion Create XML



#endregion Functions


#region Main_Script

$ScriptName =$MyInvocation.MyCommand.Name

$log = {
    param([string]$msg)       
    Write-Verbose "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
}

if ($InputFile) {
    $csvFile = Import-Csv $InputFile
    New-XMLFile -csv $csvFile
}
#end region

