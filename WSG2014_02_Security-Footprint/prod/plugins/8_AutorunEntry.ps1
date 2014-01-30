$HTMLTitle = "List Autorun Entries"
$TblHeader =  "List Autorun Entries on $env:ComputerName "

#Get - METHOD1
$hive = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
Get-itemproperty $hive | Export-csv -notypeInformation $pwd\RegAutoRuns.csv 
Import-CSV $pwd\RegAutoRuns.csv 

#Get Remote Registry Value METHOD2
$computer = $env:ComputerName
$hivepath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
$objReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer) 
$objRegKey = $objReg.openSubKey($hivepath,$true) 

$output = "" | Select RegEntryNames,Value
foreach ($entry in $objRegKey.GetValueNames()) {
    $output.RegEntryNames =  $entry
    $output.Value =  $objRegKey.GetValue($entry)
    $output | Export-csv -notypeInformation $pwd\RegAutoRuns-Remote.csv -Append
    }

#WRITE
Import-Csv $pwd\RegAutoRuns-Remote.csv
