<#
.Synopsis
   Script to run the DSC configuration files
.DESCRIPTION
   Long description
.EXAMPLE
   dot source the script into memory
   Run-SGDSCConfig -computername Server1

   This example will run the various config files to create the MOF files.
   it them proceeds to run the start-DSCconfigiration to configure the specified machines.
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Run-SGDSCConfig
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        [parameter(Mandatory=$true, ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
        [string[]]$computername
        
    )


    Begin
    {
        if (-not(test-path c:\SGDSC\monitoring))
    {
        mkdir c:\SGDSC\monitoring
    }
    if (-not(test-path c:\SGDSC\LCM)) {mkdir c:\SGDSC\LCM}
    }
    Process
    {
        .\SGMonitoring.ps1 -computername $computername
        .\SGLocalConfigMgr.ps1 -computername $Computername

        Start-DscConfiguration -Path c:\sgdsc\monitoring -Wait -Verbose
        Set-DscLocalConfigurationManager -Path c:\sgdsc\LCM -Verbose
    }
    End
    {
        
    }
}