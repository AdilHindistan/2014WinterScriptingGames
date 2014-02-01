[CMDLETBINDING()]
Param(
        [Parameter(Mandatory)]
        [String]$OutputPath,
        
        [Parameter(Mandatory)]
        [string]$LogFile
     )

$ScriptName = $MyInvocation.MyCommand.Name

$configFile = Join-Path $PSScriptRoot ($ScriptName -replace '.ps1','_config.ini')
 

if ($OutputPath) { 
    $outputFile = Join-Path $outputpath ($ScriptName -replace '.ps1','.csv') 
}

$log = {
    param([string]$msg)

    if ($LogFile) {        
        Add-Content -path $LogFile  -value "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
    }
    Write-Verbose "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
}


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



&$log "Getting configuration file to determine which events will be captured"
$EventConfig = Get-Config -config $configFile

$startdate=(Get-Date).AddHours(-24) ## Assuming this will be run daily

$Events = $EventConfig.GetEnumerator() | foreach {

    &$log  "Processing $($_.key) with event IDs $($_.value)"
    try {
        Get-WinEvent -FilterHashTable @{ 
                LogName = $_.key;             
                StartTime=$startdate; 
                ID = $_.value 
         } -ErrorAction SilentlyContinue
    }
    catch {
        ## Reading Security log requires privileges, scheduled job will take care of that when configured. 
        ## Running the script in normal shell throws errors, hence the catch block to ignore them
    }

}

&$log "Exporting results to $output file"
$Events | export-csv -NoTypeInformation -Path $outputFile -Force