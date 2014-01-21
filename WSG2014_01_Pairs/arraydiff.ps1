[string[]]$alpha = "a","b","c","d","e","f","g","h","i","j"
[string[]]$beta= "b","c","h"
[string[]]$diff = $alpha | where {$beta -notcontains $_}

