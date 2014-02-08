<#
    .SYNOPSIS
    Set up and maintain new Department Folder Structure
    .DESCRIPTION
    Set up and maintain new Department Folder Structure.
    .NOTES
    Uses icacls to save/restore permissions. All reports, saved files are under ACL folder which resides under script folder

#>
[CMDLETBINDING()]
Param(
    [switch]$NewDepartmentSetup,
    [switch]$ReportACL

)

#region functions

Function New-TestFolders {
<#
    .SYNOPSIS
    Create a test folder structure 
    .DESCRIPTION 
    Creates a test folder structure under Department for testing script.
#>
    [CMDLETBINDING()]
    param (            
            [validatescript({Test-Path $_})]
            [string]$path
            )
    
    1..3 | ForEach-Object { 
        $TestFolder= "TestFolder$_"
        $SubTestFolder = "$path\$TestFolder\"
        1..5 | ForEach-Object {
                
                    $sub= "Sub" * $_
                    $SubTestFolder += "${Sub}${TestFolder}\"
                }
       Write-Verbose "Creating test folder structure $SubTestFolder"
       $null =New-Item -Path $SubTestFolder -ItemType Directory -Force
    }
}

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
                        
                        Write-Verbose "Following is not needed in production."
                        New-TestFolders -path $teamFolder                                                  
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
        VERBOSE: Attempting to create group AllUsers
        VERBOSE: Attempting to create department group grp_Finance
        VERBOSE: Adding grp_Finance into grp_AllUsers as a member
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
            [string]$ADPath = "OU=groups,OU=EUDE,DC=nyumc,DC=org"    ## !!!REMOVE_THIS_&_SERVER_BEFORE_SUBMISSION!!!
            )    
    Begin {
             try {
                
                Write-Verbose "Attempting to create group AllUsers."            
                $AllUsers = New-AdGroup -Name "grp_AllUsers" -GroupScope DomainLocal -GroupCategory Security -Path $ADPath -Server ADSWCDCPVM008 -PassThru 
                    
                Write-Verbose "Attempting to create department group grp_$department"            
                $departmentGroup = New-AdGroup -Name "grp_${department}" -GroupScope DomainLocal -GroupCategory Security -Path $ADPath -Server ADSWCDCPVM008 -PassThru 
                #$departmentGroup = Get-ADGroup -Identity "grp_${department}"

                Write-Verbose "Adding grp_${department} into grp_AllUsers as a member"
                Add-ADGroupMember -Identity $AllUsers -Members "$departmentGroup" -Server ADSWCDCPVM008
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

    #region Department Root Folder permissions    
    Write-Verbose "Grant Read-Only to grp_${department} group for $DepartmentRoot"
    icacls.exe $DepartmentRoot /grant grp_${Department}:`(NP`)R /Q  >$null

    Write-Verbose "Grant Read-Only to grp_audit group for $DepartmentRoot" 
    icacls.exe $DepartmentRoot /grant grp_audit:`(CI`)`(OI`)R /Q >$null          

    Write-Verbose "Grant Read-Only to All users (whole organization) for $DepartmentRoot only"
    icacls.exe ${DepartmentRoot} /grant grp_AllUsers:`(NP`)R >$null
    #endregion Department Root
    
    #region OPEN folder permissions
    Write-Verbose "Setting up Permissions on OPEN folder so that whole organization (authenticated users) can read it but department can also modify"
    icacls.exe ${DepartmentRoot}\Open /grant grp_${Department}:`(CI`)`(OI`)M /Q >$null

    Write-Verbose "Grant whole organization permission to read OPEN folder"
    icacls.exe ${DepartmentRoot}\Open /grant grp_AllUsers:`(CI`)`(OI`)R >$null
    #endregion Open folder permissions

    
    #region Team Folders
    $TeamFolder = Get-ChildItem $DepartmentRoot -Directory |where {$_.name -ne 'OPEN'} #Team Folders
    Foreach ($tf in $TeamFolder) {
    
        $tfFullPath=$tf.FullName  
        $teamName = "grp_$($tf.name)"

        ## Root of team folders
        Write-Verbose "Grant Readonly access to $teamName for $tfFullPath"
        icacls.exe $tfFullPath /grant ${teamName}:`(NP`)R /Q >$null
        
        #lead
        $teamLeadFullPath="${tfFullPath}\lead"                   # e.g. finance/audit/lead
        $teamLead="${teamname}_lead"                             # audit_lead
        Write-Verbose "Grant Full access to $teamLead for $teamLeadFullPath"
        icacls.exe $teamleadFullPath /grant ${teamLead}:`(CI`)`(OI`)F /Q >$null
    
        #private
        $teamPrivateFullPath="${tfFullPath}\private"             # e.g. finance/audit/private        
        Write-Verbose "Grant Modify to team $teamname for $teamPrivateFullPath"
        icacls.exe $teamPrivateFullPath /grant ${teamname}:`(CI`)`(OI`)M /Q >$null

        #shared        
        $teamSharedFullPath="${tfFullPath}\shared"                     # e.g. finance/audit/shared
        
        Write-Verbose "Grant modify to $teamName for $teamSharedFullPath"
        icacls.exe $teamSharedFullPath /grant ${teamName}:`(CI`)`(OI`)M /Q >$null
        
        Write-Verbose "Grant Read-only to whole grp_${department} department"
        icacls.exe $teamSharedFullPath /grant grp_${department}:`(CI`)`(OI`)R /Q >$null ## Read by department

    }
    #endregion team folders

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
    .DESCRIPTION
    Save original ACL on a department folder structure as csv to use when reporting and as icacls output for restoring
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
                
        $savefile = "OriginalACL.$(get-date -Format "yyyyMMdd.hhmm").${savepath}.txt"   ## e.g. OriginalACL.20140206.1144.finance_audit.txt
        $saveCSVfile = "OriginalACL.$(get-date -Format "yyyyMMdd.hhmm").${savepath}.csv"   ## e.g. OriginalACL.20140206.1144.finance_audit.csv

        Write-Verbose "Saving Original ACL file for $dirPath into $savefile for restore purposes"
        icacls.exe $dirPath /save $saveFile /Q # not using /T to include subfolders

        $dirACL = (Get-Acl $dirPath).Access | Where-Object {$_.IdentityReference -notmatch 'Builtin|Authority'} 
            
        Write-Verbose "Exporting Original ACL file to  $dirPath into $saveCSVfile for reporting purposes"
        $dirACL | Select-Object @{l='Path';e={$dirPath}},FileSystemRights, AccessControlType, IdentityReference, InheritanceFlags, IsInherited, PropagationFlags |Export-Csv $SaveCSVfile         
    }

    if (!(test-path "$PSScriptRoot\originalACL")) {
            
        Write-Verbose "Creating ${PSSCriptRoot}\ACL folder"
        $null = new-item -Path "$PSScriptRoot\ACL" -ItemType directory -Force                    

    }

    Write-Verbose "Moving saved ACL file for each $department folder to ${PSSCriptRoot}\ACL folder"
    Move-Item -path $PSScriptRoot\OriginalACL.* -destination "$PSScriptRoot\ACL" -force
    
}

Function Export-DepartmentFolderACLToHTML {
<#
    .SYNOPSIS
    Export ACL on a department folder structure
#>
    [CMDLETBINDING()]
    param (
            [ValidateScript({Test-Path "$PsScriptRoot\$_"})]
            [string]$department='Finance'
           )

    $DepartmentFolders = Get-ChildItem "$PSScriptRoot\$department" -Recurse -Directory

    $Fragments=''
    Foreach ($d in $DepartmentFolders) {
            
            $dirPath = $d.FullName 
            $dirSavePath = $dirpath -replace "(.*)($department.*)",'$2' -replace '\\','_'   ## replaces ...\xyz\finance\audit with finance_audit                
            $dirSavefile = "ACL.$(get-date -Format "yyyyMMdd.hhmm").${dirsavepath}.csv"     ## e.g. ACL.20140206.1144.finance_audit.csv                 
              
            $dirACL = (Get-Acl $dirPath).Access | Where-Object {$_.IdentityReference -notmatch 'Builtin|Authority'} 
            
            Write-Verbose "Exporting ACL for directory $dirPath"
            $dirACL | Select-Object @{l='Path';e={$dirPath}},FileSystemRights, AccessControlType, IdentityReference, InheritanceFlags, IsInherited, PropagationFlags |Export-Csv $dirSavefile         
    
        Write-Verbose "Creating html fragment for $dirPath"
        $fragments +=$dirACL |ConvertTo-Html -as List -Fragment -PreContent "<H2>ACL for $dirPath</H2>" |out-string
    }
    
$head=@'
    <style>
        body { background-color:#dddddd;
               font-family:Tahoma;
               font-size:12pt; }
        td, th { border:1px solid black; 
                 border-collapse:collapse; }
        th { color:white;
             background-color:black; }
        table, tr, td, th { padding: 2px; margin: 0px }
        table { margin-left:50px; }
        </style>
'@


    $saveHTMLfile = "ACL.$(get-date -Format "yyyyMMdd.hhmm").${department}.html"   ## e.g. ACL.20140206.1144.finance_audit.txt
    Write-Verbose "Saving ACL report for $department to $saveHTMLfile"
    ConvertTo-Html -Head $head -PostContent $Fragments -Title "$Department ACL Report" -Body "<H1>$Department ACL Report<h1>" |out-file $saveHTMLfile

    Write-Verbose "Moving saved ACL files for each $department folder to ${PSSCriptRoot}\ACL folder"
    Move-Item -path $PSScriptRoot\ACL.* -destination "$PSScriptRoot\ACL" -force
}


#endregion functions

#region Main_Script

If ($NewDepartmentSetup) {
    New-DepartmentFolder
    Set-TemplateGroups

    New-DepartmentACL
    Export-OriginalACL
}

if ($ReportACL) {
    Export-DepartmentFolderACLToHTML
}

#endregion Main_Script