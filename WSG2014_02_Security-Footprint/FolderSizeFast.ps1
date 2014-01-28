$webroot = 'c:\windows\system32'
$fso = New-Object -ComObject Scripting.FileSystemObject
$fso.GetFolder($webRoot).Size

$fso.GetFolder($webRoot) | gm

$webroot = 'c:\'
($fso.GetFolder($webRoot).Files | Select Path).path | Get-Hash

 | Measure-Object Size -Sum | select Sum).sum /1gb

gci -Path $webroot -Recurse | Measure-Object 