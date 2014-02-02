<#
.Synopsis
   Lists running computer processes

.DESCRIPTION
   A plugin to print running processeson the computer, including the command line, which can be helpful in incident investigation. It can be run stand-alone or as part of another script with options to log to main script log and output to defined location

.PARAMETER OutputPath
    The full path to the directory where the output should be written to

.PARAMETER LogFile
    The file where script events will be logged to. Main script log file name can be passed here, to collect progress information from this plugin

.EXAMPLE
   PS C:> GetProcess.ps1 |format-table -AutoSize

    ProcessName                  ExecutablePath                                   ProcessId ParentProcessId CommandLine                                                                                                                                               
    -----------                  --------------                                   --------- --------------- -----------                                                                                                                                               
    System Idle Process                                                                   0               0                                                                                                                                                           
    synergys.exe                 C:\Program Files\Synergy\synergys.exe                11004            2424 "C:/Program Files/Synergy/synergys.exe" -f --no-tray --debug NOTE --name AHSys --ipc --stop-on-desk-switch -c C:/Users/Adil/synergy.conf --address :24800 
    conhost.exe                  C:\WINDOWS\system32\conhost.exe                       6932           11004 \??\C:\WINDOWS\system32\conhost.exe 0x4          
   
   When script is run without any parameters, it just prints the results to the screen. (Partial output is shown above)

.EXAMPLE
    PS C:> GetProcess.ps1 -LogFile 'progress.log' -OutputPath c:\temp
    PS C:>
    
    This command produces no output on the screen. Instead it will log the progress in a file named 'progress.log' in the script directory, and export results to c:\temp\GetProcess.csv    

.NOTES
   Run with -verbose to see progress.
#>
[CMDLETBINDING()]
Param(  
        [Parameter(HelpMessage='Enter full path of the output directory')]
        # Output directory where the results will be written to   
        [ValidateScript({test-path $_ -PathType 'Container'})] 
        [string]$OutputPath,
        
        [Parameter(HelpMessage='Enter path to the log file')]
        # Log file where the script will log progress        
        [string]$LogFile
     )

$ScriptName = $MyInvocation.MyCommand.Name

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

try {
        if ($OutputFile) {
            &$log "Exporting running processes to $outputfile"
            Get-WmiObject -class win32_Process | Select ProcessName,ExecutablePath,ProcessId,ParentProcessId,CommandLine,Priority,@{Name="Date";Expression={$_.ConvertToDateTime($_.CreationDate)}}| Export-Csv -Path $outputFile  -NoTypeInformation -Force
        } else {
            Get-WmiObject -class win32_Process
        }
    }
catch {
        &$log $_
    }

