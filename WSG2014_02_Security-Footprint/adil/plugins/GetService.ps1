<#
.Synopsis
   Lists running computer services

.DESCRIPTION
   A plugin to print running processeson the computer, including the PATH, which can be helpful in incident investigation. It can be run stand-alone or as part of another script with options to log to main script log and output to defined location

.PARAMETER OutputPath
    The full path to the directory where the output should be written to

.PARAMETER LogFile
    The file where script events will be logged to. Main script log file name can be passed here, to collect progress information from this plugin

.EXAMPLE
   PS C:> GetService.ps1 |format-table -AutoSize

    DisplayName                                            PathName                                                                                                        State   StartMode DesktopInteract ServiceType   ProcessID
    -----------                                            --------                                                                                                        -----   --------- --------------- -----------   ---------
    Adobe Acrobat Update Service                           "C:\Program Files (x86)\Common Files\Adobe\ARM\1.0\armsvc.exe"                                                  Running Auto                False Own Process        1736
    Adobe Flash Player Update Service                      C:\Windows\SysWOW64\Macromed\Flash\FlashPlayerUpdateService.exe                                                 Stopped Manual              False Own Process           0
    AMD External Events Utility                            C:\WINDOWS\system32\atiesrxx.exe                                                                                Running Auto                False Own Process        1008
    Application Information                                C:\WINDOWS\system32\svchost.exe -k netsvcs                                                                      Running Manual              False Share Process       592
    Apple Mobile Device                                    "C:\Program Files (x86)\Common Files\Apple\Mobile Device Support\AppleMobileDeviceService.exe"                  Running Auto                False Own Process        6228   
   
   When script is run without any parameters, it just prints the results to the screen. (Partial output is shown above)

.EXAMPLE
    PS C:> GetService.ps1 -LogFile 'progress.log' -OutputPath c:\temp
    PS C:>
    
    This command produces no output on the screen. Instead it will log the progress in a file named 'progress.log' in the script directory, and export results to c:\temp\GetService.csv    

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
            &$log "Exporting running Services to $outputfile"
            Get-WmiObject -class win32_Service | Select DisplayName,PathName,State,StartMode,DesktopInteract,ServiceType,ProcessID | Export-Csv -Path $outputFile  -NoTypeInformation -Force
        } else {
            Get-WmiObject -class win32_Service | Select DisplayName,PathName,State,StartMode,DesktopInteract,ServiceType,ProcessID
        }
    }
catch {
        &$log $_
    }
