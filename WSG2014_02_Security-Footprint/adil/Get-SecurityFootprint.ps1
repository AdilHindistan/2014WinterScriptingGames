#Requires -version 3
#Requires -RunAsAdministrator  ##Choose run with highest privilidges in Scheduled Task. This will be necessary for some plugins
<#
.Synopsis
   Creates a security footprint of the computer

.DESCRIPTION
   Creates a zipped file that contains security footprint of the computer and ships it to a central log folder.

.PARAMETER ConfigFile
    Full path to the config file. It is used to determine which plugins will be run. New plugins can be added, and turned on or off. A default config.ini is included in the script directory for the current plugins.

.PARAMETER CentralLogPath
    The network share where the collected log files will be written. If not specified, collected files

.EXAMPLE
   PS C:>Get-SecurityFootprint -CentralLogPath \\logserver\logshare
   
   This will create and ship a file named {ComputerName}_yyyymmdd_hhmmss.zip

.EXAMPLE
        PS C:> cat .\onlyevents.ini
        ## Security Plugin Configuration file
        ## <configuration_item>:true|false
        ## A value of $true means script should process the relevant plugin code to get data on the item
 
        GetEventLog:true
        GetFolder:false
        GetFile:false
        GetShare:false
        GetInstalledSoftware:false
        GetProcess:false
        GetService:false
        GetEnvVariable:false
        GetRegistry:false

   PS c:> Get-SecurityFootprint -CentralLogPath \\logserver\logshare -ConfigFile "$pwd\onlyevents.ini"

   Same as above but uses the onlyevents.ini file in the current directory to determine which plugins need to be run. In this case only 'geteventlog' plugin is set to be run
.NOTES
   Be sure to run script in elevated shell. Run with -verbose to see progress.Plugins output to \output folder where script resides script      
#>

[CMDLETBINDING()]
Param (
    [Parameter(HelpMessage='Provide the config file to determine which plugins will be run')]
    #Name of configuration file for plugins    
    [ValidateScript({test-path $_})]    
    [string]$ConfigFile,

    [Parameter(HelpMessage='Enter full path of the network share where logs will be shipped to')]
    #Central Log location
    [ValidateScript({Test-Path $_})]
    [string]$CentralLogPath
)

if (!$ConfigFile){
    #use default plugin config file
    $ConfigFile = join-path $PSScriptRoot 'config.ini'
}

# Get applicable plugin list from configuration file
Function Get-ApplicablePluginList {
    # Format of config file is config_item:[$true|$false]
    
    param ( [string]$config )
    
    ((Get-Content $config) -match '^\w+:') | Foreach { 
        $name,$value = $_ -split ':'
        if ([System.Convert]::ToBoolean($value)) {
            $name 
        }
    }        
}

# helper function to log messages to main script log file
$log = {
    param([string]$msg)
        
    Add-Content -path $script:LogFile  -value "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
    Write-Verbose "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
}




#region variable definition and initialization
$ScriptName = $MyInvocation.MyCommand.Name
$LogFile = Join-Path $PSScriptRoot ($ScriptName -replace '.ps1','_out.log')

$OutputRoot = Join-Path $PSScriptRoot "output" 
$OutputDate = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputPath = Join-Path $OutputRoot $OutputDate   ## this is where all the plugin output will be stored at

if (-not (test-path $OutputPath)) { 
    &$log "${ScriptName}: Creating $OutputPath to store plugin output"
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}
#endregion variable definitions


#region execute plugins
Foreach ( $p in (Get-ApplicablePluginList -config $ConfigFile)) {
    if (Test-Path "$PSScriptRoot\plugins\$p.ps1") {

            try {
                    &$log "Executing $p"                    
                    & "$PSScriptRoot\plugins\$p.ps1" -OutputPath $OutputPath -logFile $LogFile
            }
            Catch {
                    &$log $_
            }


    }
}
#endregion execute plugins


#region zip up the results
Add-Type -As System.IO.Compression.FileSystem

$ZipPath = join-path $PSScriptRoot "${Env:ComputerName}_${OutputDate}.zip"
try {
        &$log "Zipping up output from $outputPath as $ZipPath"
        [IO.Compression.ZipFile]::CreateFromDirectory($OutputPath, $ZipPath, "Optimal", $true )
        if ($CentralLogPath) {
            
                &$log "Copying zipped file to network share $CentralLogPath"
                Copy-Item -Path $ZipPath -Destination $CentralLogPath
                
                &$log "Deleting local copy of the zip file"
                Remove-Item -Path $ZipPath -Force

                &$log "Deleting output folder"
                Remove-Item -Path $OutputPath -recurse -Force            
        }
    }
catch {
        &$log $_
    }
#endregion zip