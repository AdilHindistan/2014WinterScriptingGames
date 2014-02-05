        [xml]$org = Get-Content .\org.xml
        $departments  = $org.org.Departments
        foreach ($department in $departments.department) {
        "department name: " + $department.name
            foreach ($folder in $department.Folders.Folder) {
            "folder name: " + $folder.name
            "folder path: " + $folder.path
            }

        }

