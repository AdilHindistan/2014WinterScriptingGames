Function Create-DRSMonitoringFile {

#Include TestPath and input validation
param($csvfile=".\servers.csv")

Begin {
    $csv = Import-Csv $csvfile
    $xmlpath = 'C:\github\PhillyPosh\WSG2014_04_Monitoring-Support\drsconfig.xml'
    $xmldata = New-Object XML
    $xmldata.Load($xmlpath)
    }
Process {
    foreach ($item in $csv){
        $xmldata.DRSmonitoring.Server.Name = $item.Server
        $xmldata.DRSmonitoring.Server.IPAddress = $item.IP
        $xmldata.DRSmonitoring.Monitoring.MonitorCPU =$item.CPU
        $xmldata.DRSmonitoring.Monitoring.MonitorRAM =$item.RAM
        $xmldata.DRSmonitoring.Monitoring.MonitorDisk=$item.Disk
        $xmldata.DRSmonitoring.Monitoring.MonitorNetwork=$item.Network
        $xmldata.save("$pwd\$($item.Server)-DRSMonitoring.xml")
        }
    }
}