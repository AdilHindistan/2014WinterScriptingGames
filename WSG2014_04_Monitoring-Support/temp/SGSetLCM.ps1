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