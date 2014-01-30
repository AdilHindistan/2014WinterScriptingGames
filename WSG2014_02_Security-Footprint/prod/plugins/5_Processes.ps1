$HTMLTitle = "List of Running Processes"
$TblHeader =  "List of Running Processes on $env:ComputerName "

# Get
# Using WMI instead of Get-Process, to get the following data for each service:
# Executable Path, CommandLine, Process Priority, and Parent Process ID

gwmi -class win32_Process | Select ProcessName,ExecutablePath,ProcessId,ParentProcessId,CommandLine,Priority,@{Name="Date";Expression={$_.ConvertToDateTime($_.CreationDate)}} | Export-csv -notypeInformation $pwd\Processes.csv -Append

#WRITE
Import-Csv $pwd\Processes.csv 

