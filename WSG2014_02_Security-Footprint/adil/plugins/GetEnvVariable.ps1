<#
.Synopsis
   Lists environment variables for all users

.DESCRIPTION
   A plugin to print the environment variables for all users. It can be run stand-alone or as part of another script with options to log to main script log and output to defined location

.PARAMETER OutputPath
    The full path to the directory where the output should be written to

.PARAMETER LogFile
    The file where script events will be logged to. Main script log file name can be passed here, to collect progress information from this plugin

.EXAMPLE
   PS C:> .\GetEnvVariable.ps1 |format-table -AutoSize
    SYSTEM>\QTJAVA                 QTJAVA                 C:\Program Files (x86)\Java\jre7\lib\ext\QTJava.zip                                                                                                                                                                                                                                                
    NT AUTHORITY\SYSTEM\TMP         TMP                    %USERPROFILE%\AppData\Local\Temp                                                                                                                                                                                                                                                                   
    NT AUTHORITY\SYSTEM\TEMP        TEMP                   %USERPROFILE%\AppData\Local\Temp                                                                                                                                                                                                                                                                   
    AHSys\Adil\TMP                  TMP                    %USERPROFILE%\AppData\Local\Temp 
   
   When script is run without any parameters, it just prints the results to the screen. (Partial output is shown above)

.EXAMPLE
    PS C:> .\GetEnvVariable.ps1 -LogFile 'envprogress.log' -OutputPath c:\temp
    PS C:>
    
    This command produces no output on the screen. Instead it will log the progress in a file named 'envprogress.log' in the script directory, and export results to c:\temp\GetEnvVariable.csv    

.NOTES
   Be sure to run script in elevated shell. Run with -verbose to see progress.Plugins output to \output folder where script resides script      
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
            &$log "Exporting Environment variables for all users to $outputfile"
            Get-WmiObject -Class Win32_Environment| Select Caption,Name,VariableValue,SystemVariable,Username |Export-Csv -Path $outputFile  -NoTypeInformation -Force
        } else {
            Get-WmiObject -Class Win32_Environment| Select Caption,Name,VariableValue,SystemVariable,Username
        }
    }
catch {
        &$log $_
    }

