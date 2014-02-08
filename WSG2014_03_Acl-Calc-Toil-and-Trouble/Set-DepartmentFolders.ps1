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
    Setup permission on a new department structure
#>
[CMDLETBINDING()]
Param(
        [string]$department='Finance'
    )
    
    $DepartmentRoot = "$PSScriptRoot\$department"
    Write-Verbose "Department Root: $DepartmentRoot"

    ## Department Root Folder permissions
    Write-Verbose "Grant Read-Only to grp_${department} group for $DepartmentRoot"
    icacls.exe $DepartmentRoot /grant grp_${Department}:R /T /Q  #Grant department Read-Only for all files and sub-folders

    Write-Verbose "Grant Read-Only to grp_audit group for $DepartmentRoot"
    icacls.exe $DepartmentRoot /grant grp_audit:R /T /Q         #Grant Read-Only to audit group for all files and sub-folders

    Write-Verbose "Grant Read-Only to Authenticated Users (whole organization) for $DepartmentRoot"
    icacls.exe ${DepartmentRoot}\Open /grant --% "Authenticated Users":R  

    

    ## OPEN folder permissions
    Write-Verbose "Setting up Permissions on OPEN folder so that whole organization (authenticated users) can read it but department can also modify"
    icacls.exe ${DepartmentRoot}\Open /grant:r grp_${Department}:M /T /Q #Grant modify to grp_department for all files and sub-folders

    Write-Verbose "Grant whole organization (Authenticated users) permission to read OPEN folder"
    icacls.exe ${DepartmentRoot}\Open /grant:r --% "Authenticated User":R  

    $TeamFolder = Get-ChildItem $DepartmentRoot -Directory |where {$_.name -ne 'OPEN'} #Team Folders
    Foreach ($tf in $TeamFolder) {
    
        $tfFullPath=$tf.FullName  
        $teamName = "grp_$($tf.name)"
        
        #lead
        $teamLeadFullPath="${tfFullPath}\lead"                   # e.g. finance/audit/lead
        $teamLead="${teamname}_lead"                             # audit_lead
        Write-Verbose "Grant Full access to $teamLead for $teamLeadFullPath"
        icacls.exe $teamleadFullPath /grant ${teamLead}:F /T  /Q   
    
        #private
        $teamPrivateFullPath="${tfFullPath}\private"             # e.g. finance/audit/private        
        Write-Verbose "Grant Modify to team $teamname for $teamPrivateFullPath"
        icacls.exe $teamPrivateFullPath /grant ${teamname}:M /T /Q

        #shared        
        $teamSharedFullPath="${tfFullPath}\shared"                     # e.g. finance/audit/shared
        
        Write-Verbose "Grant modify to $teamName for $teamSharedFullPath"
        icacls.exe $teamSharedFullPath /grant ${teamName}:M /T /Q        
        
        Write-Verbose "Grant Read-only to whole grp_${department} department"
        icacls.exe $teamSharedFullPath /grant grp_${department}:R /T /Q ## Read by department

    }

<#
    Test: 
    1) remove inheritance: icacls.exe .\finance /inheritance:r /t
    2) Run script, remove my id 
    3) check results icacls.exe .\finance /t |? {$_ -notmatch 'hindia01'}
    $) fix: grp_Finance :Read access should not go all the way down!

    .\finance\ NYUMC\grp_audit:(R)
            NYUMC\grp_Finance:(R)

    .\finance\Accounting NYUMC\grp_audit:(R)
                            NYUMC\grp_Finance:(R)

    .\finance\Audit NYUMC\grp_audit:(R)
                    NYUMC\grp_Finance:(R)

    .\finance\OPEN NT AUTHORITY\Authenticated Users:(R)
                    NYUMC\grp_audit:(R)
                    NYUMC\grp_Finance:(M)

    .\finance\Payments NYUMC\grp_audit:(R)
                        NYUMC\grp_Finance:(R)

    .\finance\Receipts NYUMC\grp_audit:(R)
                        NYUMC\grp_Finance:(R)

    .\finance\Accounting\Lead NYUMC\grp_Accounting_lead:(F)
                                NYUMC\grp_audit:(R)
                                NYUMC\grp_Finance:(R)

    .\finance\Accounting\Private NYUMC\grp_Accounting:(M)
                                    NYUMC\grp_audit:(R)
                                    NYUMC\grp_Finance:(R)

    .\finance\Accounting\Shared NYUMC\grp_Accounting:(M)
                                NYUMC\grp_audit:(R)
                                NYUMC\grp_Finance:(R)

    .\finance\Audit\Lead NYUMC\grp_Audit_lead:(F)
                            NYUMC\grp_audit:(R)
                            NYUMC\grp_Finance:(R)

    .\finance\Audit\Private NYUMC\grp_audit:(M)
                            NYUMC\grp_Finance:(R)

    .\finance\Audit\Shared NYUMC\grp_audit:(M)
                            NYUMC\grp_Finance:(R)

    .\finance\Payments\Lead NYUMC\grp_Payments_lead:(F)
                            NYUMC\grp_audit:(R)
                            NYUMC\grp_Finance:(R)

    .\finance\Payments\Private NYUMC\grp_Payments:(M)
                                NYUMC\grp_audit:(R)
                                NYUMC\grp_Finance:(R)

    .\finance\Payments\Shared NYUMC\grp_Payments:(M)
                                NYUMC\grp_audit:(R)
                                NYUMC\grp_Finance:(R)

    .\finance\Receipts\Lead NYUMC\grp_Receipts_lead:(F)
                            NYUMC\grp_audit:(R)
                            NYUMC\grp_Finance:(R)

    .\finance\Receipts\Private NYUMC\grp_Receipts:(M)
                                NYUMC\grp_audit:(R)
                                NYUMC\grp_Finance:(R)

    .\finance\Receipts\Shared NYUMC\grp_Receipts:(M)
                                NYUMC\grp_audit:(R)
                                NYUMC\grp_Finance:(R)

#>
}

function Export-OriginalACL {
<#
    .SYNOPSIS
    Save original ACL on a department folder structure
#>
    [CMDLETBINDING()]
    param (
            [ValidateScript({Test-Path "$PsScriptRoot\$_"})]
            [string]$department='Finance'
           )
    
    $DepartmentFolders = Get-ChildItem "$PSScriptRoot\$department" -Recurse -Directory

    Foreach ($d in $DepartmentFolders) {
            
        $dirPath = $d.FullName
        $savePath = $dirpath -replace "(.*)($department.*)",'$2' -replace '\\','_'   ## replaces ...\xyz\finance\audit with finance_audit
                
        $savefile = "originalacl_${savepath}_$(get-date -Format "yyyyMMdd")"   ## e.g. finance/audit_20140206_114402

        Write-Verbose "Saving Original ACL file for $dirPath into $savefile"
        icacls.exe $dirPath /save $saveFile /Q ## need to include full path or some way of identifing which folder this 

    }

    if (!(test-path "$PSScriptRoot\originalACL")) {
            
        Write-Verbose "Creating ${PSSCriptRoot}\OriginalACL folder"
        $null = new-item -Path "$PSScriptRoot\originalACL" -ItemType directory -Force                    

    }

    Write-Verbose "Moving saved ACL file for each $department folder to ${PSSCriptRoot}\OriginalACL folder"
    Move-Item -path $PSScriptRoot\originalacl_* -destination "$PSScriptRoot\OriginalACL" -force
    


}

#endregion functions

#region Main_Script

New-DepartmentFolder
Set-TemplateGroups

New-DepartmentACL
Export-OriginalACL

#endregion Main_Script