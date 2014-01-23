[string[]]$names = get-content C:\Github\PhillyPosh\WSG2014_01_Pairs\sunny\names.txt
[string[]]$primary= get-content C:\Github\PhillyPosh\WSG2014_01_Pairs\sunny\primary.txt

#IgnoreList as CSV //Bad Idea
$ignoreListCSV = "ignorelist.csv"
$output = "" | Select First, Second
for ($i=0; $i -lt $names.length; $i++) {
       for ($j=0; $j -lt $names.length; $j++) {
        $output.First = $($names[$i])
        $output.Second = $($names[$j])
        $output | export-csv $ignoreListCSV -NoTypeInformation -Append
        }
}

#IgnoreList as MultiDimensional Array.
# How do you export and save it ? XML ?
$horiz= $primary.Count
$ignoreListArr = New-Object 'object[,]' $horiz,$horiz
for ($i=0; $i -lt $horiz; $i++) {
       for ($j=0; $j -lt $horiz; $j++) {
        $ignoreListArr[$i,$j] ="$($primary[$i]),$($primary[$j])"
        }
}
$datepart = $(get-date -f MMddyyyy)
$runTime 
$ignoreListArr | Export-Clixml "ignorelist_$datepart_$count.xml"
$count = 0
foreach ($itm in $ignoreListArr) {
Write-Output "$itm, Count: $count" 
$count++
}

$(Get-Date -Format MM/dd/yyyy-[HH:MM:ss])