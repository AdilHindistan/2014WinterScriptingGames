<#
    .SYNOPSIS
    Set up and maintain new Department Folder Structure

#>
[CMDLETBINDING()]
Param()

#region functions

Function New-DepartmentFolder {
<#
    .SYNOPSIS
    Create a new Department folder structure
#>
    [CMDLETBINDING()]
    param (            
            [string]$department='Finance',
            [string[]]$team=@('Receipts','Payments','Audit','Accounting')
            )
    
    
    $departmentRoot = "$PSScriptRoot\$department"
    
    ## Handle Department Open, which is open to all other departments
    $departmentOpen = "$departmentRoot\OPEN"
    if (test-path $departmentOpen) {

        Write-Verbose "$departmentOpen already exists"

    } else {                        

        Write-Verbose "Creating $departmentOpen"                        
        $null = New-Item -Path $departmentOpen -ItemType Directory -Force                                                    

    }

    #region team_folders
    $CommonFolders = 'Lead','Private','Shared'        
    Foreach ($t in $team) {        
        $teamRoot = "$departmentRoot\$t"                
        
        ## Create Common Folders for each team
        Foreach ($c in $CommonFolders) {

                    $teamFolder="$teamRoot\$c"

                    if (Test-Path $teamFolder) {
                        Write-Verbose "$teamFolder already exists"

                    } else {                        
                        Write-Verbose "$teamFolder needs to be created"                        
                        $null = New-Item -Path $teamFolder -ItemType Directory -Force                                                    
                    }
        }
    
    }
    #endregion team_folders
}

Function New-DepartmentACL {
<#
    .SYNOPSIS
    Create a new Department folder structure
#>
[CMDLETBINDING()]
Param(
        [string]$department='Finance'
    )


}

#endregion functions

#region Main_Script

New-DepartmentFolder

#endregion Main_Script