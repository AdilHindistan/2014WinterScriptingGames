$ScriptName = $MyInvocation.MyCommand.Name
$outputFile = Join-Path $PSScriptRoot ($ScriptName -replace '.ps1','_out.csv')
$configFile = Join-Path $PSScriptRoot ($ScriptName -replace '.ps1','_config.txt')
 


 Function Get-Config {
    # 
    param ( [string]$config )
    $result=@{}
    ((Get-Content $config) -match '^\w+:') | foreach { 
       
        [string]$name=($_ -split ':')[0]
        [int[]]$value=($_ -split ':')[1] -split ','
       
        $result[$name]=$value
    }    
   $result
}


$EventConfig = Get-Config -config $configFile

$startdate=(Get-Date).AddHours(-10)
$Events = $EventConfig.GetEnumerator() | foreach {

    Write-Verbose "Processing $($_.key) with event IDs $($_.value)"
    try {
        Get-WinEvent -FilterHashTable @{ 
                LogName = $_.key;             
                StartTime=$startdate; 
                ID = $_.value 
         } -ErrorAction SilentlyContinue
    }
    catch {
        ## Reading Security log requires priviliges. Running normally throws errors

        }

}

$Events | export-csv -NoTypeInformation -Path $outputFile