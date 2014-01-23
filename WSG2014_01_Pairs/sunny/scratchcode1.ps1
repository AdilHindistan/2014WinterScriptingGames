$users = Get-Content .\names.txt
$ul = $users.Length
$primary = Get-Content .\primary.txt
$pl = $primary.Length

#test if each person in primary is already a member of user-list
#later.

#assuming they are, lets setup the perm. set

#ignore all possible combinations of primary
#aa,ab,ac 
[string[]]$ignorelist = @()

Function factorial ($n)  {
    $n..1 | foreach {$result = 1}{$result *= $_}{$result}
    }

$len = $primary.Length*$primary.Length
for ($i=0; $i -lt $lbound; $i++) {
    for ($j=0; $j -lt $lbound; $j++) {
        $array2[$i,$j] = $primary[$i] +","+ $script:myStack.pop()
        }
}

$array2


$ignorelist
$lbound = $ul/2

$array2 = New-Object 'object[,]' $lbound, $lbound



$script:myStack = new-object  System.Collections.Stack  
$users = Get-Content .\names.txt
foreach ($item in $users) {
$script:myStack.Push($item)
}
$script:myStack.pop()
 