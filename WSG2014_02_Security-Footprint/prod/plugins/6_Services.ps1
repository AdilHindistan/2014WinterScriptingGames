$HTMLTitle = "List of Services"
$TblHeader =  "List of Services on $env:ComputerName "

# Get
# Using WMI instead of Get-Service, to get the following data for each service:
# Startmode,DesktopInteract, EXE Path, and ProcessID and Parent Process ID
gwmi -class win32_Service | Select DisplayName,PathName,State,StartMode,DesktopInteract,ServiceType,ProcessID | Export-csv -notypeInformation $pwd\Services.csv -Append

#WRITE
Import-Csv $pwd\Services.csv

