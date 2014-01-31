[CMDLETBINDING()]
$ScriptName = $MyInvocation.MyCommand.Name
$outputFile = Join-Path $PSScriptRoot ($ScriptName -replace '.ps1','_out.csv')
$configFile = Join-Path $PSScriptRoot ($ScriptName -replace '.ps1','_config.txt')
 


 Function Get-Config {
    # 
    param ( [string]$config )
    $result=@{}
    ((Get-Content $config) -match '^\w+:') | Foreach { 
        $name=($_ -split ':')[0]
        $value=($_ -split ':')[1] -split ','
        $result[$name]=$value
    }    
   $result
}


#$events = Get-WinEvent -FilterHashTable @{ LogName = $logname; StartTime = $date; ID = 1001 }
$EventConfig = Get-Config -config $configFile

$startdate=(Get-Date).AddHours(-10)
$Events = $EventConfig.GetEnumerator() | foreach {

    Write-Verbose "Processing $($_.key) with event IDs $($_.value)"
    Get-WinEvent -FilterHashTable @{ LogName = $_.key; 
            
            StartTime=$startdate; 
            ID = $_.value 
     }


}

$Events | export-csv -NoTypeInformation -Path $outputFile