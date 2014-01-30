$HTMLTitle = "List of Shares"
$TblHeader =  "List of Shares on $env:ComputerName "

#GET
Get-WmiObject -class Win32_Share | Export-Csv -NoTypeInformation $pwd\FileShares.csv -Append

#WRITE
import-csv $pwd\FileShares.csv