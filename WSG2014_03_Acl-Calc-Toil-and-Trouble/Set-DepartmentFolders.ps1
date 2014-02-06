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

Function Set-TemplateGroups {
<#
    .SYNOPSIS
    Setup AD group for department
    .DESCRIPTION
    Sets up AD groups for department, teams, and team leads
    .EXAMPLE
        PS> Set-TemplateGroups -Verbose
        VERBOSE: Attempting to create department group grp_Finance
        VERBOSE: Attempting to create team group grp_Receipts
        VERBOSE: Adding grp_Receipts into grp_Finance as a member
        VERBOSE: Attempting to create team lead group grp_Receipts_Lead
        VERBOSE: Adding grp_Receipts_Lead into grp_Receipts
        VERBOSE: Attempting to create team group grp_Payments
        VERBOSE: Adding grp_Payments into grp_Finance as a member
        VERBOSE: Attempting to create team lead group grp_Payments_Lead
        VERBOSE: Adding grp_Payments_Lead into grp_Payments
        VERBOSE: Attempting to create team group grp_Audit
        VERBOSE: Adding grp_Audit into grp_Finance as a member
        VERBOSE: Attempting to create team lead group grp_Audit_Lead
        VERBOSE: Adding grp_Audit_Lead into grp_Audit
        VERBOSE: Attempting to create team group grp_Accounting
        VERBOSE: Adding grp_Accounting into grp_Finance as a member
        VERBOSE: Attempting to create team lead group grp_Accounting_Lead
        VERBOSE: Adding grp_Accounting_Lead into grp_Accounting
#>
    [CMDLETBINDING()]
    param (            
            [string]$department='Finance',
            [string[]]$team=@('Receipts','Payments','Audit','Accounting'),
            [string]$ADPath = "OU=groups,OU=EUDE,DC=nyumc,DC=org"    ## !!!REMOVE_THIS_BEFORE_SUBMISSION!!!
            )    
    Begin {
             try {
                Write-Verbose "Attempting to create department group grp_$department"            
                $departmentGroup = New-AdGroup -Name "grp_${department}" -GroupScope DomainLocal -GroupCategory Security -Path $ADPath -Server ADSWCDCPVM008 -PassThru 
                #$departmentGroup = Get-ADGroup -Identity "grp_${department}"
            }
            catch {
                Write-Verbose $_
            }       
    
    }
    Process {

        Foreach ($t in $team) {
            try {
                Write-Verbose "Attempting to create team group grp_${t}"            
                $TeamGroup = New-AdGroup -Name "grp_${t}" -GroupScope DomainLocal -GroupCategory Security -Path $ADPath -Server ADSWCDCPVM008 -PassThru 
                
                Write-Verbose "Adding grp_${t} into grp_$department as a member"
                Add-ADGroupMember -Identity $departmentGroup -Members $TeamGroup -Server ADSWCDCPVM008

                Write-Verbose "Attempting to create team lead group grp_${t}_Lead"
                $TeamLeadGroup = New-AdGroup -Name "grp_${t}_Lead" -GroupScope DomainLocal -GroupCategory Security -Path $ADPath -Server ADSWCDCPVM008 -PassThru 
                
                Write-Verbose "Adding grp_${t}_Lead into grp_${t}"
                Add-ADGroupMember -Identity $TeamGroup -Members $TeamLeadGroup -Server ADSWCDCPVM008

            }
            catch {
                Write-Verbose $_
            }
        }
    
    }        
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
Set-TemplateGroups

#endregion Main_Script