#Get a better naming, so that Jaykul "Naming Convention Police" doesnt arrest you.
Function Export-LiveIP {
    param(
    #add validateset and param validation later.
    #Input is an array, output from Get-IPrange -ip 172.19.2.32 -cidr 24
    $ipaddress
    )

foreach ($ip in $ipaddress) {
    $obj = "" | Select IP, Live, Hostname
    if (Test-Connection $ip -Count 1) {
        $obj.ip = $ip
        $obj.Live = $true
        $obj.Hostname = [System.Net.Dns]::gethostentry($ip).HostName
        }
    else {
        $obj.ip = $ip
        $obj.Live = $false
        $obj.Hostname = ""
        }
Write-Output $obj
} #End of Foreach
}

#TEST
Export-LiveIP -ipaddress $ipaddress


