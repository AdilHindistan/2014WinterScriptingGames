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

#ignore

#Main combinaiton Matrix of Pairs
$horiz= $names.Count
$outputArr = New-Object 'object[,]' $horiz,$horiz
for ($i=0; $i -lt $horiz; $i++) {
       for ($j=0; $j -lt $horiz; $j++) {
        $outputArr[$i,$j] ="$($names[$i]),$($names[$j])"
        }
}
$outputArr
#Delete main matrix with IgnoreList #Fitness Test

#How about dealing with a shorter List
$final = @()
foreach ($user in $names) {
    if($primary -notcontains $user) {
    $final +=$user
    }
}
$final.Count

[string[]]$names = get-content C:\Github\PhillyPosh\WSG2014_01_Pairs\sunny\names.txt
[string[]]$primary= get-content C:\Github\PhillyPosh\WSG2014_01_Pairs\sunny\primary.txt

$myStack = new-object  System.Collections.Stack  
foreach ($item in $final) {
$myStack.Push($item)
}

        
$ncount = $names.Count
$pcount = $primary.Count
$resultArr= New-Object 'object[,]' $ncount,$ncount  
for ($i=0; $i -lt $pcount; $i++) {
       for ($j=0; $j -lt $ncount; $j++) {
        $temp = $myStack.Peek()
        $resultArr[$i,$j] ="$($primary[$i]),$($names[$j])"
        }
}

$names = Get-Content .\names.txt
$myStack = new-object  System.Collections.Stack  
foreach ($item in $names) {
$myStack.Push($item)
}
#need to use Peek, to inspect the element being popped out is -Contains Primary
$myStack.Peek()