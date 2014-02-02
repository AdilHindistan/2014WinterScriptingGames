[CMDLETBINDING()]
Param(
        [Parameter(Mandatory)]
        [String]$OutputPath,
        
        [Parameter(Mandatory)]
        [string]$LogFile
     )

$ScriptName = $MyInvocation.MyCommand.Name

$outputFile = Join-Path $outputpath ($ScriptName -replace '.ps1','.csv')
$configFile = Join-Path $PSScriptRoot ($ScriptName -replace '.ps1','_config.ini')
 


 Function Get-Config {
    #Name of config file 
    param ( [string]$config )
    
    $result=@{}
    ((Get-Content $config) -match '^\w+:') | foreach { 
       
        [string]$name=($_ -split ':')[0]
        [int[]]$value=($_ -split ':')[1] -split ',' #we want an array for Event ID, not a string
       
        $result[$name]=$value
    }    
   
   $result
}

$log = {
    param([string]$msg)
        
    Add-Content -path $script:LogFile  -value "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
    Write-Verbose "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
}


&$log "Getting configuration file to determine which events will be captured"
$EventConfig = Get-Config -config $configFile

$Events = $EventConfig.GetEnumerator() | foreach {

    &$log  "Processing $($_.key) with event IDs $($_.value)"
    try {
        Get-EventLog -FilterHashTable @{ 
                LogName = $_.key;             
                EventID = $_.value 
         } -ErrorAction SilentlyContinue | select EventID,MachineName,EntryType,Message,Source,TimeGenerated
    }
    catch {
        ## Reading Security log requires privileges, scheduled job will take care of that when configured. 
        ## Running the script in normal shell throws errors, hence the catch block to ignore them
    }

}

&$log "Exporting results to $output file"
$Events | export-csv -NoTypeInformation -Path $outputFile -Force