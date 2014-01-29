$HTMLTitle = "List of Shares"
$TblHeader =  "List of Shares on $env:ComputerName "

#Get
gwmi -class win32_Process | Select ProcessName,ExecutablePath,ProcessId,ParentProcessId,CommandLine,Priority,@{Name="Date";Expression={$_.ConvertToDateTime($_.CreationDate)}} | Export-csv -notypeInformation $pwd\Processes.csv -Append

#WRITE
Import-Csv $pwd\Processes.csv 

