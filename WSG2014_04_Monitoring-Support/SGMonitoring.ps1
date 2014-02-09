Configuration SGEvent4
{
    
    param ( $NodeName )

    Node $NodeName
    
    {
        
        Registry DRSmonitoing
        {
            Ensure = "Present" 
            Key = "HKLM:\SOFTWARE\DRSmonitoing"
            ValueName = "Monitoring"
            ValueData = "1"
        }

        File DirectoryCopy
        {
            Ensure = "Present" 
            Type = "file" 
           # Recurse = $true 
            SourcePath = "C:\SG2014\DRSConfig.xml"
            DestinationPath = "c:\drsmonitoring\DRSConfig.xml"    
        }

        #trying to use the Log to create the report

        #Log AfterDirectoryCopy
        #{
        #    # The message below gets written to the Microsoft-Windows-Desired State Configuration/Analytic log
        #    Message = "Finished running the file resource with ID DirectoryCopy"
        #    DependsOn = "[File]DirectoryCopy" # This means run "DirectoryCopy" first.
        #}
    }
}
