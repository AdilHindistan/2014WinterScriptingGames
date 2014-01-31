#Requires -version 3
[CMDLETBINDING()]
Param (
    #[String]$ConfigFile="$PSScriptRoot\config.txt"
    [ValidateScript({test-path $_})]
    [String]$ConfigFile = 'C:\Users\Adil\Documents\GitHub\PhillyPosh\WSG2014_02_Security-Footprint\adil\Config.txt'
)


# Get applicable plugin list from configuration file
Function Get-ApplicablePluginList {
    # Format of config file is config_item:[$true|$false]
    param ( [string]$config )
    
    ((Get-Content $ConfigFile) -match '^\w+:') | Foreach { 
        $name,$value=$_ -split ':'; 
        if ($value) {
            $name 
        }
    }        
}

## Execute each plugin
Foreach ( $p in (Get-ApplicablePluginList -config $ConfigFile)) {
    if (Test-Path "$PSScriptRoot\plugins\$p.ps1") {
            Write-Verbose "Executing $p"
            & "$PSScriptRoot\plugins\$p.ps1"
    }
}


