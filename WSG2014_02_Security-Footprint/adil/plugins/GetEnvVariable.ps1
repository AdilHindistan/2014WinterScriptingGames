$ScriptName = $MyInvocation.MyCommand.Name
$outputFile = Join-Path $PSScriptRoot ($ScriptName -replace '.ps1','_out.csv')

#(gci env:) | Export-Csv -Path $outputFile  -NoTypeInformation -Force
(Get-ItemProperty 'HKLM:\system\CurrentControlSet\control\Session Manager\Environment') |Export-Csv -Path $outputFile  -NoTypeInformation -Force
