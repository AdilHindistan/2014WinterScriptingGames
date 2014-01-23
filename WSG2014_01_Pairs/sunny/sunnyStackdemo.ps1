$names = Get-Content .\names.txt
$myStack = new-object  System.Collections.Stack  
foreach ($item in $names) {
$myStack.Push($item)
}
$myStack.pop()
 