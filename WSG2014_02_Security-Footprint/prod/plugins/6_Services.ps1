$HTMLTitle = "List of Services"
$TblHeader =  "List of Services on $env:ComputerName "

#Get
gwmi -class win32_Service | Select DisplayName,PathName,State,StartMode,DesktopInteract,ServiceType,ProcessID | Export-csv -notypeInformation $pwd\Services.csv -Append

#WRITE
Import-Csv $pwd\Services.csv

