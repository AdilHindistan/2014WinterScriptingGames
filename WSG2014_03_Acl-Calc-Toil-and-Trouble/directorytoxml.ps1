function loopNodes { 
        param ( 
            $oElmntParent, 
            $strPath
        ) 
    #Write-Host $strPath
    $dirInfo = New-Object System.IO.DirectoryInfo $strPath
    $dirInfo.GetDirectories() | % {
        $OutNull = $oElmntChild = $xmlDoc.CreateElement("folder")
        $OutNull = $oElmntChild.SetAttribute("name", $_.Name)
        $OutNull = $oElmntParent.AppendChild($oElmntChild)
        loopNodes $oElmntChild ($strPath + "\" + $_.Name)
    }
    $dirInfo.GetFiles() | % {
        $OutNull = $oElmntChild = $xmlDoc.CreateElement("file")
        $OutNull = $oElmntChild.SetAttribute("name", $_.Name)
        $OutNull = $oElmntChild.SetAttribute("bytesSize", $_.Length)
        $OutNull = $oElmntParent.AppendChild($oElmntChild)
    }
}
function Directory2Xml {
    $FolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if($FolderBrowserDialog.ShowDialog() -eq 'OK'){
        $path = $FolderBrowserDialog.SelectedPath
        $xmlDoc = New-Object xml
        if($path -ne ''){
            $OutNull = $xmlDoc.AppendChild($xmlDoc.CreateProcessingInstruction("xml", "version='1.0'"))
            $OutNull = $oElmntRoot = $xmlDoc.CreateElement("baseDir")
            $OutNull = $oElmntRoot.SetAttribute("path", $path)
            $OutNull = $oElmntRoot.SetAttribute("description", "This is the root folder")
            $OutNull = $xmlDoc.AppendChild($oElmntRoot)
            loopNodes $oElmntRoot $path
        }
        $OutNull = $xmlDoc.Save("$path\Tree.xml")
        Write-Host "Archivo generado $path\Tree.xml"
    }
}
