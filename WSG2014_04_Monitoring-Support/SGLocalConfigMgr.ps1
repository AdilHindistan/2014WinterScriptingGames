Configuration SGLocalConfigMgr
{
    Param (
        [string]$computername
    )
    Node $computername 
        {
            LocalConfigurationManager
            {
                ConfigurationMode = "ApplyAndAutoCorrect"
            }
        }
}

SGLocalConfigMgr -computername $Computername -OutputPath c:\SGDSC\LCM