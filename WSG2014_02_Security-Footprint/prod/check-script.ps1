

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function check-script
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $Scriptfile
    )

    Begin
    {
    }
    Process
    {
    switch ($(Get-AuthenticodeSignature $Scriptfile|select -ExpandProperty status)) 
    {
    "notsigned"{Write-Warning "skipping not signed"
    return $false
    }
    "valid" {Write-Verbose "script validated"
    return $true}
    "notvalid" {Write-Warning "cannot validate certificate. Skipping execution"
    return $false
    default {Write-Warning "cannot validate certificate. Skipping execution"}
    }
    }
    }
    End
    {
    }
}