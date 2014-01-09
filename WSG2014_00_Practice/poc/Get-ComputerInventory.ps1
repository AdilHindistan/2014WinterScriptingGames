#Bartek. http://becomelotr.wordpress.com/2013/05/07/event-2-my-way/
#including manufacturer, model, CPU, RAM and disk sizes 
Function Get-ComputerInventory {

[OutputType('WMI.Inventory')]            
param (            
                
    # Name of computer to be invetoried.            
    [Parameter(            
        ValueFromPipeline = $true,            
        ValueFromPipelineByPropertyName = $true,            
        Mandatory = $true            
    )]            
    [Alias('CN','Name')]            
    [string]$ComputerName,            
            
    #Optional alternate credentials            
    [Management.Automation.PSCredential]            
    [Management.Automation.Credential()]            
    $Credential = [Management.Automation.PSCredential]::Empty            
)            
begin {
filter ConvertTo-WmiInventory {            
        if ($LogicalProcessors = $_.NumberOfLogicalProcessors) {            
            $Processors = $_.NumberOfProcessors            
        } else {            
            $Processors = 'N/A'            
            $LogicalProcessors = $_.NumberOfProcessors            
        }            
            
        $OS = $_.GetRelated('Win32_OperatingSystem').Version            
            
        $Out = New-Object PSObject -Property @{            
            Name = $_.Name            
            Manufacturer= $_.Manufacturer
            Model = $_.Model
            RAM = $_.TotalPhysicalMemory
            Processors = $Processors            
            LogicalProcessors = $LogicalProcessors            
            OSVersion = $OS            
            PhysicalMemory = $_.TotalPhysicalMemory  |            
                Add-Member -MemberType ScriptMethod -Value {            
                    "{0:N2} GB" -f ($this / 1gb)            
                } -PassThru -Name ToString -Force            
            
            }            
        $Out.PSTypeNames.Insert(0,'WMI.Inventory')            
        $Out                 
    }            

$WmiOptions = @{            
        Class = 'Win32_ComputerSystem'             
        ErrorAction = 'Stop'            
    }  
}
process {
try {            
        Get-WmiObject @PSBoundParameters @WmiOptions | ConvertTo-WmiInventory            
    } catch {            
        Write-Warning ("Issue with '{0}': '{1}'" -f             
        $ComputerName, $_.Exception.Message)            
    } 
}

} # End of Function

Update-TypeData -DefaultDisplayPropertySet @(            
    'Name'            
    'OSVersion'            
    'PhysicalMemory'            
    'LogicalProcessors'            
) -TypeName WMI.Inventory -Force   
