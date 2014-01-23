[string[]]$output = @()
[string[]]$names = get-content C:\Github\PhillyPosh\WSG2014_01_Pairs\names2.txt
for ($i=0; $i -lt $names.length; $i+=2) {
       "$($names[$i]),$($names[$i+1])"
}
