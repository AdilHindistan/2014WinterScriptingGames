Function Create-Path {
param(
$computer,
$hive = 'SOFTWARE\DRSMonitoring',
$regvalue = 1
)

process {    
    $temppath = "\\$computer\c$\DRSMonitoring"
       
    #Check if TEMP Exists.
    if(!(Test-Path -Path $temppath)) {
   
        try {
            #Else Create Temp Folder
            $process = ([wmiclass]"\\$computer\root\cimv2:win32_Process")
            $command = 'cmd /c mkdir C:\DRSMonitoring'
            $process.create($command)
            }
    catch [Exception] {
        "DRS Monitoring FILE CREATION ERROR: $computer $_.Exception.Message"
        }
    } #end of IF
    } #end of Process Block
} #End of Function