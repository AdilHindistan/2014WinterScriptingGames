Configuration SGMonitoring
{
    
    param ( 
        
        [Parameter(Mandatory=$true)]
        [string[]] $Computername,
        
        [string]$path,
        [string]$Destination,
        
        [string]$RegKey
        )

    Node $Computername
    
    {
        
        Registry DRSmonitoing
        {
            Ensure = "present" 
            Key = "HKLM:\SOFTWARE\DRSmonitoing"
            ValueName = "Monitoring"
            ValueData = "1"
        }

       # File DirectoryCopy
       # {
       #     Ensure = "Present" 
       #     Type = "Directory" 
       #     Recurse = $true 
       #     DestinationPath = "c:\drsmonitoring"    
       # }

        File FileCopy
        {
            Ensure = "present" 
            Type = "file" 
           # Recurse = $true 
            SourcePath = "\\bamboo\SG2014\DRSConfig.xml"
            DestinationPath = "c:\drsmonitoring\DRSConfig.xml"  
           # DependsOn = "[File]DirectoryCopy"  
        }

        
    }
}

SGMonitoring -computername $computername -outputpath c:\SGDSC\monitoring