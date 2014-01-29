$HTMLTitle = "List Autorun Entries"
$TblHeader =  "List Autorun Entries on $env:ComputerName "

#Get
$hive = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
Get-itemproperty $hive | Export-csv -notypeInformation $pwd\RegAutoRuns.csv 

#Get Remote Registry Value
$computer = ''
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
Import-Csv $pwd\EnvVariables.csv 
Import-Csv $pwd\RegAutoRuns-Remote.csv
