$HTMLTitle = "List of Environment Variables"
$TblHeader =  "List of Environment Variables on $env:ComputerName "

#Get
gwmi -Class Win32_Environment| Select Caption,Name,VariableValue,SystemVariable,Username | Export-csv -notypeInformation $pwd\EnvVariables.csv -Append

#WRITE
Import-Csv $pwd\EnvVariables.csv 



