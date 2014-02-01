<#
.Synopsis
   Lists computer shares

.DESCRIPTION
   A plugin to print computer share information. It can be run stand-alone or as part of another script with options to log to main script log and output to defined location

.PARAMETER OutputPath
    The full path to the directory where the output should be written to

.PARAMETER LogFile
    The file where script events will be logged to. Main script log file name can be passed here, to collect progress information from this plugin

.EXAMPLE
   PS C:> GetShare.ps1 |format-table -AutoSize
            Name   Path                              Description    
            ----   ----                              -----------    
            IPC$                                     Remote IPC     
            print$ C:\WINDOWS\system32\spool\drivers Printer Drivers
            VM     C:\VM                             Virtual Machines 

   
   When script is run without any parameters, it just prints the results to the screen. (Partial output is shown above)

.EXAMPLE
    PS C:> GetShare.ps1 -LogFile 'progress.log' -OutputPath c:\temp
    PS C:>
    
    This command produces no output on the screen. Instead it will log the progress in a file named 'progress.log' in the script directory, and export results to c:\temp\GetShare.csv    

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

    IF ($LogFile) {        
        Add-Content -path $LogFile  -value "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
    }
    Write-Verbose "$(Get-Date -Format 'yyyyMMdd_HHmmss') ${ScriptName}: $msg"
}

try {
        if ($OutputFile) {
            &$log "Exporting File shares to $outputfile"
            Get-WmiObject -class Win32_Share| Export-Csv -Path $outputFile  -NoTypeInformation -Force
        } else {
            Get-WmiObject -class Win32_Share
        }
    }
catch {
        &$log $_
    }

