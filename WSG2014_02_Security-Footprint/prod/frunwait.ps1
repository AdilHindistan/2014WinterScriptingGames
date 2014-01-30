Function fRunWait {
    param ([Parameter(Mandatory=$true)]$command,[Parameter(Mandatory=$false)]$arglist )

    $ps = new-object System.Diagnostics.Process
    $ps.StartInfo.Arguments = $arglist
    $ps.StartInfo.FileName = $command
    $ps.StartInfo.RedirectStandardOutput = $True
    $ps.StartInfo.UseShellExecute = $false
    $ps.start()
    $ps.WaitForExit()
    [string] $Out = $ps.StandardOutput.ReadToEnd()
    "$(get-date) INFO: $($Out)"|Out-File $log -Append
    "exit code: " + $ps.ExitCode
    return $ps.ExitCode
}
