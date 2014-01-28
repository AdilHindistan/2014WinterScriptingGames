$wc = new-object System.Net.WebClient
$uri = 'http://live.sysinternals.com/procexp.exe'
#$tmpProcExp = "$env:TEMP\procexp.exe"
$tmpAuto = "$env:TEMP\autorunsc.exe"
$wc.DownloadFile($uri,$tmpAuto)

